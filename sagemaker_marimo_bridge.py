"""WebSocket bridge that makes marimo work on Amazon SageMaker Studio.

SageMaker Studio's JupyterLab proxy (the ``/jupyterlab/default/proxy/PORT/``
mount) **strips the query string off WebSocket upgrade requests**. marimo puts
its ``session_id`` in the ``/ws`` query, so the backend receives ``/ws`` with no
``session_id`` and rejects the handshake with HTTP 403 — the notebook loads but
stays blank, stuck "connecting".

This bridge sits in front of marimo and works around that:

  browser ──/proxy/PORT/── SageMaker ──── this bridge (localhost) ──── marimo
                                              │
                                              └─ restores the stripped query,
                                                 then dials marimo over
                                                 localhost (origin intact).

How it works, end to end:

1. The bridge reverse-proxies all of marimo's HTTP (HTML, assets, API) and
   injects a tiny JS shim into the HTML.
2. The shim rewrites marimo's WebSocket URL so the query rides in the *path*
   (``/ws/__wss_q/<url-encoded-query>``) instead of ``?query`` — the path
   survives SageMaker's strip.
3. The bridge's WebSocket route decodes that path segment back into a real
   query and opens the WebSocket to marimo over localhost, where nothing is
   stripped and marimo's origin check is satisfied.

The shim tries a **native WebSocket first**. If SageMaker ever stops stripping
the query, marimo's own URL works unchanged and the bridge is a transparent
passthrough. An SSE + HTTP-POST fallback is included for environments that
block WebSockets outright (not needed on SageMaker, where WebSockets work).

Not marimo-specific in principle, but the query-strip workaround is what makes
it necessary on SageMaker; that is the only place it is needed.

Run it::

    python sagemaker_marimo_bridge.py --marimo-port 2718 --port 2719

Requires: starlette, uvicorn, httpx, websockets (all pulled in by marimo).
"""

from __future__ import annotations

import argparse
import asyncio
import base64
import html
import logging
import sys
from typing import Optional
from urllib.parse import unquote, urlencode

import httpx
import websockets.asyncio.client
import websockets.exceptions
from starlette.applications import Starlette
from starlette.requests import Request
from starlette.responses import Response, StreamingResponse
from starlette.routing import Route, WebSocketRoute
from starlette.websockets import WebSocket, WebSocketDisconnect

logger = logging.getLogger("marimo_bridge")

# --- The JS shim injected into marimo's HTML -------------------------------
#
# It replaces window.WebSocket so marimo's WebSocket URL is rewritten to carry
# its query in the path (surviving SageMaker's query strip). Native WebSocket
# is tried first; an SSE fallback covers environments that block WebSockets.

