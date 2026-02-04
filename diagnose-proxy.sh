#!/bin/bash
# Diagnostic script to help find the correct marimo access URL

echo "================================================"
echo "  marimo Proxy Diagnostic Tool"
echo "================================================"
echo ""

# Activate environment
eval "$(conda shell.bash hook)"
conda activate marimo-env 2>/dev/null

echo "1️⃣  Checking jupyter-server-proxy installation..."
if python -c "import jupyter_server_proxy" 2>/dev/null; then
    echo "✅ jupyter-server-proxy is installed"
    VERSION=$(pip show jupyter-server-proxy 2>/dev/null | grep Version | cut -d' ' -f2)
    echo "   Version: $VERSION"
else
    echo "❌ jupyter-server-proxy NOT installed"
    echo "   Installing now..."
    pip install jupyter-server-proxy
fi

echo ""
echo "2️⃣  Checking Jupyter server extensions..."
jupyter server extension list 2>/dev/null || jupyter serverextension list 2>/dev/null

echo ""
echo "3️⃣  Checking if marimo is running..."
if pgrep -f "marimo edit" > /dev/null; then
    echo "✅ marimo process is running"
    PORT=$(ps aux | grep "marimo edit" | grep -o "port [0-9]*" | grep -o "[0-9]*" | head -1)
    if [ -z "$PORT" ]; then
        PORT="2718"
    fi
    echo "   Port: $PORT"
else
    echo "⚠️  marimo is NOT running"
    echo "   Start it with: ~/start-marimo.sh"
fi

echo ""
echo "4️⃣  Checking network connections..."
if command -v netstat > /dev/null; then
    echo "Listening ports:"
    netstat -tuln 2>/dev/null | grep "2718\|8888" || ss -tuln 2>/dev/null | grep "2718\|8888"
elif command -v ss > /dev/null; then
    echo "Listening ports:"
    ss -tuln 2>/dev/null | grep "2718\|8888"
fi

echo ""
echo "5️⃣  Testing proxy configuration..."
# Check if jupyter-server-proxy config exists
if [ -f ~/.jupyter/jupyter_server_config.py ]; then
    echo "✅ Jupyter config exists"
    if grep -q "server_proxy" ~/.jupyter/jupyter_server_config.py; then
        echo "   Contains server_proxy configuration"
    fi
else
    echo "⚠️  No custom jupyter config found (using defaults)"
fi

echo ""
echo "6️⃣  Environment information..."
echo "JUPYTER_CONFIG_DIR: ${JUPYTER_CONFIG_DIR:-not set}"
echo "JUPYTER_DATA_DIR: ${JUPYTER_DATA_DIR:-not set}"
echo "JUPYTER_RUNTIME_DIR: ${JUPYTER_RUNTIME_DIR:-not set}"

echo ""
echo "================================================"
echo "  📋 Recommended URLs to Try"
echo "================================================"
echo ""
echo "Try these URLs in order (replace YOUR-DOMAIN):"
echo ""
echo "1. https://YOUR-DOMAIN/proxy/2718/"
echo "2. https://YOUR-DOMAIN/studiolab/default/jupyter/proxy/2718/"
echo "3. https://YOUR-DOMAIN/jupyter/proxy/2718/"
echo "4. https://YOUR-DOMAIN/user-redirect/proxy/2718/"
echo ""
echo "Your current domain:"
echo "https://d1n5us641itpxvv.studio.us-east-2.sagemaker.aws"
echo ""
echo "================================================"
echo ""
echo "If none work, try these steps:"
echo ""
echo "Step A: Enable jupyter-server-proxy extension"
echo "  jupyter server extension enable jupyter_server_proxy"
echo ""
echo "Step B: Restart Jupyter server"
echo "  (File → Shut Down → Restart runtime in Studio Lab)"
echo ""
echo "Step C: Check JupyterLab's running terminals/kernels"
echo "  Look for a 'Proxied' section or similar in JupyterLab"
echo ""
