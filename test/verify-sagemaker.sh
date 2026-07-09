#!/bin/bash
# Phase 1 verification harness for marimo + ws-sse-proxy on SageMaker.
#
# Run this in a TERMINAL inside your SageMaker Studio / Unified Studio JupyterLab
# space. It proves the parts that can be checked without a browser:
#   - marimo is up on localhost
#   - ws-sse-proxy is up
#   - marimo accepts a direct localhost WebSocket (the premise of the fix)
#   - the proxy's SSE bridge (/__wss/events) actually connects to marimo
#
# The last check is the make-or-break one: it isolates whether marimo's 403 is
# an Origin check (proxy's Origin: http://localhost satisfies it -> works) or a
# genuine session-cookie requirement (proxy forwards no cookie -> 502 -> the fix
# needs to forward the cookie). See WEBSOCKET-STATUS.md and issue #8.
#
# It does NOT prove the browser UX (cell execution, reactive updates) — that
# requires a real browser; see test/CHECKLIST.md (Phase 2).

set -u

MARIMO_PORT=${MARIMO_PORT:-2718}
PROXY_PORT=${PROXY_PORT:-2719}
PASS=0; FAIL=0; WARN=0
ok()   { echo "  PASS: $*"; PASS=$((PASS+1)); }
bad()  { echo "  FAIL: $*"; FAIL=$((FAIL+1)); }
warn() { echo "  WARN: $*"; WARN=$((WARN+1)); }

echo "================================================================"
echo "  Phase 1: marimo + ws-sse-proxy server-side verification"
echo "================================================================"

echo ""
echo "[1] Packages installed"
marimo --version >/dev/null 2>&1 && ok "marimo $(marimo --version 2>&1)" || bad "marimo not installed"
python -c "import ws_sse_proxy" 2>/dev/null && ok "ws-sse-proxy importable" || bad "ws-sse-proxy not installed"

echo ""
echo "[2] Processes listening"
curl -s "http://127.0.0.1:$MARIMO_PORT/" >/dev/null 2>&1 \
    && ok "marimo responds on 127.0.0.1:$MARIMO_PORT" \
    || bad "marimo not responding on $MARIMO_PORT — start it: bash start-marimo.sh"
curl -s "http://127.0.0.1:$PROXY_PORT/" >/dev/null 2>&1 \
    && ok "ws-sse-proxy responds on 127.0.0.1:$PROXY_PORT" \
    || bad "ws-sse-proxy not responding on $PROXY_PORT"

echo ""
echo "[3] Does marimo accept a direct localhost WebSocket? (the premise)"
# Python check: open a WS to marimo on localhost with Origin: http://localhost,
# exactly as the proxy does. If this succeeds, marimo is not blocking on cookie
# for a localhost/origin-clean client.
python - "$MARIMO_PORT" <<'PY'
import sys, asyncio
port = sys.argv[1]
async def main():
    try:
        import websockets
    except ImportError:
        print("  WARN: 'websockets' not importable standalone; it ships with ws-sse-proxy")
        return 2
    url = f"ws://127.0.0.1:{port}/ws"
    try:
        async with websockets.connect(url, additional_headers={"Origin":"http://localhost"}, open_timeout=5) as ws:
            print(f"  PASS: marimo accepted localhost WebSocket at {url}")
            return 0
    except Exception as e:
        print(f"  FAIL: marimo REJECTED localhost WebSocket: {type(e).__name__}: {e}")
        print("        -> If this is a 403, marimo requires the session cookie even")
        print("           on localhost; ws-sse-proxy must forward it. (diagnose-only)")
        return 1
sys.exit(asyncio.run(main()))
PY
rc=$?
[ $rc -eq 0 ] && PASS=$((PASS+1)); [ $rc -eq 1 ] && FAIL=$((FAIL+1)); [ $rc -eq 2 ] && WARN=$((WARN+1))

echo ""
echo "[4] MAKE-OR-BREAK: does the proxy's SSE bridge connect to marimo?"
# Hit the proxy's SSE endpoint the way the browser shim does. A 200 text/event-stream
# that stays open == the bridge opened a WS to marimo successfully. A 502 == marimo
# rejected the proxy's localhost WS (cookie-based 403). We read for 3s then stop.
SSE_URL="http://127.0.0.1:$PROXY_PORT/__wss/events?__wss_id=verify1&__wss_path=%2Fws"
hdrs=$(curl -s -m 3 -D - -o /dev/null -H "Accept: text/event-stream" "$SSE_URL" 2>/dev/null || true)
code=$(printf '%s' "$hdrs" | awk 'NR==1{print $2}')
ctype=$(printf '%s' "$hdrs" | tr -d '\r' | awk -F': ' 'tolower($1)=="content-type"{print $2}')
echo "  HTTP status: ${code:-<none/timeout>}   Content-Type: ${ctype:-<none>}"
if [ "$code" = "200" ] && printf '%s' "$ctype" | grep -qi "text/event-stream"; then
    ok "SSE bridge connected to marimo (proxy opened the localhost WebSocket)"
    echo "       => the fix works server-side; confirm the UI in Phase 2 (test/CHECKLIST.md)"
elif [ "$code" = "502" ]; then
    bad "SSE bridge got 502 — marimo rejected the proxy's localhost WebSocket"
    echo "       => cookie-based 403. Diagnose-only outcome: ws-sse-proxy needs to"
    echo "          forward marimo's session cookie. Report back before any code change."
else
    warn "Unexpected/no response from SSE bridge (status=${code:-none}). Re-run with the"
    warn "proxy log visible: ws-sse-proxy --log-level DEBUG ... and inspect."
fi

echo ""
echo "================================================================"
echo "  Phase 1 result: PASS=$PASS  FAIL=$FAIL  WARN=$WARN"
echo "================================================================"
echo "Next: Phase 2 (browser) — see test/CHECKLIST.md."
[ $FAIL -eq 0 ]