SHIM_SCRIPT = r"""
<script>
(function() {
  const OriginalWebSocket = window.WebSocket;

  class ShimmedWebSocket extends EventTarget {
    constructor(url, protocols) {
      super();
      this.url = url;
      this.readyState = ShimmedWebSocket.CONNECTING;
      this.bufferedAmount = 0;
      this.extensions = '';
      this.protocol = '';
      this.binaryType = 'blob';

      const wsUrl = new URL(url, window.location.origin);
      this._queryString = wsUrl.search;

      // The mount prefix is the page's own directory (everything up to the
      // last '/'), NOT anything from the app's WS URL — some apps build that
      // from an empty base and emit a root URL that ignores the sub-path mount.
      //   page /jupyterlab/default/proxy/2719/  ->  /jupyterlab/default/proxy/2719
      const pagePath = window.location.pathname;
      this._basePath = pagePath.replace(/\/[^/]*$/, '');

      let appWsPath = wsUrl.pathname;
      if (this._basePath && appWsPath.startsWith(this._basePath)) {
        appWsPath = appWsPath.slice(this._basePath.length);
      }
      this._targetWsPath = appWsPath || '/';

      // Smuggle the query as a path segment because SageMaker strips the query
      // on WebSocket upgrades: <ws-path>/__wss_q/<url-encoded-query>.
      const wsScheme = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
      let nativePath = `${this._basePath}${this._targetWsPath}`;
      if (this._queryString) {
        const q = this._queryString.replace(/^\?/, '');
        nativePath = nativePath.replace(/\/$/, '') +
          '/__wss_q/' + encodeURIComponent(q);
      }
      this._nativeWsUrl = `${wsScheme}//${window.location.host}${nativePath}`;

      this._shimId = crypto.randomUUID();

      // Native WebSocket first; SSE fallback only if it fails.
      this._tryRealWebSocket(this._nativeWsUrl, protocols);
    }

    _tryRealWebSocket(url, protocols) {
      try {
        this._realWs = new OriginalWebSocket(url, protocols);
        this._realWs.binaryType = this.binaryType;

        const failTimeout = setTimeout(() => {
          if (this._realWs.readyState === OriginalWebSocket.CONNECTING) {
            console.log('[marimo-bridge] WebSocket stalled, falling back to SSE');
            this._realWs.close();
            this._startSSE();
          }
        }, 3000);

        this._realWs.onopen = (e) => {
          clearTimeout(failTimeout);
          this.readyState = ShimmedWebSocket.OPEN;
          this.dispatchEvent(new Event('open'));
          if (this.onopen) this.onopen(e);
        };

        this._realWs.onclose = (e) => {
          clearTimeout(failTimeout);
          if (e.code === 1006 && !this._sseActive) {
            console.log('[marimo-bridge] WebSocket closed 1006, falling back to SSE');
            this._startSSE();
            return;
          }
          if (!this._sseActive) {
            this.readyState = ShimmedWebSocket.CLOSED;
            const closeEvent = new CloseEvent('close', {
              code: e.code, reason: e.reason, wasClean: e.wasClean
            });
            this.dispatchEvent(closeEvent);
            if (this.onclose) this.onclose(closeEvent);
          }
        };

        this._realWs.onerror = (e) => {
          clearTimeout(failTimeout);
          if (!this._sseActive) {
            if (this._realWs.readyState !== OriginalWebSocket.OPEN) {
              return;  // will fall back on close
            }
            this.dispatchEvent(new Event('error'));
            if (this.onerror) this.onerror(e);
          }
        };

        this._realWs.onmessage = (e) => {
          this.dispatchEvent(new MessageEvent('message', { data: e.data }));
          if (this.onmessage) this.onmessage(e);
        };
      } catch (err) {
        this._startSSE();
      }
    }

    _startSSE() {
      this._sseActive = true;
      this.readyState = ShimmedWebSocket.CONNECTING;

      const sep = this._queryString ? '&' : '?';
      const sseUrl = `${this._basePath}/__wss/events${this._queryString}${sep}__wss_id=${this._shimId}&__wss_path=${encodeURIComponent(this._targetWsPath)}`;

      // Close the upstream session when the page unloads (reload/navigation) so
      // a reload resumes as the editor rather than a read-only "kiosk" view.
      // sendBeacon survives unload where a normal fetch would be cancelled.
      if (!this._unloadHandler && typeof window.addEventListener === 'function') {
        this._unloadHandler = () => {
          if (this._sseActive && this._shimId &&
              typeof navigator !== 'undefined' && navigator.sendBeacon) {
            navigator.sendBeacon(`${this._basePath}/__wss/close?__wss_id=${this._shimId}`);
          }
        };
        window.addEventListener('pagehide', this._unloadHandler);
      }

      this._eventSource = new EventSource(sseUrl);

      this._eventSource.onopen = () => {
        this.readyState = ShimmedWebSocket.OPEN;
        this.dispatchEvent(new Event('open'));
        if (this.onopen) this.onopen(new Event('open'));
      };

      this._eventSource.onmessage = (e) => {
        const msgEvent = new MessageEvent('message', { data: e.data });
        this.dispatchEvent(msgEvent);
        if (this.onmessage) this.onmessage(msgEvent);
      };

      this._eventSource.addEventListener('binary', (e) => {
        const binary = atob(e.data);
        const bytes = new Uint8Array(binary.length);
        for (let i = 0; i < binary.length; i++) bytes[i] = binary.charCodeAt(i);
        const data = this.binaryType === 'arraybuffer' ? bytes.buffer : new Blob([bytes]);
        const msgEvent = new MessageEvent('message', { data });
        this.dispatchEvent(msgEvent);
        if (this.onmessage) this.onmessage(msgEvent);
      });

      this._eventSource.onerror = () => {
        if (this._eventSource.readyState === EventSource.CLOSED) {
          this.readyState = ShimmedWebSocket.CLOSED;
          const closeEvent = new CloseEvent('close', {
            code: 1006, reason: 'SSE connection closed', wasClean: false
          });
          this.dispatchEvent(closeEvent);
          if (this.onclose) this.onclose(closeEvent);
        }
      };
    }

    send(data) {
      if (this._sseActive) {
        const sendUrl = `${this._basePath}/__wss/send?__wss_id=${this._shimId}`;
        const isBinary = data instanceof ArrayBuffer || data instanceof Blob;
        fetch(sendUrl, {
          method: 'POST',
          headers: { 'Content-Type': isBinary ? 'application/octet-stream' : 'text/plain; charset=utf-8' },
          body: data,
        }).catch(err => console.error('[marimo-bridge] send failed:', err));
      } else if (this._realWs) {
        this._realWs.send(data);
      }
    }

    close(code, reason) {
      if (this._unloadHandler) {
        window.removeEventListener('pagehide', this._unloadHandler);
        this._unloadHandler = null;
      }
      if (this._eventSource) this._eventSource.close();
      if (this._realWs) { try { this._realWs.close(code, reason); } catch (e) {} }
      this.readyState = ShimmedWebSocket.CLOSED;
      if (this._sseActive) {
        fetch(`${this._basePath}/__wss/close?__wss_id=${this._shimId}`, { method: 'POST' }).catch(() => {});
      }
      const closeEvent = new CloseEvent('close', { code: code || 1000, reason: reason || '', wasClean: true });
      this.dispatchEvent(closeEvent);
      if (this.onclose) this.onclose(closeEvent);
    }
  }

  ShimmedWebSocket.CONNECTING = 0;
  ShimmedWebSocket.OPEN = 1;
  ShimmedWebSocket.CLOSING = 2;
  ShimmedWebSocket.CLOSED = 3;
  ShimmedWebSocket.prototype.onopen = null;
  ShimmedWebSocket.prototype.onclose = null;
  ShimmedWebSocket.prototype.onerror = null;
  ShimmedWebSocket.prototype.onmessage = null;

  window.WebSocket = ShimmedWebSocket;
  console.log('[marimo-bridge] WebSocket shim installed');
})();
</script>
"""

