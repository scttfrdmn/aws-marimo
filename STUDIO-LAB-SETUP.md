# Automated Setup for SageMaker Studio Lab

This guide provides an automated setup script that combines conda environments with smart installation checking for persistent marimo installation on Studio Lab.

## Quick Start (3 Commands)

```bash
# 1. Download the setup script
curl -O https://raw.githubusercontent.com/YOUR_USERNAME/aws-marimo/main/studio-lab-setup.sh

# 2. Make it executable
chmod +x studio-lab-setup.sh

# 3. Run it (one-time setup)
./studio-lab-setup.sh
```

That's it! The script handles everything automatically.

## What the Setup Script Does

### ✅ Creates Persistent Conda Environment
- Creates `marimo-env` with Python 3.9
- Installs marimo and all dependencies
- Environment persists across Studio Lab sessions (uses your 15GB storage)

### ✅ Configures Auto-Activation
- Adds environment activation to `~/.bashrc`
- marimo-env automatically activates when you open new terminals

### ✅ Creates Helper Scripts
- **`~/start-marimo.sh`**: Quick start command for future sessions
- Checks if packages are installed before starting

### ✅ Generates Demo Notebook
- **`~/marimo-demo.py`**: Interactive demo showing reactive execution
- Includes sliders, calculations, and plotly visualizations

### ✅ Creates Backup Files
- `~/marimo-environment.yml`: Conda environment specification
- `~/marimo-requirements.txt`: Pip requirements (backup method)

## Daily Usage (After Setup)

Every time you start a new Studio Lab session, just run:

```bash
~/start-marimo.sh
```

Or manually:
```bash
conda activate marimo-env
marimo edit
```

The environment auto-activates, so often you can just type:
```bash
marimo edit
```

## Try the Demo

```bash
marimo edit ~/marimo-demo.py
```

Access at: `/proxy/2718/` or click the URL shown in terminal

## File Locations

All configuration files are stored in your persistent home directory:

| File | Purpose | Location |
|------|---------|----------|
| Setup script | Initial installation | `~/studio-lab-setup.sh` |
| Start script | Quick start command | `~/start-marimo.sh` |
| Conda env | Environment definition | `~/marimo-environment.yml` |
| Requirements | Pip packages (backup) | `~/marimo-requirements.txt` |
| Demo notebook | Sample marimo notebook | `~/marimo-demo.py` |

## How It Works (Both Techniques Combined)

### Technique 1: Conda Environment (Primary)
- **Persistent**: Environment stored in `~/conda/envs/marimo-env`
- **Survives restarts**: Uses Studio Lab's 15GB persistent storage
- **Version pinned**: Consistent package versions across sessions

### Technique 2: Smart Check-and-Install (Fallback)
- **Validates installation**: Checks if marimo is available before starting
- **Auto-repairs**: Reinstalls if packages are missing
- **Requirements file**: Quick reinstall with `pip install -r ~/marimo-requirements.txt`

## Troubleshooting

### "conda: command not found"
Studio Lab has conda pre-installed. If you see this, restart your terminal:
```bash
source ~/.bashrc
```

### marimo not found after setup
Activate the environment manually:
```bash
conda activate marimo-env
marimo edit
```

### Packages missing or errors
Reinstall packages:
```bash
conda activate marimo-env
pip install -r ~/marimo-requirements.txt
```

### Start from scratch
Remove environment and run setup again:
```bash
conda env remove -n marimo-env
./studio-lab-setup.sh
```

## Upgrading marimo

To upgrade to the latest version:
```bash
conda activate marimo-env
pip install --upgrade marimo
```

Or update all packages:
```bash
conda activate marimo-env
pip install --upgrade -r ~/marimo-requirements.txt
```

## Storage Notes

Studio Lab provides **15GB persistent storage**:
- Conda environment: ~500MB - 1GB
- Packages: ~200-300MB
- Your notebooks: minimal (`.py` files are tiny)

**You'll have plenty of space for data and experiments!**

## Comparison: Manual vs Automated Setup

| Aspect | Manual Install | Automated Setup |
|--------|---------------|-----------------|
| Initial setup | 2 commands | 3 commands |
| Persistence | Session only | Permanent |
| Future sessions | Reinstall each time | One command start |
| Time per restart | ~30 seconds | ~2 seconds |
| Configuration | Manual each time | Automatic |

## Advanced: Customizing the Environment

Edit `~/marimo-environment.yml` to add more packages:

```yaml
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
    # Add your packages here:
    - tensorflow
    - pytorch
    - transformers
```

Then recreate the environment:
```bash
conda env remove -n marimo-env
conda env create -f ~/marimo-environment.yml
```

## Why This Approach?

**Combines best of both worlds:**

1. **Conda**: Persistent environment that survives restarts
2. **Check script**: Safety net that validates installation
3. **Auto-activation**: Zero friction—just works
4. **Backup files**: Easy to recreate or customize

**Studio Lab Friendly:**
- Uses persistent storage (not temporary)
- Lightweight (~1GB total)
- No lifecycle config needed (not supported in Studio Lab)
- Works within Studio Lab's security model

## Run the Full ML Demo

After setup, try the complete SageMaker ML demo:

```bash
# Clone the repo (if not already done)
cd ~
git clone https://github.com/YOUR_USERNAME/aws-marimo.git
cd aws-marimo

# Run the demo
marimo edit sagemaker_ml_demo.py
```

## Next Steps

1. ✅ Run `~/start-marimo.sh` in your next Studio Lab session
2. ✅ Try the demo: `marimo edit ~/marimo-demo.py`
3. ✅ Create your own reactive notebooks
4. ✅ Explore marimo docs: https://docs.marimo.io

## Questions?

- **marimo docs**: https://docs.marimo.io
- **Studio Lab docs**: https://studiolab.sagemaker.aws/
- **This repo**: Check README.md and QUICKSTART.md

---

**Happy reactive coding on Studio Lab!** 🚀
