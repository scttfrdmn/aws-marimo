#!/bin/bash
# Upgrade marimo and sync with GitHub repository

echo "================================================"
echo "  marimo Update & Upgrade Script"
echo "================================================"
echo ""

# Activate conda environment
eval "$(conda shell.bash hook)"
conda activate marimo-env

# Step 1: Update repository from GitHub
if [ -d ~/aws-marimo ]; then
    echo "📦 Step 1: Updating repository from GitHub..."
    cd ~/aws-marimo
    git pull origin main
    cd - > /dev/null
    echo "✅ Repository updated"
else
    echo "⚠️  Repository not found at ~/aws-marimo"
fi

echo ""

# Step 2: Upgrade marimo package
echo "⬆️  Step 2: Upgrading marimo to latest version..."
CURRENT_VERSION=$(marimo --version 2>&1)
echo "   Current version: $CURRENT_VERSION"
echo ""

pip install --upgrade marimo

NEW_VERSION=$(marimo --version 2>&1)
echo ""
echo "✅ Upgrade complete!"
echo "   New version: $NEW_VERSION"

echo ""
echo "================================================"
echo "  ✅ All updates complete!"
echo "================================================"
echo ""
echo "To start marimo:"
echo "  ~/start-marimo.sh"
echo ""
