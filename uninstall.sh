#!/bin/bash
# Uninstall Script for marimo on SageMaker Studio Lab
# This script removes all files and configurations created by the bootstrap

set -e

echo "================================================"
echo "  marimo Uninstall for SageMaker Studio Lab"
echo "================================================"
echo ""
echo "This will remove:"
echo "  • marimo-env conda environment"
echo "  • ~/aws-marimo-sagemaker repository"
echo "  • Helper scripts (start-marimo.sh, upgrade-marimo.sh, update-marimo.sh)"
echo "  • Configuration files (marimo-environment.yml, marimo-requirements.txt)"
echo "  • Demo notebooks (marimo-demo.py)"
echo "  • Auto-activation from ~/.bashrc"
echo ""

# Ask for confirmation
read -p "Are you sure you want to uninstall? (yes/no): " -r
echo
if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
    echo "❌ Uninstall cancelled"
    exit 0
fi

echo ""
echo "🗑️  Starting uninstall process..."
echo ""

# Step 1: Stop any running marimo processes
echo "1️⃣  Stopping marimo processes..."
pkill -f "marimo edit" 2>/dev/null || true
pkill -f "marimo run" 2>/dev/null || true
echo "✅ Processes stopped"

# Step 2: Remove conda environment
echo ""
echo "2️⃣  Removing conda environment 'marimo-env'..."
if conda env list | grep -q "^marimo-env "; then
    # Deactivate if currently active
    if [ "$CONDA_DEFAULT_ENV" = "marimo-env" ]; then
        eval "$(conda shell.bash hook)"
        conda deactivate
    fi
    conda env remove -n marimo-env -y
    echo "✅ Conda environment removed"
else
    echo "⚠️  Conda environment not found (already removed?)"
fi

# Step 3: Remove repository
echo ""
echo "3️⃣  Removing ~/aws-marimo-sagemaker repository..."
if [ -d ~/aws-marimo-sagemaker ]; then
    rm -rf ~/aws-marimo-sagemaker
    echo "✅ Repository removed"
else
    echo "⚠️  Repository not found (already removed?)"
fi

# Step 4: Remove helper scripts
echo ""
echo "4️⃣  Removing helper scripts..."
SCRIPTS=(
    ~/start-marimo.sh
    ~/upgrade-marimo.sh
    ~/update-marimo.sh
)

for script in "${SCRIPTS[@]}"; do
    if [ -f "$script" ]; then
        rm -f "$script"
        echo "   ✅ Removed $(basename $script)"
    fi
done

# Step 5: Remove configuration files
echo ""
echo "5️⃣  Removing configuration files..."
CONFIG_FILES=(
    ~/marimo-environment.yml
    ~/marimo-requirements.txt
)

for file in "${CONFIG_FILES[@]}"; do
    if [ -f "$file" ]; then
        rm -f "$file"
        echo "   ✅ Removed $(basename $file)"
    fi
done

# Step 6: Remove demo notebooks
echo ""
echo "6️⃣  Removing demo notebooks..."
if [ -f ~/marimo-demo.py ]; then
    rm -f ~/marimo-demo.py
    echo "✅ Demo notebook removed"
else
    echo "⚠️  Demo notebook not found (already removed?)"
fi

# Step 7: Remove auto-activation from .bashrc
echo ""
echo "7️⃣  Removing auto-activation from ~/.bashrc..."
if grep -q "# Auto-activate marimo environment" ~/.bashrc 2>/dev/null; then
    # Create a backup
    cp ~/.bashrc ~/.bashrc.marimo-backup

    # Remove the marimo auto-activation block
    sed -i.tmp '/# Auto-activate marimo environment/,/^fi$/d' ~/.bashrc
    rm -f ~/.bashrc.tmp

    echo "✅ Auto-activation removed"
    echo "   Backup saved to ~/.bashrc.marimo-backup"
else
    echo "⚠️  Auto-activation not found in ~/.bashrc"
fi

# Step 8: Summary
echo ""
echo "================================================"
echo "  ✅ Uninstall Complete!"
echo "================================================"
echo ""
echo "All marimo components have been removed."
echo ""
echo "If you want to reinstall later, run:"
echo "  curl -fsSL https://raw.githubusercontent.com/scttfrdmn/aws-marimo-sagemaker/main/bootstrap.sh | bash"
echo ""
echo "Note: Your ~/.bashrc backup is at ~/.bashrc.marimo-backup"
echo ""
