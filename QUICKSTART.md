# Quick Start: marimo on SageMaker in 5 Minutes

This guide shows the **easiest** way to get marimo running on Amazon SageMaker Studio Lab (free!) or SageMaker Studio.

## Option 1: SageMaker Studio Lab (100% Free, No AWS Account Required!)

Perfect for learning and experimentation without any AWS costs.

### Step 1: Get Studio Lab Access
1. Go to https://studiolab.sagemaker.aws
2. Request a free account (approval usually within 1-2 days)
3. Sign in and start your runtime

### Step 2: Install marimo (30 seconds)
Open a terminal in Studio Lab and run:

```bash
pip install marimo jupyter-server-proxy
```

### Step 3: Start marimo
```bash
marimo edit
```

### Step 4: Access marimo UI
Click the URL shown in the terminal output, or navigate to:
```
/proxy/2718/
```

**That's it!** You now have marimo running on Studio Lab for free. 🎉

### Quick Test
Try this in a new notebook cell:

```python
import marimo as mo

slider = mo.ui.slider(0, 100, value=50)
mo.md(f"Value: {slider.value}")
```

Move the slider and watch the value update automatically!

## Option 2: SageMaker Studio (For Production Use)

If you already have SageMaker Studio set up, getting marimo is just as easy.

### Super Quick Method (Manual Installation)

1. **Open Studio** - Launch your SageMaker Studio instance
2. **Open Terminal** - Click File > New > Terminal
3. **Install marimo**:
```bash
pip install marimo jupyter-server-proxy
```

4. **Start marimo**:
```bash
marimo edit --host 0.0.0.0 --port 8888
```

5. **Access the UI** at:
```
/jupyter/default/proxy/8888/
```

### Automated Method (Lifecycle Configuration)

For persistent installation across sessions, use a lifecycle configuration:

#### Create Lifecycle Config Script

Save this as `install-marimo.sh`:

```bash
#!/bin/bash
set -e

pip install marimo jupyter-server-proxy
jupyter serverextension enable --py jupyter_server_proxy --sys-prefix

echo "marimo installed successfully!"
```

#### Deploy via AWS Console

1. Go to SageMaker Console > Domains
2. Click your domain > Studio settings
3. Select "Lifecycle configurations"
4. Create new configuration:
   - Name: `marimo-install`
   - Type: `JupyterServer`
   - Upload: `install-marimo.sh`
5. Attach to your user profile

#### Deploy via AWS CLI

```bash
# Create lifecycle config
aws sagemaker create-studio-lifecycle-config \
    --studio-lifecycle-config-name marimo-setup \
    --studio-lifecycle-config-app-type JupyterServer \
    --studio-lifecycle-config-content file://install-marimo.sh

# Update user profile to use it
aws sagemaker update-user-profile \
    --domain-id <your-domain-id> \
    --user-profile-name <your-username> \
    --user-settings JupyterServerAppSettings={
        LifecycleConfigArns=["arn:aws:sagemaker:region:account:studio-lifecycle-config/marimo-setup"]
    }
```

Now marimo installs automatically every time JupyterServer starts!

## Quick Tips

### Running marimo notebooks

```bash
# Create a new notebook
marimo edit my_notebook.py

# Run existing notebook
marimo run my_notebook.py

# Execute as script
python my_notebook.py
```

### Converting Jupyter notebooks

Already have Jupyter notebooks? Convert them:

```bash
marimo convert analysis.ipynb -o analysis.py
```

### Helper script for easy starting

Create this helper script (`~/start-marimo.sh`):

```bash
#!/bin/bash
PORT=${1:-8888}
marimo edit --host 0.0.0.0 --port $PORT
```

Make it executable:
```bash
chmod +x ~/start-marimo.sh
```

Then start marimo anytime with:
```bash
~/start-marimo.sh
```

## Sample Notebook

Try this sample to see marimo's reactive magic:

