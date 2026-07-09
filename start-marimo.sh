#!/bin/bash
# Start marimo on Amazon SageMaker Studio (JupyterLab) via ws-sse-proxy.
#
# Why the proxy: SageMaker's JupyterLab proxy does not forward marimo's session
# cookie, so marimo rejects the /ws WebSocket handshake with HTTP 403 and
# notebooks never connect. ws-sse-proxy opens the WebSocket to marimo over
# localhost (where the cookie/origin are intact) and exposes only HTTP + SSE
# through the SageMaker proxy. See WEBSOCKET-STATUS.md.
#
# This launches two processes:
#   1. marimo      on port 2718 (backend, localhost only, not exposed directly)
#   2. ws-sse-proxy on port 2719 (what you access through the SageMaker proxy)
#
# Access marimo at the proxy port, NOT marimo's port:
#   https://<domain>/jupyterlab/default/proxy/2719/
#   TODO(verify): confirm the exact proxy base path on your Studio JupyterLab
#   space. Reported as /jupyterlab/default/proxy/PORT/ (see issue #8).

set -e

MARIMO_PORT=${MARIMO_PORT:-2718}
PROXY_PORT=${PROXY_PORT:-2719}

# On SageMaker Studio JupyterLab, the "studio" conda env is already active in a
# space; we do NOT assume a dedicated marimo-env (that was the Studio Lab model).
# Just make sure the two tools are importable in the current environment.
if ! command -v marimo &>/dev/null; then
    echo "Installing marimo..."
    pip install --quiet marimo
fi

python -c "import ws_sse_proxy" 2>/dev/null || {
    echo "Installing ws-sse-proxy..."
    pip install --quiet ws-sse-proxy
}

cleanup() {
    echo ""
    echo "Shutting down..."
    [ -n "$MARIMO_PID" ] && kill "$MARIMO_PID" 2>/dev/null || true
    [ -n "$PROXY_PID" ] && kill "$PROXY_PID" 2>/dev/null || true
    wait 2>/dev/null
    echo "Done."
}
trap cleanup EXIT INT TERM

echo "================================================"
echo "  marimo on SageMaker Studio (via ws-sse-proxy)"
echo "================================================"
echo ""
echo "Starting marimo on 127.0.0.1:$MARIMO_PORT ..."

# Bind marimo to localhost only — the proxy reaches it locally, and it should
# never be exposed directly (that path has the broken WebSocket).
# --no-token: the SageMaker proxy already gates access; --headless: no browser.
marimo edit --host 127.0.0.1 --port "$MARIMO_PORT" --no-token --headless &
MARIMO_PID=$!

echo "Waiting for marimo to start..."
for _ in $(seq 1 30); do
    if curl -s "http://127.0.0.1:$MARIMO_PORT/" >/dev/null 2>&1; then
        echo "marimo is ready."
        break
    fi
    sleep 1
done

echo ""
echo "Starting ws-sse-proxy on port $PROXY_PORT ..."
ws-sse-proxy --target-port "$MARIMO_PORT" --listen-port "$PROXY_PORT" &
PROXY_PID=$!

echo ""
echo "================================================"
echo "  Ready!"
echo "================================================"
echo ""
echo "Open marimo through the SageMaker JupyterLab proxy at the PROXY port"
echo "$PROXY_PORT (NOT marimo's port $MARIMO_PORT). Copy your JupyterLab URL and"
echo "replace everything after the host with the proxy path:"
echo ""
echo "  Standalone SageMaker Studio:"
echo "    https://<domain>.studio.<region>.sagemaker.aws/jupyterlab/default/proxy/$PROXY_PORT/"
echo ""
echo "  SageMaker Unified Studio: the proxy base path differs from the above."
echo "  TODO(verify): confirm the Unified Studio JupyterLab proxy path (issue #8)."
echo ""
echo "  marimo PID: $MARIMO_PID (127.0.0.1:$MARIMO_PORT)"
echo "  proxy PID:  $PROXY_PID (0.0.0.0:$PROXY_PORT)"
echo ""
echo "Press Ctrl+C to stop both."
echo ""

# Exit (and trigger cleanup) as soon as either process dies.
wait -n "$MARIMO_PID" "$PROXY_PID" 2>/dev/null || true
