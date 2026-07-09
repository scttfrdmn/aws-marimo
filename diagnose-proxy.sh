#!/bin/bash
# Diagnose a marimo + ws-sse-proxy setup on SageMaker Studio.
#
# Checks that both processes are running and listening, so you can tell whether
# a "can't connect" problem is the setup or the proxy path/URL.

MARIMO_PORT=${MARIMO_PORT:-2718}
PROXY_PORT=${PROXY_PORT:-2719}

echo "================================================"
echo "  marimo / ws-sse-proxy diagnostic"
echo "================================================"
echo ""

echo "1) Packages"
marimo --version 2>&1 | sed 's/^/   marimo: /' || echo "   marimo: NOT installed (pip install marimo)"
python -c "import ws_sse_proxy" 2>/dev/null \
    && echo "   ws-sse-proxy: installed" \
    || echo "   ws-sse-proxy: NOT installed (pip install ws-sse-proxy)"

echo ""
echo "2) Processes"
pgrep -f "marimo edit" >/dev/null && echo "   marimo: running" || echo "   marimo: not running"
pgrep -f "ws-sse-proxy" >/dev/null && echo "   ws-sse-proxy: running" || echo "   ws-sse-proxy: not running"

echo ""
echo "3) Local HTTP checks"
if curl -s "http://127.0.0.1:$MARIMO_PORT/" >/dev/null 2>&1; then
    echo "   marimo responds on 127.0.0.1:$MARIMO_PORT"
else
    echo "   marimo NOT responding on 127.0.0.1:$MARIMO_PORT"
fi
if curl -s "http://127.0.0.1:$PROXY_PORT/" >/dev/null 2>&1; then
    echo "   ws-sse-proxy responds on 127.0.0.1:$PROXY_PORT"
else
    echo "   ws-sse-proxy NOT responding on 127.0.0.1:$PROXY_PORT"
fi

echo ""
echo "4) Listening ports"
{ ss -tlnp 2>/dev/null || netstat -tln 2>/dev/null; } | grep -E ":$MARIMO_PORT|:$PROXY_PORT" \
    || echo "   (no listeners found on $MARIMO_PORT / $PROXY_PORT)"

echo ""
echo "================================================"
echo "  Access URL"
echo "================================================"
echo ""
echo "Open the PROXY port ($PROXY_PORT), NOT marimo's port ($MARIMO_PORT):"
echo ""
echo "  https://<domain>.studio.<region>.sagemaker.aws/jupyterlab/default/proxy/$PROXY_PORT/"
echo ""
echo "  (SageMaker Unified Studio uses a different proxy base path —"
echo "   see WEBSOCKET-STATUS.md / issue #8.)"
echo ""
echo "If marimo loads but cells won't run, that's the WebSocket 403 issue —"
echo "make sure you started via start-marimo.sh and are on port $PROXY_PORT."
