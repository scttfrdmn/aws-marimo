#!/bin/bash
# Quick start script for marimo on SageMaker Studio Lab
# Run this each time you start a new Studio Lab session

# Auto-update from GitHub (if repo exists)
if [ -d ~/aws-marimo ]; then
    echo "🔄 Checking for repository updates..."
    cd ~/aws-marimo
    git fetch origin main --quiet 2>/dev/null || true
    LOCAL=$(git rev-parse HEAD 2>/dev/null)
    REMOTE=$(git rev-parse origin/main 2>/dev/null)

    if [ "$LOCAL" != "$REMOTE" ] && [ -n "$REMOTE" ]; then
        echo "📦 Repository updates available! Pulling latest changes..."
        git pull origin main
        echo "✅ Repository updated!"
    else
        echo "✅ Repository is up to date"
    fi
    cd - > /dev/null
    echo ""
fi

# Activate conda environment
eval "$(conda shell.bash hook)"
conda activate marimo-env

# Check if marimo is available
if ! command -v marimo &> /dev/null; then
    echo "❌ marimo not found. Run ~/aws-marimo/studio-lab-setup.sh first"
    exit 1
fi

# Check for marimo updates and offer to upgrade
echo "🔍 Checking marimo version..."
CURRENT_VERSION=$(marimo --version 2>&1)
echo "   Current: $CURRENT_VERSION"

# Check PyPI for latest version (quick check)
LATEST_VERSION=$(pip index versions marimo 2>/dev/null | grep "marimo (" | head -1 | sed 's/marimo (\(.*\))/\1/' || echo "unknown")

if [ "$LATEST_VERSION" != "unknown" ] && [ "$CURRENT_VERSION" != "$LATEST_VERSION" ]; then
    echo "   Latest:  $LATEST_VERSION"
    echo ""
    echo "📦 New marimo version available!"
    read -p "   Upgrade now? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "⬆️  Upgrading marimo..."
        pip install --upgrade marimo
        echo "✅ Upgrade complete!"
        echo ""
    fi
else
    echo "✅ marimo is up to date"
fi

echo ""
echo "================================================"
echo "  🚀 Starting marimo on SageMaker Studio Lab"
echo "================================================"
echo ""
echo "📍 Access marimo through JupyterLab proxy:"
echo ""
echo "   Method 1 (Recommended):"
echo "   • Look for the 🔗 proxy icon in JupyterLab's left sidebar"
echo "   • Click on port 2718 to open marimo"
echo ""
echo "   Method 2 (Manual URL):"
echo "   • Replace your browser URL path with:"
echo "   /studiolab/default/jupyter/proxy/2718/"
echo ""
echo "   Example:"
echo "   https://[your-id].studio.us-east-1.sagemaker.aws/studiolab/default/jupyter/proxy/2718/"
echo ""
echo "================================================"
echo ""

# Start marimo
# Use default port 2718 (Studio Lab's proxy default)
marimo edit --host 0.0.0.0 --port 2718
