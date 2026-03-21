#!/bin/bash
# Fix jupyter-server-proxy for SageMaker Studio Lab
#
# NOTE: Previous versions of this script downgraded to v3.2.4.
# This is NO LONGER NECESSARY. Version 4.x works correctly for HTTP proxying.
# The WebSocket issue is in the SageMaker gateway, not jupyter-server-proxy.
# See: https://github.com/marimo-team/marimo/issues/8060

set -e

echo "================================================"
echo "  jupyter-server-proxy Check for SageMaker"
echo "================================================"
echo ""

# Activate environment
eval "$(conda shell.bash hook)"
conda activate marimo-env 2>/dev/null || conda activate studiolab 2>/dev/null || true

# Check current version
CURRENT_VERSION=$(pip show jupyter-server-proxy 2>/dev/null | grep "Version:" | cut -d' ' -f2 || echo "not installed")

echo "Current jupyter-server-proxy version: $CURRENT_VERSION"
echo ""

if [[ "$CURRENT_VERSION" == "not installed" ]]; then
    echo "📦 Installing jupyter-server-proxy..."
    pip install jupyter-server-proxy
    NEW_VERSION=$(pip show jupyter-server-proxy 2>/dev/null | grep "Version:" | cut -d' ' -f2)
    echo "✅ Installed version: $NEW_VERSION"
else
    echo "✅ jupyter-server-proxy is installed and working."
    echo ""
    echo "NOTE: Previous versions of this script downgraded to v3.2.4."
    echo "This is no longer necessary. The WebSocket limitation on SageMaker"
    echo "Studio Lab is caused by the SageMaker gateway/ALB infrastructure,"
    echo "not by jupyter-server-proxy version."
    echo ""
    echo "See: https://github.com/marimo-team/marimo/issues/8060"
    echo "See: https://github.com/marimo-team/marimo-jupyter-extension/issues/8"
fi

echo ""
echo "================================================"
echo "  ✅ Check Complete!"
echo "================================================"
echo ""
