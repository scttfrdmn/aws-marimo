# WebSocket Proxy Status on SageMaker Studio Lab

## Summary

marimo requires WebSocket connections for interactive notebook editing (cell execution, reactive updates, UI widgets). On SageMaker Studio Lab, WebSocket connections through the jupyter-server-proxy `/proxy/PORT/` path are dropped by the SageMaker gateway/ALB infrastructure.

**HTTP proxying works. WebSocket proxying does not.**

## What Works

- marimo home page / file browser loads at `/proxy/2718/`
- HTTP API requests are proxied correctly
- jupyter-server-proxy extension loads and serves HTTP traffic
- Internal WebSocket (localhost:8888 → localhost:2718) works fine
- Jupyter's own WebSocket paths (terminals, kernels) work through the gateway

## What Doesn't Work

- WebSocket connections from browser → SageMaker gateway → jupyter-server-proxy → marimo
- The WebSocket upgrade succeeds (OPEN state) but immediately closes with code 1006 (abnormal closure)
- This prevents cell execution, reactive updates, and all interactive features

## Root Cause

The SageMaker Studio Lab gateway (AWS ALB) sits between the browser and the Jupyter server. While ALB nominally supports WebSocket, there's a known behavior where it can replace `Connection: Upgrade` headers with `Connection: Keep-Alive` on certain proxy paths. The SageMaker gateway adds additional routing that compounds this issue.

Jupyter's own WebSocket paths (`/api/kernels/*/channels`, `/terminals/websocket/*`) work because they're handled directly by the Jupyter server before reaching the proxy extension layer. The proxy extension's WebSocket forwarding to backend services doesn't survive the gateway.

## What We've Ruled Out

| Approach | Result |
|----------|--------|
| jupyter-server-proxy 3.2.4 (downgrade) | Same WebSocket failure |
| jupyter-server-proxy 4.4.0 (current) | HTTP works, WebSocket fails |
| marimo `--allow-origins '*'` | No effect on WebSocket |
| marimo `--base-url` with proxy path | Creates double-prefix routing problem |
| marimo `--proxy` flag | Doesn't help with gateway-level issue |

## Workaround: ws-sse-proxy

This repo uses [ws-sse-proxy](https://github.com/scttfrdmn/ws-sse-proxy), a generic WebSocket-to-SSE translation proxy. It's not marimo-specific — it works with any WebSocket-dependent web application behind a broken proxy.

### How it works

```
Browser → SageMaker Gateway → jupyter-server-proxy → ws-sse-proxy (port 2719) → WebSocket → marimo (port 2718)
              (HTTP + SSE only)                                                   (localhost, works)
```

1. The proxy passes all HTTP requests through to marimo unchanged
2. It injects a small JavaScript shim that monkey-patches `window.WebSocket`
3. The patched WebSocket tries real WebSocket first — if it works (non-SageMaker), zero overhead
4. On SageMaker, when WebSocket fails with code 1006, it falls back to SSE + HTTP POST
5. The `/__wss/events` SSE endpoint opens a real WebSocket to marimo on localhost and streams messages back
6. The `/__wss/send` POST endpoint forwards user actions to marimo via the local WebSocket

### Usage

```bash
pip install ws-sse-proxy
bash start-marimo-shim.sh
```

Then access marimo at `/proxy/2719/` (the proxy port, not marimo's port).

## Potential Solutions (Upstream)

### 1. marimo HTTP fallback transport (Best long-term fix)
Add SSE or HTTP long-polling as a fallback when WebSocket is unavailable. marimo's server architecture already separates the `SessionConsumer` interface from the WebSocket transport (`ws_endpoint.py`), making this feasible. The shim in this repo demonstrates the approach.

**Target:** [marimo-team/marimo](https://github.com/marimo-team/marimo)

### 2. marimo-jupyter-extension SageMaker support
The marimo team has an open issue for SageMaker support. Note: the extension currently uses jupyter-server-proxy under the hood (iframe to proxied URL), so it has the same WebSocket problem. A fix could incorporate the SSE shim approach.

**Target:** [marimo-jupyter-extension #8](https://github.com/marimo-team/marimo-jupyter-extension/issues/8)

### 3. marimo WASM mode
marimo can run entirely in the browser via WebAssembly/Pyodide, eliminating the need for WebSocket. However, this can't access SageMaker-specific resources (boto3, local files, GPUs).

**Status:** Available now via `marimo export html-wasm`

## Related Issues

- [marimo #8060](https://github.com/marimo-team/marimo/issues/8060) - WebSocket issue on AWS SageMaker
- [marimo-jupyter-extension #8](https://github.com/marimo-team/marimo-jupyter-extension/issues/8) - feat: support sagemaker
- [jupyter-server-proxy #404](https://github.com/jupyterhub/jupyter-server-proxy/issues/404) - Version 4.0.0 breaks SageMaker Studio environment (different product, but related context)
- [dask/dask #5432](https://github.com/dask/dask/issues/5432) - Proxying Dask/Bokeh Web Interface on AWS SageMaker (same root cause)

## Previous Incorrect Advice

Earlier versions of this repo recommended downgrading jupyter-server-proxy from 4.x to 3.2.4. **This is not necessary.** The downgrade:
- Does not fix the WebSocket issue (it's in the gateway, not the proxy)
- Can break the conda-managed extension registration (pip install overwrites conda metadata)
- References issue #404, which was about SageMaker Studio (a different product), not Studio Lab

Use the conda-provided version of jupyter-server-proxy (currently 4.4.0) with no modification.
