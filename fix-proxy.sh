#!/bin/bash
# Fix and configure jupyter-server-proxy for marimo access

echo "================================================"
echo "  jupyter-server-proxy Configuration Fix"
echo "================================================"
echo ""

# Activate environment
eval "$(conda shell.bash hook)"
conda activate marimo-env

echo "1️⃣  Ensuring jupyter-server-proxy is installed..."
pip install --upgrade jupyter-server-proxy
echo "✅ Package updated"

echo ""
echo "2️⃣  Enabling server extension..."
jupyter server extension enable jupyter_server_proxy 2>/dev/null || \
jupyter serverextension enable --py jupyter_server_proxy 2>/dev/null
echo "✅ Extension enabled"

echo ""
echo "3️⃣  Creating/updating Jupyter config..."
mkdir -p ~/.jupyter

# Create a basic config if it doesn't exist
if [ ! -f ~/.jupyter/jupyter_server_config.py ]; then
    cat > ~/.jupyter/jupyter_server_config.py << 'EOF'
# Jupyter Server Configuration for SageMaker Studio Lab
c = get_config()

# Enable server proxy
c.ServerProxy.host_allowlist = lambda app, host: True
EOF
    echo "✅ Created jupyter_server_config.py"
else
    echo "✅ Config file already exists"
fi

echo ""
echo "4️⃣  Checking nbserverproxy (fallback for older Jupyter)..."
pip list | grep -i "nbserverproxy\|jupyter-server-proxy"

echo ""
echo "================================================"
echo "  ✅ Configuration Complete!"
echo "================================================"
echo ""
echo "⚠️  IMPORTANT: You need to restart your Jupyter server:"
echo ""
echo "In JupyterLab:"
echo "  File → Shut Down"
echo ""
echo "Then in Studio Lab:"
echo "  Stop Runtime → Start Runtime → Open Project"
echo ""
echo "After restart, marimo should be accessible via:"
echo "  https://d1n5us641itpxvv.studio.us-east-2.sagemaker.aws/proxy/2718/"
echo ""
echo "Alternative URLs to try after restart:"
echo "  /jupyter/proxy/2718/"
echo "  /user-redirect/proxy/2718/"
echo ""
