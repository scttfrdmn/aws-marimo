#!/bin/bash
# SageMaker Studio JupyterLab lifecycle configuration (LCC).
#
# Installs marimo and downloads the bridge into the space so they persist
# across restarts, instead of running start-marimo.sh from scratch each
# session. After this runs, launch marimo with:
#
#   bash ~/aws-marimo-sagemaker-start.sh          # or the copy in your space
#
# --- Create and attach the LCC (run once, from your machine or CloudShell) ---
#
#   LCC_CONTENT=$(base64 < lifecycle-config/install.sh)
#   aws sagemaker create-studio-lifecycle-config \
#       --studio-lifecycle-config-name marimo-setup \
#       --studio-lifecycle-config-app-type JupyterLab \
#       --studio-lifecycle-config-content "$LCC_CONTENT"
#
# Then attach it under JupyterLabAppSettings on the domain / user profile /
# space and select it when launching the JupyterLab space:
# https://docs.aws.amazon.com/sagemaker/latest/dg/studio-lifecycle-configurations.html
set -eux

RAW_BASE="https://raw.githubusercontent.com/scttfrdmn/aws-marimo-sagemaker/main"

# marimo brings starlette/uvicorn/httpx/websockets, which the bridge reuses.
pip install --upgrade marimo

# Drop the bridge and launcher into the home dir (persisted on the space EBS).
curl -fsSL "${RAW_BASE}/sagemaker_marimo_bridge.py" -o ~/sagemaker_marimo_bridge.py
curl -fsSL "${RAW_BASE}/start-marimo.sh"            -o ~/aws-marimo-sagemaker-start.sh
chmod +x ~/aws-marimo-sagemaker-start.sh

echo "marimo + bridge installed. Start with:"
echo "  bash ~/aws-marimo-sagemaker-start.sh"
