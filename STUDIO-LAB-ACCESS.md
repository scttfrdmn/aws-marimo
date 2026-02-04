# Accessing marimo on SageMaker Studio Lab

After running `~/start-marimo.sh`, you'll see marimo start on port 2718. Here's how to access it properly in Studio Lab.

## 🔗 Access Methods

### Method 1: JupyterLab Proxy UI (Recommended)

1. **Look for the proxy icon** in JupyterLab's left sidebar (it looks like 🔗 or a chain link)
2. **Find port 2718** in the list of running servers
3. **Click on it** to open marimo in a new tab

### Method 2: Manual URL Navigation

If you don't see the proxy UI, manually construct the URL:

1. Copy your current JupyterLab URL (it looks like):
   ```
   https://abc123xyz.studio.us-east-1.sagemaker.aws/studiolab/default/jupyter/lab
   ```

2. Replace everything after the domain with `/studiolab/default/jupyter/proxy/2718/`:
   ```
   https://abc123xyz.studio.us-east-1.sagemaker.aws/studiolab/default/jupyter/proxy/2718/
   ```

3. Navigate to that URL in your browser

## ⚠️ Important Notes

### Why the Terminal URL Doesn't Work

When marimo starts, it shows URLs like:
```
➜  URL: http://0.0.0.0:2718?access_token=...
➜  Network: http://169.254.255.2:2718?access_token=...
```

**These URLs won't work in Studio Lab!** They're internal network addresses. You must use the JupyterLab proxy methods above.

### Port Number

marimo always uses **port 2718** by default. If you need a different port, edit `~/start-marimo.sh` and change:
```bash
marimo edit --host 0.0.0.0 --port 2718
```

## 🔄 Upgrading marimo

marimo will notify you when updates are available. To upgrade:

### Option 1: Quick Upgrade
```bash
conda activate marimo-env
pip install --upgrade marimo
```

### Option 2: Use the Upgrade Script
```bash
~/aws-marimo/upgrade-marimo.sh
```

This will:
- Update the repository from GitHub
- Upgrade marimo to the latest version
- Show version information

## 🚀 Quick Start Commands

```bash
# Start marimo (auto-checks for updates)
~/start-marimo.sh

# Upgrade everything
~/aws-marimo/upgrade-marimo.sh

# Update repository only
~/update-marimo.sh

# Open a specific notebook
conda activate marimo-env
marimo edit ~/marimo-demo.py
marimo edit ~/aws-marimo/sagemaker_ml_demo.py
```

## 🐛 Troubleshooting

### Can't find proxy icon
- Make sure JupyterLab is fully loaded
- Try refreshing the page
- Use Method 2 (manual URL) instead

### marimo won't start
- Check that the conda environment is activated: `conda activate marimo-env`
- Verify marimo is installed: `marimo --version`
- Re-run the setup: `~/aws-marimo/studio-lab-setup.sh`

### Port already in use
- Stop any running marimo instances
- Kill the process: `pkill -f marimo`
- Then restart: `~/start-marimo.sh`

### Session disconnected after idle time
- Studio Lab sessions timeout after inactivity
- Your work is saved in the persistent storage
- Just run `~/start-marimo.sh` again after restarting your runtime

## 📚 Next Steps

- Try the quick demo: `marimo edit ~/marimo-demo.py`
- Explore the ML demo: `marimo edit ~/aws-marimo/sagemaker_ml_demo.py`
- Read the docs: https://docs.marimo.io
- Check out examples: https://github.com/marimo-team/marimo/tree/main/examples