# On each idle wakeup we poll for client disconnect and emit an SSE keepalive.
DISCONNECT_POLL_SECONDS = 1.0
# Large comment preamble + periodic keepalive to nudge buffering proxies to
# flush the SSE stream (fallback path only).
SSE_PREAMBLE = ":" + (" " * 2048) + "\n\n"
SSE_KEEPALIVE = ": keepalive\n\n"


class _ConnectionPool:
    """Tracks active SSE-fallback WebSocket connections keyed by shim id."""

    def __init__(self) -> None:
        self._connections: dict[str, websockets.asyncio.client.ClientConnection] = {}

    async def open(self, shim_id: str, ws_url: str):
        # Close any prior connection for this id first, so a reconnect can't
        # orphan an upstream socket (which would leave marimo's session OPEN and
        # demote the reconnecting client to a read-only kiosk view).
        await self.close(shim_id)
        ws = await websockets.asyncio.client.connect(
            ws_url, additional_headers={"Origin": "http://localhost"}, max_size=None
        )
        self._connections[shim_id] = ws
        return ws

    def get(self, shim_id: str):
        return self._connections.get(shim_id)

    async def close(self, shim_id: str) -> None:
        ws = self._connections.pop(shim_id, None)
        if ws:
            try:
                await ws.close()
            except Exception:  # noqa: BLE001
                pass


