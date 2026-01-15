# One-Command Bootstrap from GitHub

The easiest way to get marimo running on SageMaker Studio Lab with automatic updates!

## TL;DR - Single Command Setup

```bash
curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/aws-marimo/main/bootstrap.sh | bash
```

That's it! Everything else is automatic.

## What This Does

The bootstrap script:

1. **📦 Clones this repository** to `~/aws-marimo`
2. **🔧 Runs the setup script** automatically
3. **🔄 Creates update mechanism** for pulling latest changes
4. **✅ Configures everything** (conda env, scripts, demo)

## Why This Approach?

### Traditional Setup
```bash
# Manual steps
pip install marimo jupyter-server-proxy  # Session only
pip install pandas numpy boto3 ...       # Reinstall each time
marimo edit                               # Every restart
```

### GitHub Bootstrap
```bash
# One time
curl -fsSL https://[...]/bootstrap.sh | bash

# Future sessions
~/start-marimo.sh  # Auto-checks for updates!
```

## Automatic Updates

Every time you run `~/start-marimo.sh`, it:
- ✅ Checks GitHub for updates
- ✅ Pulls latest demos and scripts
- ✅ Keeps everything in sync
- ✅ Takes only 2-3 seconds

No manual git pull needed!

## What Gets Installed

From the repository:
- `sagemaker_ml_demo.py` - Full ML workflow demo
- `studio-lab-setup.sh` - Setup script
- `bootstrap.sh` - Bootstrap script
- All documentation (README, QUICKSTART, etc.)

In your environment:
- marimo + jupyter-server-proxy
- pandas, numpy, boto3, plotly, scikit-learn
- Persistent conda environment
- Helper scripts in `~/`

## File Structure After Bootstrap

```
~/aws-marimo/              # Repository clone
├── sagemaker_ml_demo.py   # Full ML demo
├── bootstrap.sh           # This bootstrap script
├── studio-lab-setup.sh    # Setup script
├── README.md              # Main docs
├── QUICKSTART.md          # Quick start guide
└── [all other files]

~/                         # Helper scripts
├── start-marimo.sh        # Auto-updating start script
├── update-marimo.sh       # Manual update script
├── marimo-demo.py         # Simple demo notebook
└── marimo-*.txt/yml       # Config files

~/conda/envs/marimo-env/   # Persistent environment
└── [all packages]
```

## Usage After Bootstrap

### Daily Start (with auto-update)
```bash
~/start-marimo.sh
```

### Manual Update
```bash
~/update-marimo.sh
```

### Try the Demos
```bash
# Simple demo
marimo edit ~/marimo-demo.py

# Full ML workflow
marimo edit ~/aws-marimo/sagemaker_ml_demo.py
```

## Advanced: Update Strategy

The `start-marimo.sh` script uses smart update logic:

```bash
# 1. Silent fetch from GitHub
git fetch origin main --quiet

# 2. Compare commits
LOCAL=$(git rev-parse HEAD)
REMOTE=$(git rev-parse origin/main)

# 3. Pull only if different
if [ "$LOCAL" != "$REMOTE" ]; then
    git pull origin main
fi
```

**Result**: Zero manual git commands, always up-to-date!

## Customization: Fork and Personalize

1. **Fork this repository** on GitHub
2. **Customize the files**:
   - Add your own demos to `my-custom-demo.py`
   - Modify setup script for your packages
   - Update demos with your use cases

3. **Update bootstrap URL** in your fork:
```bash
# Change YOUR_USERNAME to your GitHub username
REPO_URL="https://github.com/YOUR_USERNAME/aws-marimo.git"
```

4. **Share with your team**:
```bash
curl -fsSL https://raw.githubusercontent.com/YOUR_TEAM/aws-marimo/main/bootstrap.sh | bash
```

Now everyone gets your custom setup automatically!

## Comparison: Manual vs Bootstrap

| Feature | Manual Install | GitHub Bootstrap |
|---------|---------------|------------------|
| Initial setup | Multiple commands | One curl command |
| Updates | Manual git pull | Automatic on start |
| Demos included | No | Yes |
| Team sharing | Share commands | Share one URL |
| Customization | Copy files manually | Fork and customize |
| Documentation | Search online | Included in repo |

## Security Note

The bootstrap script:
- ✅ Only installs from official GitHub repo
- ✅ Uses HTTPS (not HTTP)
- ✅ Source code is visible (review before running)
- ✅ No sudo/admin access needed
- ✅ Runs in user space only

**Best practice**: Review the script first:
```bash
curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/aws-marimo/main/bootstrap.sh
```

Then run it if satisfied.

## Troubleshooting

### Bootstrap fails with git error
```bash
# Check git is available
git --version

# If not, install it (Studio Lab should have it)
conda install git
```

### Repository already exists
Bootstrap automatically updates:
```bash
# It will do:
cd ~/aws-marimo
git pull origin main
```

### Want to start fresh
```bash
# Remove and re-bootstrap
rm -rf ~/aws-marimo
curl -fsSL https://[...]/bootstrap.sh | bash
```

### Updates not working
```bash
# Manual update
cd ~/aws-marimo
git pull origin main
```

## For Repository Maintainers

### Update Flow
1. **Push changes** to GitHub:
```bash
git add .
git commit -m "Add new demo"
git push origin main
```

2. **Users auto-update** next time they run:
```bash
~/start-marimo.sh
```

### Testing Bootstrap
```bash
# Test locally first
bash bootstrap.sh

# Then commit and push
git add bootstrap.sh
git commit -m "Update bootstrap"
git push origin main
```

## Alternative: Git Clone Approach

If you prefer manual control:

```bash
# Clone repository
git clone https://github.com/YOUR_USERNAME/aws-marimo.git
cd aws-marimo

# Run setup
bash studio-lab-setup.sh

# Manual updates
git pull origin main
```

## Why GitHub Integration?

1. **Single source of truth**: All demos, scripts, docs in one place
2. **Version control**: Track changes, rollback if needed
3. **Collaboration**: Team can contribute demos/fixes
4. **Distribution**: Share one URL instead of multiple files
5. **Updates**: Push once, everyone gets it automatically

## Next Steps

After bootstrap:

1. ✅ Run `~/start-marimo.sh`
2. ✅ Try `marimo edit ~/aws-marimo/sagemaker_ml_demo.py`
3. ✅ Explore the repository files
4. ✅ Star the repo on GitHub! ⭐
5. ✅ Consider forking for your custom setup

## Contributing

Found a bug or have an improvement?

1. Fork the repository
2. Make your changes
3. Test with bootstrap
4. Submit a pull request

Everyone using the bootstrap will get your improvements!

---

**One command to rule them all!** 🚀

```bash
curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/aws-marimo/main/bootstrap.sh | bash
```
