# Verification checklist — marimo on SageMaker via ws-sse-proxy

Acceptance criteria for [issue #8](https://github.com/scttfrdmn/aws-marimo-sagemaker/issues/8).
Two phases: a terminal harness (server-side, no browser) and a browser check
(the UX + the make-or-break fallback behavior). The browser phase can be driven
by a human or by Claude Desktop Cowork.

## Setup

In a JupyterLab terminal inside the SageMaker Studio / Unified Studio space:

```bash
pip install marimo ws-sse-proxy
curl -fsSL https://raw.githubusercontent.com/scttfrdmn/aws-marimo-sagemaker/main/start-marimo.sh -o start-marimo.sh
bash start-marimo.sh          # leave running in one terminal
```

## Phase 1 — server-side (terminal, automated)

In a second terminal:

```bash
curl -fsSL https://raw.githubusercontent.com/scttfrdmn/aws-marimo-sagemaker/main/test/verify-sagemaker.sh -o verify-sagemaker.sh
bash verify-sagemaker.sh
```

Interpreting check **[4]** (make-or-break):
- **PASS (200 / text/event-stream)** → the proxy opened a WebSocket to marimo
  over localhost successfully. The mechanism works server-side; the 403 was an
  origin/context issue that the localhost hop resolves. Proceed to Phase 2.
- **FAIL (502)** → marimo rejected the proxy's localhost WebSocket too. That
  means marimo's 403 is a genuine session-cookie requirement, and ws-sse-proxy
  isn't forwarding the cookie. **Stop and report** — the fix belongs in the
  ws-sse-proxy repo (forward marimo's `Set-Cookie`/session cookie to the
  localhost WS). Do not edit anything yet.

Capture: paste the full Phase 1 output into issue #8.

## Phase 2 — browser (Cowork or human)

Determine the proxy URL. Copy your JupyterLab URL and replace the trailing path
so it points at the **proxy** port `2719`:

- Standalone SageMaker Studio: `…/jupyterlab/default/proxy/2719/`
- **SageMaker Unified Studio: the base path differs — record the actual working
  path here once found (this is a documentation TODO):** `__________________`

Steps (with browser dev tools open — Network + Console):

1. **Load** the proxy URL. The marimo home screen should appear.
   - [ ] Home screen renders.

2. **Watch the WebSocket fallback** (the key observation). In Console you should
   see one of:
   - `[ws-sse-proxy] WebSocket closed with 1006, falling back to SSE`, or
   - `[ws-sse-proxy] WebSocket stalled, falling back to SSE`.
   In Network, filter for `__wss/events` — an `EventSource` request should be
   open (pending / streaming), status 200.
   - [ ] Fallback message seen in console.
   - [ ] `/__wss/events` EventSource open (200, event-stream).
   - [ ] Record what the failed `/ws` attempt showed (status, close code): `____`

3. **Create a notebook** and run a cell (e.g. `print(1+1)`).
   - [ ] Cell executes and shows output (kernel connects — no "connecting" hang).

4. **Reactivity**: add `s = mo.ui.slider(0,100)` in one cell and
   `mo.md(f"{s.value}")` in another; move the slider.
   - [ ] Dependent cell updates automatically.

5. **Widget**: confirm a `mo.ui.table(...)` or `mo.ui.dropdown(...)` is
   interactive.
   - [ ] Widget interactive.

6. **Screenshots** for the blog post: (a) a reactive slider updating a plot,
   (b) the Network tab showing the SSE `/__wss/events` stream.
   - [ ] Screenshots captured.

## Reporting back

Post to issue #8:
- Phase 1 output (all four checks).
- Phase 2 checkbox results + the failed `/ws` status/close-code from step 2.
- The confirmed Unified Studio proxy base path.
- Screenshots.

Once green, remove the `TODO(verify)` markers in README.md, QUICKSTART.md,
WEBSOCKET-STATUS.md, and blog-post.md, and flip the support-matrix ⚠️ rows to ✅.
