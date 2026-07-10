# Why marimo needs a bridge on SageMaker Studio

## The symptom

On SageMaker Studio, marimo's home page and file browser load fine, but open a
notebook and it stays stuck **"connecting" with blank cells**. The browser
console shows the WebSocket closing with code `1006`, over and over.

## The cause

SageMaker Studio serves apps under a sub-path proxy
(`https://<host>/jupyterlab/default/proxy/PORT/`). **That proxy drops the query
string from WebSocket upgrade requests.**

marimo puts its `session_id` in the WebSocket URL's query:

```
wss://<host>/jupyterlab/default/proxy/2718/ws?file=notebook.py&session_id=s_abc123
```

SageMaker forwards the upgrade to marimo as just `/ws` — no query. marimo
requires `session_id` on `/ws`, so it rejects the handshake with **HTTP 403**,
the browser sees `1006`, and the notebook never connects.

## It's specifically SageMaker

This was isolated to SageMaker's proxy layer, not the tools it runs:

- **marimo is correct.** Its frontend builds the right WebSocket URL, with the
  correct sub-path and `session_id` (confirmed in-browser).
- **`jupyter-server-proxy` is correct.** Vanilla `jupyter-server-proxy` (which
  provides the `/proxy/PORT/` mechanism) *preserves* the WebSocket query — both
  in its source and in a clean-room test. It is SageMaker's own routing layer,
  which wraps the JupyterLab app, that strips the query.

So the query-strip is a SageMaker Studio behavior. WebSockets themselves work
fine through SageMaker's proxy — only the query is lost.

## What the bridge does

`sagemaker_marimo_bridge.py` runs in front of marimo and restores what
SageMaker removes:

1. It reverse-proxies marimo's HTTP and injects a tiny JS shim into the HTML.
2. The shim rewrites marimo's WebSocket URL so the query rides in the **path**
   (`/ws/__wss_q/<url-encoded-query>`) instead of `?query`. Paths pass through
   SageMaker's proxy untouched.
3. The bridge's WebSocket endpoint decodes that path segment back into a real
   query and connects to marimo over **localhost**, where nothing is stripped
   and marimo's origin check is satisfied.

The shim tries a **native WebSocket first**. If SageMaker ever stops stripping
the query, marimo's own URL works unchanged and the bridge becomes a
transparent passthrough — nothing to remove. (There's also an SSE + HTTP-POST
fallback for environments that block WebSockets entirely; it isn't used on
SageMaker, where WebSockets work.)

## The alternative: a custom image

For a permanent, bridge-free setup you can bake marimo into a **custom SageMaker
Studio JupyterLab image**, but that still doesn't fix the query strip — the
bridge (or an AWS-side fix) is what makes the WebSocket connect. Attaching the
bridge via a lifecycle configuration (see the README) is the lighter-weight
path that works on the stock image today.
