#!/bin/bash
# SageMaker Studio Lab - marimo Setup Script
# This script combines conda environment + smart installation checking
# Run once to set everything up, then use the start script for future sessions

set -e  # Exit on error

echo "================================================"
echo "  marimo Setup for SageMaker Studio Lab"
echo "================================================"
echo ""

# Configuration
ENV_NAME="marimo-env"
CONDA_ENV_FILE=~/marimo-environment.yml
REQUIREMENTS_FILE=~/marimo-requirements.txt

# Step 1: Create environment.yml if it doesn't exist
if [ ! -f "$CONDA_ENV_FILE" ]; then
    echo "📝 Creating conda environment configuration..."
    cat > "$CONDA_ENV_FILE" << 'EOF'
name: marimo-env
channels:
  - conda-forge
  - defaults
dependencies:
  - python=3.9
  - pip
  - pip:
    - marimo
    - jupyter-server-proxy
    - pandas
    - numpy
    - boto3
    - plotly
    - scikit-learn
EOF
    echo "✅ Environment file created: $CONDA_ENV_FILE"
else
    echo "✅ Environment file already exists: $CONDA_ENV_FILE"
fi

# Step 2: Create requirements.txt backup (for pip-only installs)
echo ""
echo "📝 Creating requirements.txt backup..."
cat > "$REQUIREMENTS_FILE" << 'EOF'
marimo>=0.17.6
jupyter-server-proxy>=4.0.0
pandas>=2.0.0
numpy>=1.24.0
boto3>=1.26.0
plotly>=5.14.0
scikit-learn>=1.3.0
EOF
echo "✅ Requirements file created: $REQUIREMENTS_FILE"

# Step 3: Check if conda environment exists
echo ""
if conda env list | grep -q "^${ENV_NAME} "; then
    echo "✅ Conda environment '$ENV_NAME' already exists"
    ENV_EXISTS=true
else
    echo "📦 Creating conda environment '$ENV_NAME'..."
    conda env create -f "$CONDA_ENV_FILE"
    ENV_EXISTS=true
    echo "✅ Conda environment created!"
fi

# Step 4: Activate environment and verify/install packages
echo ""
echo "🔧 Activating environment and checking packages..."

# Source conda to make activation work in script
eval "$(conda shell.bash hook)"
conda activate "$ENV_NAME"

# Check if marimo is installed
if ! command -v marimo &> /dev/null; then
    echo "📦 Installing packages (this may take a minute)..."
    pip install -r "$REQUIREMENTS_FILE"
    echo "✅ Packages installed!"
else
    echo "✅ marimo is already installed"
fi

# Enable jupyter-server-proxy extension
echo ""
echo "🔧 Enabling jupyter-server-proxy extension..."
jupyter serverextension enable --py jupyter_server_proxy --sys-prefix 2>/dev/null || true
echo "✅ Extension enabled!"

# Step 5: Create start script with auto-update
echo ""
echo "📝 Creating start script with auto-update..."
cat > ~/start-marimo.sh << 'EOFSTART'
#!/bin/bash
# Quick start script for marimo
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
        echo "✅ Repository up to date"
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

# Check for marimo updates
CURRENT_VERSION=$(marimo --version 2>&1)
echo "📋 Current marimo version: $CURRENT_VERSION"

# Quick check for updates (non-blocking)
LATEST_VERSION=$(pip index versions marimo 2>/dev/null | grep "marimo (" | head -1 | sed 's/marimo (\(.*\))/\1/' || echo "")
if [ -n "$LATEST_VERSION" ] && [ "$CURRENT_VERSION" != "$LATEST_VERSION" ]; then
    echo "⬆️  New version available: $LATEST_VERSION"
    echo "   To upgrade: pip install --upgrade marimo"
    echo ""
fi

echo ""
echo "================================================"
echo "  🚀 Starting marimo on SageMaker Studio Lab"
echo "================================================"
echo ""
echo "📍 Access marimo in your browser:"
echo ""
echo "Copy your JupyterLab URL and modify the path:"
echo "  FROM: /studiolab/default/jupyter/lab"
echo "    TO: /studiolab/default/jupyter/proxy/2718/"
echo ""
echo "Example:"
echo "  https://xxxxx.studio.us-east-2.sagemaker.aws/studiolab/default/jupyter/proxy/2718/"
echo ""
echo "The marimo interface will open with 'Create a new notebook' screen."
echo ""
echo "================================================"
echo ""

# Start marimo
# Use default port 2718 with Studio Lab-compatible flags
# --no-token: Jupyter already handles authentication
# --headless: Proxy-friendly mode for Studio Lab
marimo edit --host 0.0.0.0 --port 2718 --no-token --headless
EOFSTART

chmod +x ~/start-marimo.sh
echo "✅ Start script created: ~/start-marimo.sh"

# Create upgrade helper script
echo ""
echo "📝 Creating upgrade helper script..."
cat > ~/upgrade-marimo.sh << 'EOFUPGRADE'
#!/bin/bash
# Upgrade marimo and sync repository

echo "================================================"
echo "  marimo Upgrade Script"
echo "================================================"
echo ""

# Activate conda environment
eval "$(conda shell.bash hook)"
conda activate marimo-env

# Update repository
if [ -d ~/aws-marimo ]; then
    echo "📦 Updating repository from GitHub..."
    cd ~/aws-marimo
    git pull origin main
    cd - > /dev/null
    echo "✅ Repository updated"
    echo ""