```python
import marimo

app = marimo.App()

@app.cell
def __():
    import marimo as mo
    return mo,

@app.cell
def __(mo):
    mo.md("# My First marimo Notebook on SageMaker!")
    return

@app.cell
def __(mo):
    # Create an interactive slider
    x = mo.ui.slider(start=1, stop=10, value=5, label="x")
    x
    return x,

@app.cell
def __(mo, x):
    # This automatically updates when slider changes!
    y = x.value ** 2
    mo.md(f"**x² = {y}**")
    return y,

@app.cell
def __(mo, x, y):
    # Plot also updates automatically
    import plotly.graph_objects as go

    fig = go.Figure()
    fig.add_trace(go.Scatter(
        x=list(range(1, 11)),
        y=[i**2 for i in range(1, 11)],
        mode='lines+markers',
        name='y = x²'
    ))

    # Highlight current point
    fig.add_trace(go.Scatter(
        x=[x.value],
        y=[y],
        mode='markers',
        marker=dict(size=15, color='red'),
        name='Current'
    ))

    mo.ui.plotly(fig)
    return fig, go

if __name__ == "__main__":
    app.run()
```

Save this as `demo.py` and run:
```bash
marimo edit demo.py
```

Move the slider and watch everything update instantly!

## Troubleshooting

### "Can't access marimo UI"

**Problem**: marimo server is running but can't access the UI

**Solution**: Make sure you're using the correct proxy URL:
- Studio Lab: `/proxy/2718/`
- Studio: `/jupyter/default/proxy/8888/`

### "jupyter-server-proxy not found"

**Problem**: After installing, proxy doesn't work

**Solution**:
```bash
jupyter serverextension enable --py jupyter_server_proxy --sys-prefix
jupyter serverextension list  # Verify it's enabled
```

### "Port already in use"

**Problem**: marimo won't start because port is busy

**Solution**: Use a different port:
```bash
marimo edit --host 0.0.0.0 --port 8889
```

Then access at `/proxy/8889/`

## Studio Lab vs Studio: Which to Use?

| Feature | Studio Lab (Free) | Studio (Paid) |
|---------|-------------------|---------------|
| Cost | **100% Free** | Pay per use (~$1-2/hour) |
| AWS Account | Not required | Required |
| Setup Time | 5 minutes | 10-30 minutes (infra setup) |
| Compute | CPU only, 4-16 GB RAM | CPU + GPU, scalable |
| Storage | 15 GB persistent | Unlimited (S3) |
| Session Time | 4-12 hours | Unlimited |
| Best For | Learning, demos, small projects | Production, team collaboration |

**Recommendation**: Start with Studio Lab to learn marimo, then move to Studio for production workloads.

## What Makes This Easy?

1. **No Infrastructure Setup**: Both Studio and Studio Lab handle the environment
2. **Just pip install**: marimo is a regular Python package
3. **Built-in Proxy**: jupyter-server-proxy makes web UI access seamless
4. **No Configuration Needed**: Works out of the box
5. **Free Option Available**: Studio Lab requires no AWS account or credit card

## Next Steps

Now that marimo is running:

1. ✅ Try the sample notebook above
2. ✅ Convert an existing Jupyter notebook: `marimo convert notebook.ipynb`
3. ✅ Build an interactive dashboard with real data
4. ✅ Deploy as a web app: `marimo run my_notebook.py`
5. ✅ Read the [full blog post](blog-post.md) for advanced integration with SageMaker

## Resources

- **marimo docs**: https://docs.marimo.io
- **marimo examples**: https://marimo.io/examples
- **Studio Lab docs**: https://studiolab.sagemaker.aws/
- **SageMaker Studio docs**: https://docs.aws.amazon.com/sagemaker/latest/dg/studio.html

---

**Questions or issues?** Open an issue in this repo or check the marimo Discord community!

Happy reactive coding! 🚀
