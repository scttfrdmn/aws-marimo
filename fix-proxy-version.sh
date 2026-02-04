#!/bin/bash
# Fix jupyter-server-proxy version for SageMaker Studio Lab compatibility
# Version 4.x breaks SageMaker - this downgrades to working version 3.2.2

set -e

echo "================================================"
echo "  Fix jupyter-server-proxy for SageMaker Studio Lab"
echo "================================================"
echo ""

PROXY_VERSION="3.2.2"

# Activate marimo environment
eval "$(conda shell.bash hook)"
conda activate marimo-env 2>/dev/null || conda activate studiolab 2>/dev/null || true

# Check current version
CURRENT_VERSION=$(pip show jupyter-server-proxy 2>/dev/null | grep "Version:" | cut -d' ' -f2 || echo "not installed")

echo "Current jupyter-server-proxy version: $CURRENT_VERSION"
echo "Required version: $PROXY_VERSION"
echo ""

if [[ "$CURRENT_VERSION" == "$PROXY_VERSION" ]]; then
    echo "✅ Already on correct version!"
    exit 0
fi

echo "⚠️  Version $CURRENT_VERSION is incompatible with SageMaker Studio Lab"
echo "   (Version 4.x breaks WebSocket connections)"
echo ""
echo "📦 Installing correct version..."

# Remove bad config if it exists
if [ -f ~/.jupyter/jupyter_server_config.py ]; then
    echo "🗑️  Removing problematic config file..."
    mv ~/.jupyter/jupyter_server_config.py ~/.jupyter/jupyter_server_config.py.backup
    echo "   Backup saved to: ~/.jupyter/jupyter_server_config.py.backup"
fi

# Install correct version
pip install jupyter-server-proxy==$PROXY_VERSION --force-reinstall --no-deps

# Verify
NEW_VERSION=$(pip show jupyter-server-proxy 2>/dev/null | grep "Version:" | cut -d' ' -f2)

echo ""
echo "================================================"
echo "  ✅ Fix Complete!"
echo "================================================"
echo ""
echo "New version: $NEW_VERSION"
echo ""
echo "⚠️  IMPORTANT: You MUST restart Jupyter for changes to take effect:"
echo ""
echo "  1. In JupyterLab: File → Shut Down"
echo "  2. In Studio Lab: Stop Runtime"
echo "  3. Start Runtime"
echo "  4. Open Project"
echo ""
echo "After restart, marimo should work without 403 errors!"
echo ""