fi

# Upgrade marimo
echo "⬆️  Upgrading marimo..."
CURRENT=$(marimo --version 2>&1)
echo "   Current: $CURRENT"

pip install --upgrade marimo

NEW=$(marimo --version 2>&1)
echo "   New: $NEW"
echo ""
echo "✅ Upgrade complete!"
echo ""
EOFUPGRADE

chmod +x ~/upgrade-marimo.sh
echo "✅ Upgrade script created: ~/upgrade-marimo.sh"

# Step 6: Create auto-activate for bashrc
echo ""
echo "🔧 Setting up auto-activation..."
if ! grep -q "conda activate marimo-env" ~/.bashrc; then
    cat >> ~/.bashrc << 'EOFBASH'

# Auto-activate marimo environment
if [ -z "$CONDA_DEFAULT_ENV" ] || [ "$CONDA_DEFAULT_ENV" != "marimo-env" ]; then
    eval "$(conda shell.bash hook)"
    conda activate marimo-env 2>/dev/null
fi
EOFBASH
    echo "✅ Auto-activation added to ~/.bashrc"
else
    echo "✅ Auto-activation already configured"
fi

# Step 7: Create demo notebook
echo ""
echo "📝 Creating demo notebook..."
cat > ~/marimo-demo.py << 'EOFDEMO'
"""
marimo Quick Demo - SageMaker Studio Lab
Try this to see reactive programming in action!
"""

import marimo

__generated_with = "0.17.6"
app = marimo.App(width="medium")


@app.cell
def __():
    import marimo as mo
    return mo,


@app.cell
def __(mo):
    mo.md(
        """
        # Welcome to marimo on Studio Lab! 🚀

        This notebook demonstrates reactive execution. Try moving the slider below!
        """
    )
    return


@app.cell
def __(mo):
    # Create an interactive slider
    slider = mo.ui.slider(1, 100, value=25, label="Select a number")
    slider
    return slider,


@app.cell
def __(mo, slider):
    # This cell automatically updates when slider changes!
    squared = slider.value ** 2
    cubed = slider.value ** 3

    mo.md(
        f"""
        ## Reactive Calculations

        - **Value**: {slider.value}
        - **Squared**: {squared}
        - **Cubed**: {cubed}

        *Move the slider and watch these update automatically!*
        """
    )
    return cubed, squared


@app.cell
def __(mo, slider):
    # Interactive visualization
    import plotly.graph_objects as go

    x_values = list(range(1, 101))
    y_squared = [x**2 for x in x_values]
    y_cubed = [x**3 for x in x_values]

    fig = go.Figure()

    fig.add_trace(go.Scatter(
        x=x_values,
        y=y_squared,
        mode='lines',
        name='x²',
        line=dict(color='blue')
    ))

    fig.add_trace(go.Scatter(
        x=x_values,
        y=y_cubed,
        mode='lines',
        name='x³',
        line=dict(color='red')
    ))

    # Highlight current value
    fig.add_trace(go.Scatter(
        x=[slider.value],
        y=[slider.value**2],
        mode='markers',
        name='Current x²',
        marker=dict(size=12, color='blue')
    ))

    fig.add_trace(go.Scatter(
        x=[slider.value],
        y=[slider.value**3],
        mode='markers',
        name='Current x³',
        marker=dict(size=12, color='red')
    ))

    fig.update_layout(
        title='Polynomial Functions',
        xaxis_title='x',
        yaxis_title='y',
        hovermode='closest'
    )

    mo.ui.plotly(fig)
    return fig, go, x_values, y_cubed, y_squared


@app.cell
def __(mo):
    mo.md(
        """
        ## What's Happening?

        Unlike traditional notebooks:
        - ✅ No manual re-running of cells
        - ✅ No hidden state or out-of-order execution
        - ✅ Changes propagate automatically
        - ✅ Everything stays synchronized

        ## Try This:
        1. Move the slider
        2. Watch calculations and plots update instantly
        3. Notice you didn't click "Run" on any cell!

        ## Next Steps:
        - Clone the aws-marimo repo for more examples
        - Try the full ML demo: `marimo edit sagemaker_ml_demo.py`
        - Read the docs: https://docs.marimo.io
        """
    )
    return


if __name__ == "__main__":
    app.run()
EOFDEMO
echo "✅ Demo notebook created: ~/marimo-demo.py"

# Step 8: Summary
echo ""
echo "================================================"
echo "  ✅ Setup Complete!"
echo "================================================"
echo ""
echo "To start marimo in future sessions, just run:"
echo "  ~/start-marimo.sh"
echo ""
echo "Or start manually with:"
echo "  conda activate marimo-env"
echo "  marimo edit"
echo ""
echo "Try the demo:"
echo "  marimo edit ~/marimo-demo.py"
echo ""
echo "Configuration files created:"
echo "  - $CONDA_ENV_FILE"
echo "  - $REQUIREMENTS_FILE"
echo "  - ~/start-marimo.sh"
echo "  - ~/upgrade-marimo.sh"
echo "  - ~/marimo-demo.py"
echo ""
echo "The marimo-env environment will auto-activate in new terminal sessions."
echo ""
echo "To upgrade marimo in the future:"
echo "  ~/upgrade-marimo.sh"
echo ""
echo "🚀 Happy coding!"
