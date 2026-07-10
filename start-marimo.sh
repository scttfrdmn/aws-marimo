#!/usr/bin/env bash
# Start marimo on Amazon SageMaker Studio.
#
# Runs marimo behind a small bridge that enables marimo to work on SageMaker.
# See docs/why-the-bridge.md for what the bridge does and why it's needed.
#
# Usage:
#   bash start-marimo.sh [notebook.py] [--open]
#     notebook.py   optional notebook file to open
#     --open        open the browser automatically (local runs only; see note)
#
# Two ways to run, both fine:
#   bash start-marimo.sh                                  # after cloning
#   curl -fsSL <raw-url>/start-marimo.sh | bash           # zero-clone
set -euo pipefail

MARIMO_PORT="${MARIMO_PORT:-2718}"   # marimo backend (localhost only)
BRIDGE_PORT="${BRIDGE_PORT:-2719}"   # what you open through SageMaker

RAW_BASE="https://raw.githubusercontent.com/scttfrdmn/aws-marimo-sagemaker/main"
BRIDGE_FILE="sagemaker_marimo_bridge.py"

# Args: an optional notebook filename and/or --open, in any order.
NOTEBOOK=""
OPEN_BROWSER=0
for arg in "$@"; do
  case "$arg" in
    --open) OPEN_BROWSER=1 ;;
    *) NOTEBOOK="$arg" ;;
  esac
done

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

NB_QUERY=""
[ -n "${NOTEBOOK}" ] && NB_QUERY="?file=${NOTEBOOK}"
PROXY_PATH="/jupyterlab/default/proxy/${BRIDGE_PORT}/${NB_QUERY}"

# Are we on SageMaker Studio, or a local machine?
ON_SAGEMAKER=0
[ -f /opt/ml/metadata/resource-metadata.json ] && ON_SAGEMAKER=1

# --open: only meaningful locally. From a SageMaker terminal there is no way to
# open a tab in your (remote) browser, and the per-space Studio host isn't
# knowable here — so we can't auto-open or even build the full URL for you.
open_local() {
  local url="$1"
  if command -v open >/dev/null 2>&1; then open "$url"; return 0; fi
  if command -v xdg-open >/dev/null 2>&1; then xdg-open "$url"; return 0; fi
  return 1
}

if [ "${OPEN_BROWSER}" -eq 1 ] && [ "${ON_SAGEMAKER}" -eq 0 ]; then
  LOCAL_URL="http://localhost:${BRIDGE_PORT}/${NB_QUERY}"
  echo ""
  echo "Opening ${LOCAL_URL} ..."
  open_local "${LOCAL_URL}" || echo "(no browser opener found — open it manually)"
fi

echo ""
echo "== Ready =="
if [ "${ON_SAGEMAKER}" -eq 1 ]; then
  cat <<EOF

Open marimo in your browser at your JupyterLab host + this path:

    ${PROXY_PATH}

i.e. take the URL in your browser's address bar and replace everything after
the host with the path above. (--open can't help here: the SageMaker terminal
can't open a tab in your local browser.)

Open the bridge port (${BRIDGE_PORT}), not marimo's port (${MARIMO_PORT}).
EOF
else
  echo ""
  echo "Open:  http://localhost:${BRIDGE_PORT}/${NB_QUERY}"
fi
echo ""
echo "Press Ctrl+C to stop."

wait -n "${MARIMO_PID}" "${BRIDGE_PID}" 2>/dev/null || true
