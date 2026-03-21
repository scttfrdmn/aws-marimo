#!/bin/bash
# Start marimo with ws-sse-proxy for SageMaker Studio Lab.
#
# This launches two processes:
#   1. marimo on port 2718 (backend, not directly exposed)
#   2. ws-sse-proxy on port 2719 (translates WebSocket to SSE for the gateway)
#
# Access marimo at: /proxy/2719/
# (NOT /proxy/2718/ — that bypasses the proxy)

set -e

MARIMO_PORT=${MARIMO_PORT:-2718}
PROXY_PORT=${PROXY_PORT:-2719}

# Activate conda env if available
if command -v conda &>/dev/null; then
    eval "$(conda shell.bash hook)"
    conda activate marimo-env 2>/dev/null || true
fi

# Check dependencies
if ! command -v marimo &>/dev/null; then
    echo "Error: marimo not found. Install with: pip install marimo"
    exit 1
fi

python -c "import ws_sse_proxy" 2>/dev/null || {
    echo "Installing ws-sse-proxy..."
    pip install ws-sse-proxy
}

cleanup() {
    echo ""
    echo "Shutting down..."
    if [ -n "$MARIMO_PID" ]; then
        kill "$MARIMO_PID" 2>/dev/null || true
    fi
    if [ -n "$PROXY_PID" ]; then
        kill "$PROXY_PID" 2>/dev/null || true
    fi
    wait 2>/dev/null
    echo "Done."
}
trap cleanup EXIT INT TERM

echo "================================================"
echo "  marimo on SageMaker (via ws-sse-proxy)"
echo "================================================"
echo ""
echo "Starting marimo on port $MARIMO_PORT..."

# Start marimo in the background
marimo edit --host 0.0.0.0 --port "$MARIMO_PORT" --no-token --headless &
MARIMO_PID=$!

# Wait for marimo to be ready
echo "Waiting for marimo to start..."
for i in $(seq 1 30); do
    if curl -s "http://localhost:$MARIMO_PORT/health" >/dev/null 2>&1 || \
       curl -s "http://localhost:$MARIMO_PORT/" >/dev/null 2>&1; then
        echo "marimo is ready."
        break
    fi
    sleep 1
done

echo ""
echo "Starting ws-sse-proxy on port $PROXY_PORT..."

# Start the proxy
ws-sse-proxy --target-port "$MARIMO_PORT" --listen-port "$PROXY_PORT" &
PROXY_PID=$!

echo ""
echo "================================================"
echo "  Ready!"
echo "================================================"
echo ""
echo "Access marimo at:"
echo ""
echo "  /studiolab/default/jupyter/proxy/$PROXY_PORT/"
echo ""
echo "  (Replace /studiolab/default/jupyter/ with your base URL)"
echo ""
echo "  marimo PID:  $MARIMO_PID (port $MARIMO_PORT)"
echo "  proxy PID:   $PROXY_PID (port $PROXY_PORT)"
echo ""
echo "Press Ctrl+C to stop both."
echo ""

# Wait for either process to exit
wait -n "$MARIMO_PID" "$PROXY_PID" 2>/dev/null || true
