#!/bin/bash
# One-Command Bootstrap for SageMaker Studio Lab
# Run this: curl -fsSL https://raw.githubusercontent.com/scttfrdmn/aws-marimo-sagemaker/main/bootstrap.sh | bash

set -e

echo "================================================"
echo "  marimo Bootstrap - Auto Setup from GitHub"
echo "================================================"
echo ""

# Configuration
REPO_URL="https://github.com/scttfrdmn/aws-marimo-sagemaker.git"
REPO_DIR=~/aws-marimo-sagemaker
ENV_NAME="marimo-env"

# Step 1: Clone or update the repository
if [ -d "$REPO_DIR" ]; then
    echo "📦 Repository exists, pulling latest changes..."
    cd "$REPO_DIR"
    git pull origin main
else
    echo "📦 Cloning repository from GitHub..."
    git clone "$REPO_URL" "$REPO_DIR"
    cd "$REPO_DIR"
fi

echo "✅ Repository ready at: $REPO_DIR"
echo ""

# Step 2: Run the setup script from the repo
if [ -f "$REPO_DIR/studio-lab-setup.sh" ]; then
    echo "🚀 Running setup script..."
    chmod +x "$REPO_DIR/studio-lab-setup.sh"
    bash "$REPO_DIR/studio-lab-setup.sh"
else
    echo "❌ Setup script not found in repository"
    exit 1
fi

# Step 3: Create update script
echo ""
echo "📝 Creating auto-update script..."
cat > ~/update-marimo.sh << 'EOFUPDATE'
#!/bin/bash
# Auto-update marimo setup from GitHub

REPO_DIR=~/aws-marimo-sagemaker

echo "🔄 Updating aws-marimo-sagemaker from GitHub..."
cd "$REPO_DIR"
git pull origin main

echo ""
echo "✅ Repository updated!"
echo ""
echo "To upgrade marimo:"
echo "  conda activate marimo-env"
echo "  pip install --upgrade marimo"
EOFUPDATE

chmod +x ~/update-marimo.sh
echo "✅ Update script created: ~/update-marimo.sh"

# Step 4: Summary
echo ""
echo "================================================"
echo "  ✅ Bootstrap Complete!"
echo "================================================"
echo ""
echo "Repository cloned to: $REPO_DIR"
echo ""
echo "To start marimo:"
echo "  ~/start-marimo.sh"
echo ""
echo "To try the demos:"
echo "  marimo edit ~/aws-marimo-sagemaker/sagemaker_ml_demo.py"
echo "  marimo edit ~/marimo-demo.py"
echo ""
echo "To update from GitHub:"
echo "  ~/update-marimo.sh"
echo ""
echo "🚀 Ready to go!"
