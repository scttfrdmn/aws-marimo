#!/usr/bin/env bash
# Start marimo on Amazon SageMaker Studio.
#
# Runs marimo behind a small bridge that enables marimo to work on SageMaker.
# See docs/why-the-bridge.md for what the bridge does and why it's needed.
#
# Two ways to run, both fine:
#   bash start-marimo.sh                                  # after cloning
#   curl -fsSL <raw-url>/start-marimo.sh | bash           # zero-clone
#
# Then open the printed URL in your browser.
set -euo pipefail

MARIMO_PORT="${MARIMO_PORT:-2718}"   # marimo backend (localhost only)
BRIDGE_PORT="${BRIDGE_PORT:-2719}"   # what you open through SageMaker
NOTEBOOK="${1:-}"                    # optional notebook file to open

RAW_BASE="https://raw.githubusercontent.com/scttfrdmn/aws-marimo-sagemaker/main"
BRIDGE_FILE="sagemaker_marimo_bridge.py"

echo "== marimo on SageMaker Studio =="

# 1. Dependencies. marimo pulls in starlette/uvicorn/httpx/websockets, so the
#    bridge needs nothing extra.
if ! command -v marimo >/dev/null 2>&1; then
  echo "Installing marimo..."
  pip install --quiet marimo
fi

# 2. Locate the bridge next to this script; otherwise fetch it (curl|bash case).
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd || true)"
if [ -n "${SCRIPT_DIR:-}" ] && [ -f "${SCRIPT_DIR}/${BRIDGE_FILE}" ]; then
  BRIDGE_PATH="${SCRIPT_DIR}/${BRIDGE_FILE}"
else
  BRIDGE_PATH="$(mktemp -t marimo_bridge.XXXXXX.py)"
  echo "Fetching bridge..."
  curl -fsSL "${RAW_BASE}/${BRIDGE_FILE}" -o "${BRIDGE_PATH}"
fi

cleanup() {
  echo ""
  echo "Shutting down..."
  [ -n "${MARIMO_PID:-}" ] && kill "${MARIMO_PID}" 2>/dev/null || true
  [ -n "${BRIDGE_PID:-}" ] && kill "${BRIDGE_PID}" 2>/dev/null || true
  wait 2>/dev/null || true
}
trap cleanup EXIT INT TERM

# 3. marimo on localhost only (never exposed directly — the bridge fronts it).
#    --no-token: SageMaker already gates access to the space.
echo "Starting marimo on 127.0.0.1:${MARIMO_PORT} ..."
# shellcheck disable=SC2086
marimo edit ${NOTEBOOK} --host 127.0.0.1 --port "${MARIMO_PORT}" --no-token --headless &
MARIMO_PID=$!

for _ in $(seq 1 30); do
  curl -sf "http://127.0.0.1:${MARIMO_PORT}/" >/dev/null 2>&1 && break
  sleep 1
done

# 4. The bridge, on the port you actually open.
echo "Starting bridge on 0.0.0.0:${BRIDGE_PORT} ..."
python "${BRIDGE_PATH}" --marimo-port "${MARIMO_PORT}" --port "${BRIDGE_PORT}" &
BRIDGE_PID=$!

# 5. Print the URL to open.
NB_QUERY=""
[ -n "${NOTEBOOK}" ] && NB_QUERY="?file=${NOTEBOOK}"
cat <<EOF

== Ready ==

Open marimo through the SageMaker proxy at the BRIDGE port (${BRIDGE_PORT}).
Take your JupyterLab URL and replace everything after the host with:

    /jupyterlab/default/proxy/${BRIDGE_PORT}/${NB_QUERY}

e.g.  https://<studio-host>/jupyterlab/default/proxy/${BRIDGE_PORT}/${NB_QUERY}

(Do NOT open port ${MARIMO_PORT} directly — that path has the broken WebSocket.)

Press Ctrl+C to stop.
EOF

wait -n "${MARIMO_PID}" "${BRIDGE_PID}" 2>/dev/null || true
