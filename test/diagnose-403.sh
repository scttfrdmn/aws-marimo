#!/bin/bash
# Diagnose marimo's /ws 403 on localhost (no proxy, no browser involved).
#
# Phase 1 showed marimo rejects a direct localhost WebSocket with 403, even
# though it was started with --no-token. This isolates WHY, by varying the
# Origin header sent on the handshake. Run it while start-marimo.sh is running
# (marimo on 2718). Diagnose-only — changes nothing.

MARIMO_PORT=${MARIMO_PORT:-2718}

echo "=============================================================="
echo "  marimo /ws 403 diagnosis (direct to 127.0.0.1:$MARIMO_PORT)"
echo "=============================================================="
echo ""
echo "marimo version: $(marimo --version 2>&1)"
echo ""

python - "$MARIMO_PORT" <<'PY'
import sys, asyncio
port = sys.argv[1]
import websockets
import websockets.asyncio.client as wsc

# (label, kwargs for connect). Vary Origin; also try a session_id query param.
cases = [
    ("no Origin header",            f"ws://127.0.0.1:{port}/ws", {}),
    ("Origin http://127.0.0.1:PORT",f"ws://127.0.0.1:{port}/ws", {"additional_headers": {"Origin": f"http://127.0.0.1:{port}"}}),
    ("Origin http://localhost:PORT",f"ws://127.0.0.1:{port}/ws", {"additional_headers": {"Origin": f"http://localhost:{port}"}}),
    ("Origin http://localhost",     f"ws://127.0.0.1:{port}/ws", {"additional_headers": {"Origin": "http://localhost"}}),
    ("no Origin + session_id",      f"ws://127.0.0.1:{port}/ws?session_id=s_diag01&file=__new__", {}),
]

async def try_case(label, url, kwargs):
    try:
        async with wsc.connect(url, open_timeout=5, **kwargs) as ws:
            # Connected. Try to read one frame (or time out) to see if it stays open.
            try:
                msg = await asyncio.wait_for(ws.recv(), timeout=2)
                print(f"  ACCEPTED  [{label}] -> open, first frame: {str(msg)[:80]!r}")
            except asyncio.TimeoutError:
                print(f"  ACCEPTED  [{label}] -> open, no frame within 2s")
            return True
    except Exception as e:
        code = getattr(getattr(e, "response", None), "status_code", None)
        print(f"  REJECTED  [{label}] -> {type(e).__name__}"
              + (f" (HTTP {code})" if code else f": {e}"))
        return False

async def main():
    for label, url, kwargs in cases:
        await try_case(label, url, kwargs)

asyncio.run(main())
PY

echo ""
echo "=============================================================="
echo "  Interpretation"
echo "=============================================================="
echo "- If a MATCHING Origin (127.0.0.1:PORT / localhost:PORT) is ACCEPTED but"
echo "  'http://localhost' is REJECTED -> it's marimo's Origin check. Fix:"
echo "  ws-sse-proxy should send a matching Origin (or none), or start marimo"
echo "  with --allow-origins '*'."
echo "- If ALL are REJECTED with 403 regardless of Origin -> it's auth/token or"
echo "  a required session context, not Origin."
echo "- Also check Terminal 1 (marimo's log) for the matching rejection lines."
echo ""
echo "Next optional test: restart marimo with --allow-origins '*' and re-run"
echo "  bash verify-sagemaker.sh   (see if check [4] flips to 200)."