def create_bridge(marimo_port: int, marimo_host: str = "localhost") -> Starlette:
    """Build the ASGI bridge app that fronts marimo."""
    target_http = f"http://{marimo_host}:{marimo_port}"
    target_ws = f"ws://{marimo_host}:{marimo_port}"
    pool = _ConnectionPool()
    http_client = httpx.AsyncClient(trust_env=False, timeout=30.0)

    # --- Preferred path: bridge the browser WebSocket to marimo -------------

    async def websocket_bridge(client_ws: WebSocket) -> None:
        ws_path = client_ws.url.path
        query = client_ws.url.query

        # The shim smuggles the query as a trailing path segment because
        # SageMaker strips the real query on WS upgrades. Decode it back.
        marker = "/__wss_q/"
        idx = ws_path.find(marker)
        if idx != -1:
            encoded = ws_path[idx + len(marker):]
            ws_path = ws_path[:idx] or "/"
            if not query:
                query = unquote(encoded)

        # A query must never contain HTML entities; SageMaker can deliver '&'
        # as '&amp;', which would turn "session_id" into "amp;session_id" and
        # make marimo 403. Unescape so marimo sees real '&' separators.
        if query and "&amp;" in query:
            query = html.unescape(query)

        target_url = f"{target_ws}{ws_path}"
        if query:
            target_url += f"?{query}"

        await client_ws.accept()

        try:
            upstream = await websockets.asyncio.client.connect(
                target_url,
                additional_headers={"Origin": "http://localhost"},
                max_size=None,
            )
        except Exception as e:  # noqa: BLE001
            logger.error("WS bridge: upstream connect failed for %s: %s", target_url, e)
            await client_ws.close(code=1011)
            return

        logger.info("WS bridge: %s", target_url)

        async def browser_to_marimo() -> None:
            try:
                while True:
                    msg = await client_ws.receive()
                    if msg["type"] == "websocket.disconnect":
                        break
                    if msg.get("text") is not None:
                        await upstream.send(msg["text"])
                    elif msg.get("bytes") is not None:
                        await upstream.send(msg["bytes"])
            except (WebSocketDisconnect, RuntimeError):
                pass
            finally:
                await upstream.close()

        async def marimo_to_browser() -> None:
            try:
                async for message in upstream:
                    if isinstance(message, bytes):
                        await client_ws.send_bytes(message)
                    else:
                        await client_ws.send_text(message)
            except websockets.exceptions.ConnectionClosed:
                pass
            finally:
                try:
                    await client_ws.close()
                except RuntimeError:
                    pass

        t1 = asyncio.ensure_future(browser_to_marimo())
        t2 = asyncio.ensure_future(marimo_to_browser())
        try:
            await asyncio.wait({t1, t2}, return_when=asyncio.FIRST_COMPLETED)
        finally:
            for t in (t1, t2):
                t.cancel()
            await upstream.close()

    # --- Fallback path: SSE + HTTP POST (for hosts that block WebSockets) ---

    async def sse_endpoint(request: Request) -> Response:
        shim_id = request.query_params.get("__wss_id")
        if not shim_id:
            return Response("Missing __wss_id", status_code=400)
        ws_path = request.query_params.get("__wss_path", "/ws")
        params = [
            (k, v)
            for k, v in request.query_params.multi_items()
            if not k.startswith("__wss_")
        ]
        qs = urlencode(params)
        ws_url = f"{target_ws}{ws_path}" + (f"?{qs}" if qs else "")
        try:
            ws = await pool.open(shim_id, ws_url)
        except Exception as e:  # noqa: BLE001
            return Response(f"WebSocket connection failed: {e}", status_code=502)

        async def event_generator():
            yield SSE_PREAMBLE
            recv_task = asyncio.ensure_future(ws.recv())
            try:
                while True:
                    done, _ = await asyncio.wait({recv_task}, timeout=DISCONNECT_POLL_SECONDS)
                    if recv_task not in done:
                        if await request.is_disconnected():
                            break
                        yield SSE_KEEPALIVE
                        continue
                    message = recv_task.result()
                    recv_task = asyncio.ensure_future(ws.recv())
                    if isinstance(message, bytes):
                        yield f"event: binary\ndata: {base64.b64encode(message).decode('ascii')}\n\n"
                    else:
                        yield "data: " + "\ndata: ".join(message.split("\n")) + "\n\n"
            except websockets.exceptions.ConnectionClosed:
                yield "event: close\ndata: connection closed\n\n"
            except Exception as e:  # noqa: BLE001
                yield f"event: error\ndata: {e}\n\n"
            finally:
                recv_task.cancel()
                await pool.close(shim_id)

        return StreamingResponse(
            event_generator(),
            media_type="text/event-stream",
            headers={"Cache-Control": "no-cache", "Connection": "keep-alive", "X-Accel-Buffering": "no"},
        )

    async def send_endpoint(request: Request) -> Response:
        shim_id = request.query_params.get("__wss_id")
        if not shim_id:
            return Response("Missing __wss_id", status_code=400)
        ws = pool.get(shim_id)
        if not ws:
            return Response("No active connection", status_code=404)
        body = await request.body()
        try:
            if "octet-stream" in request.headers.get("content-type", ""):
                await ws.send(body)
            else:
                try:
                    await ws.send(body.decode("utf-8"))
                except UnicodeDecodeError:
                    await ws.send(body)
            return Response("OK", status_code=200)
        except Exception as e:  # noqa: BLE001
            return Response(f"Send failed: {e}", status_code=502)

    async def close_endpoint(request: Request) -> Response:
        shim_id = request.query_params.get("__wss_id")
        if shim_id:
            await pool.close(shim_id)
        return Response("OK", status_code=200)

    # --- Everything else: reverse-proxy HTTP + inject the shim into HTML ----

    async def http_proxy(request: Request) -> Response:
        path = request.url.path
        query = str(request.url.query)
        target_url = f"{target_http}{path}" + (f"?{query}" if query else "")
        try:
            resp = await http_client.request(
                method=request.method,
                url=target_url,
                headers={
                    k: v
                    for k, v in request.headers.items()
                    if k.lower() not in ("host", "connection", "transfer-encoding")
                },
                content=(await request.body() if request.method in ("POST", "PUT", "PATCH") else None),
                follow_redirects=False,
            )
        except httpx.ConnectError:
            return Response("marimo not reachable", status_code=502)

        body = resp.content
        if "text/html" in resp.headers.get("content-type", ""):
            page = body.decode("utf-8", errors="replace")
            at = page.find("<script")
            if at == -1:
                at = page.find("</head>")
            page = (page[:at] + SHIM_SCRIPT + page[at:]) if at != -1 else (SHIM_SCRIPT + page)
            body = page.encode("utf-8")

        excluded = {"transfer-encoding", "connection", "content-encoding", "content-length"}
        headers = {k: v for k, v in resp.headers.items() if k.lower() not in excluded}
        return Response(content=body, status_code=resp.status_code, headers=headers)

    routes = [
        Route("/__wss/events", sse_endpoint),
        Route("/__wss/send", send_endpoint, methods=["POST"]),
        Route("/__wss/close", close_endpoint, methods=["POST"]),
        # Preferred path: bridge any WebSocket upgrade to marimo over localhost.
        WebSocketRoute("/{path:path}", websocket_bridge),
        Route("/{path:path}", http_proxy, methods=["GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS"]),
        Route("/", http_proxy),
    ]
    return Starlette(routes=routes)


