#!/bin/bash
# SageMaker Studio JupyterLab lifecycle configuration (LCC).
#
# Installs marimo + ws-sse-proxy so they persist across space restarts, instead
# of pip-installing every session. Attach this to the JupyterLab app.
#
# Create the LCC (app type is JupyterLab for the new Studio JupyterLab app —
# verified against the SageMaker API model, not JupyterServer which was the
# Studio Classic value):
#
#   LCC_CONTENT=$(base64 < lifecycle-config/install-marimo.sh)
#   aws sagemaker create-studio-lifecycle-config \
#       --studio-lifecycle-config-name marimo-setup \
#       --studio-lifecycle-config-app-type JupyterLab \
#       --studio-lifecycle-config-content "$LCC_CONTENT"
#
# Then attach it to a domain / user profile / space (JupyterLabAppSettings)
# and select it when launching the JupyterLab space. See:
# https://docs.aws.amazon.com/sagemaker/latest/dg/studio-lifecycle-configurations.html
#
# TODO(verify): confirm LCC attachment + startup on a live JupyterLab space
# (issue #8). On the new SageMaker Studio JupyterLab image the "studio" conda
# env is not required for a pip install into the space's own environment.

set -eux

pip install --upgrade marimo ws-sse-proxy

echo "marimo + ws-sse-proxy installed via lifecycle configuration."
echo "Start with: bash start-marimo.sh   (or your copy of it in the space)"
