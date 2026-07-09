# WebSocket Status: marimo on Amazon SageMaker Studio

## Summary

marimo requires a WebSocket connection for interactive notebook editing (cell
execution, reactive updates, UI widgets). On Amazon SageMaker Studio, the
marimo home page and file browser load through the JupyterLab proxy, but the
WebSocket connection is **rejected with HTTP 403** and notebooks stay stuck in
a "connecting" loop with blank cells.

**HTTP proxying works. The marimo WebSocket handshake does not — and it fails
at the handshake, not after connecting.** This repo ships a workaround
([ws-sse-proxy](https://github.com/scttfrdmn/ws-sse-proxy)); see below.

> Applies to full **SageMaker Studio** (the JupyterLab application / Spaces) and
> **SageMaker Unified Studio**. It is *not* specific to the now-EOL Studio Lab.

## What works

- marimo home page / file browser through the JupyterLab proxy
- HTTP API requests (`/health`, `/api/*`) through the proxy
- jupyter-server-proxy serving HTTP traffic
- marimo running fine when reached directly on localhost inside the space

## What doesn't work (without the shim)

- The browser → SageMaker proxy → marimo WebSocket (`/ws`) handshake
- Interactive notebook editing, cell execution, reactive updates, UI widgets

## Root cause

**The SageMaker JupyterLab proxy does not forward marimo's session cookie, so
marimo rejects the WebSocket handshake with HTTP 403.**

marimo sets a session cookie on the initial HTTP request and requires that
cookie to be present on the subsequent WebSocket upgrade to `/ws`. SageMaker's
proxy strips it, so marimo returns **403 Forbidden** and refuses the upgrade.
In the marimo server log this appears as:

```
INFO:     ("WebSocket /ws" 403)
INFO:     connection rejected (403 Forbidden)
INFO:     connection closed
```

In the browser console it surfaces as a WebSocket that closes with code
**1006** — but the underlying cause is the 403 handshake rejection, not an
abnormal close of an established connection.

> **Correction:** earlier versions of this document attributed the failure to
> an AWS ALB rewriting `Connection: Upgrade` to `Connection: Keep-Alive`. That
> was wrong. The failure is a **session-cookie / 403 handshake rejection at the
> proxy layer**, confirmed by multiple independent reports on real SageMaker
> Studio (see Upstream status).

## What we've ruled out

| Approach | Result |
|----------|--------|
| Downgrading jupyter-server-proxy (3.x) | No effect — the problem isn't in the proxy version |
| marimo `--allow-origins '*'` | No effect on the 403 |
| marimo `--no-token` / `--trusted` | No effect on the 403 (cookie still stripped) |
| marimo `--base-url /jupyterlab/default/proxy/PORT` | Produces double-prefixed, mangled URLs; does not fix the handshake |

## Workaround: ws-sse-proxy

[ws-sse-proxy](https://github.com/scttfrdmn/ws-sse-proxy) is a generic
WebSocket-to-SSE translation proxy (on PyPI). It is not marimo-specific.

### Why it works

```
Browser → SageMaker proxy → ws-sse-proxy (:2719) → WebSocket → marimo (:2718)
             (HTTP + SSE only)                      (localhost — cookie intact)
```

The key insight: ws-sse-proxy opens the real WebSocket to marimo **over
localhost**, inside the space, where the session cookie and origin are intact —
so marimo accepts the handshake. Only plain HTTP and Server-Sent Events cross
the SageMaker proxy, and those are not blocked.

1. All HTTP passes through to marimo unchanged.
2. A small JavaScript shim is injected that wraps `window.WebSocket`.
3. The shim tries a real WebSocket first — if it works (e.g. local dev), zero overhead.
4. When the real WebSocket fails, it falls back to SSE + HTTP POST.
5. `/__wss/events` (SSE) opens a real WebSocket to marimo on localhost and streams messages back.
6. `/__wss/send` (POST) forwards user actions to marimo over that local WebSocket.

<!-- TODO(verify): the shim's fallback currently triggers on WebSocket close
     code 1006 / stall. Confirm on a live SageMaker Studio space that it also
     engages when the failure is a 403 handshake rejection. If it does not, the
     fallback trigger needs to be broadened in the ws-sse-proxy repo. See
     https://github.com/scttfrdmn/aws-marimo-sagemaker/issues/8 -->

### Usage

```bash
pip install marimo ws-sse-proxy
bash start-marimo.sh
```

Then open marimo at the **proxy** port (`2719`), not marimo's port (`2718`):

```
https://<domain>/jupyterlab/default/proxy/2719/
```

<!-- TODO(verify): confirm the exact proxy base path on standalone SageMaker
     Studio vs SageMaker Unified Studio (they differ). See issue #8. -->

## Upstream status

The real fix belongs in marimo (or the marimo Jupyter extension): make the
WebSocket handshake work without the stripped cookie, or add an SSE/long-poll
fallback transport.

- [marimo-team/marimo-jupyter-extension#8](https://github.com/marimo-team/marimo-jupyter-extension/issues/8)
  — "feat: support sagemaker". **Open, unassigned, no fix as of 2026-06-30.**
  Community investigation there identified the cookie-stripping 403 root cause.
- [marimo-team/marimo#8060](https://github.com/marimo-team/marimo/issues/8060)
  — original WebSocket report; closed 2026-02-06 as SageMaker-specific and
  redirected to the extension issue.

Until upstream ships a native fix, **ws-sse-proxy is the working path** for
interactive marimo on SageMaker Studio.

## Alternative: WASM export (no server, no WebSocket)

marimo can run entirely in the browser via WebAssembly/Pyodide, which needs no
WebSocket at all:

```bash
marimo export html-wasm notebook.py -o output_dir
```

This can't access space-local resources (boto3 with the space role, local
files, GPUs), so it's suited to static/shareable notebooks rather than
interactive SageMaker work.