def main() -> None:
    parser = argparse.ArgumentParser(
        description="WebSocket bridge that makes marimo work on SageMaker Studio."
    )
    parser.add_argument("--marimo-port", type=int, default=2718,
                        help="Port marimo is listening on (default: 2718)")
    parser.add_argument("--marimo-host", default="localhost",
                        help="Host marimo is listening on (default: localhost)")
    parser.add_argument("--port", type=int, default=2719,
                        help="Port for the bridge to listen on (default: 2719)")
    parser.add_argument("--host", default="0.0.0.0",
                        help="Host to bind the bridge to (default: 0.0.0.0)")
    parser.add_argument("--log-level", default="INFO", type=str.upper,
                        choices=["DEBUG", "INFO", "WARNING", "ERROR"])
    args = parser.parse_args()

    logging.basicConfig(
        level=getattr(logging, args.log_level),
        format="%(asctime)s [%(name)s] %(levelname)s: %(message)s",
    )

    try:
        import uvicorn
    except ImportError:
        print("uvicorn is required: pip install uvicorn", file=sys.stderr)
        sys.exit(1)

    app = create_bridge(marimo_port=args.marimo_port, marimo_host=args.marimo_host)
    uvicorn.run(app, host=args.host, port=args.port, log_level=args.log_level.lower())


if __name__ == "__main__":
    main()
