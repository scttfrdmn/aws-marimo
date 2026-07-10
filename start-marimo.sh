#!/usr/bin/env bash
# Start marimo on Amazon SageMaker Studio.
#
# Runs marimo behind a small bridge that enables marimo to work on SageMaker.
# See docs/why-the-bridge.md for what the bridge does and why it's needed.
#
# Usage:
#   bash start-marimo.sh [notebook.py]
#
# Two ways to run, both fine:
#   bash start-marimo.sh                                  # after cloning
#   curl -fsSL <raw-url>/start-marimo.sh | bash           # zero-clone
set -euo pipefail

MARIMO_PORT="${MARIMO_PORT:-2718}"   # marimo backend (localhost only)
BRIDGE_PORT="${BRIDGE_PORT:-2719}"   # what you open through SageMaker
NOTEBOOK="${1:-}"                    # optional notebook file to open

RAW_BASE="https://raw.githubusercontent.com/scttfrdmn/aws-marimo-sagemaker/main"
BRIDGE_FILE="sagemaker_marimo_bridge.py"
METADATA="/opt/ml/metadata/resource-metadata.json"

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

# 5. Build the full URL. The space knows its own Studio host — read the space
#    name / domain from the on-instance metadata and ask the SageMaker API for
#    the space URL. Needs the AWS CLI and sagemaker:DescribeSpace permission;
#    if either is missing we fall back to printing the path to paste.
STUDIO_URL=""
if [ -f "${METADATA}" ] && command -v aws >/dev/null 2>&1; then
  DOMAIN_ID="$(python -c "import json;print(json.load(open('${METADATA}')).get('DomainId',''))" 2>/dev/null || true)"
  SPACE_NAME="$(python -c "import json;print(json.load(open('${METADATA}')).get('SpaceName',''))" 2>/dev/null || true)"
  REGION="$(python -c "import json;a=json.load(open('${METADATA}')).get('ResourceArn','');print(a.split(':')[3] if a.count(':')>3 else '')" 2>/dev/null || true)"
  if [ -n "${DOMAIN_ID}" ] && [ -n "${SPACE_NAME}" ]; then
    BASE_URL="$(aws sagemaker describe-space \
      ${REGION:+--region "${REGION}"} \
      --domain-id "${DOMAIN_ID}" --space-name "${SPACE_NAME}" \
      --query 'Url' --output text 2>/dev/null || true)"
    # describe-space returns .../jupyterlab/default — swap the tail for our path.
    if [ -n "${BASE_URL}" ] && [ "${BASE_URL}" != "None" ]; then
      HOST="${BASE_URL%%/jupyterlab/*}"
      STUDIO_URL="${HOST}${PROXY_PATH}"
    fi
  fi
fi

echo ""
echo "== Ready =="
echo ""
if [ -n "${STUDIO_URL}" ]; then
  echo "Open marimo:"
  echo ""
  echo "    ${STUDIO_URL}"
else
  echo "Open marimo at your JupyterLab host + this path:"
  echo ""
  echo "    ${PROXY_PATH}"
  echo ""
  echo "(Replace everything after the host in your browser's address bar with"
  echo " the path above. Couldn't auto-build the full URL — the AWS CLI or"
  echo " sagemaker:DescribeSpace permission isn't available in this space.)"
fi
echo ""
echo "Use the bridge port (${BRIDGE_PORT}), not marimo's port (${MARIMO_PORT})."
echo "Press Ctrl+C to stop."

wait -n "${MARIMO_PID}" "${BRIDGE_PID}" 2>/dev/null || true
