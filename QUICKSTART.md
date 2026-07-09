# Quick Start: marimo on SageMaker Studio

Get marimo running interactively on Amazon SageMaker Studio in a few minutes.

> **Platforms:** full **SageMaker Studio** (JupyterLab) and **SageMaker Unified
> Studio**. Studio Lab (EOL 2026-07-30) and Studio Classic (EOL) are not
> supported — see the [README](README.md#️-studio-lab-is-no-longer-supported).

## Why the extra proxy?

marimo's UI will load, but notebooks stay stuck "connecting" with blank cells.
SageMaker's JupyterLab proxy strips marimo's session cookie, so marimo rejects
its WebSocket handshake with HTTP 403. [ws-sse-proxy](https://github.com/scttfrdmn/ws-sse-proxy)
works around it by keeping the WebSocket on localhost. Full detail:
[WEBSOCKET-STATUS.md](WEBSOCKET-STATUS.md).

## Step 1: Open a terminal in your JupyterLab space

In SageMaker Studio, launch a **JupyterLab** space and open a terminal
(File → New → Terminal).

## Step 2: Install marimo and the shim

```bash
pip install marimo ws-sse-proxy
```

## Step 3: Start marimo behind the shim

```bash
curl -fsSL https://raw.githubusercontent.com/scttfrdmn/aws-marimo-sagemaker/main/start-marimo.sh -o start-marimo.sh
bash start-marimo.sh
```

This launches marimo on `127.0.0.1:2718` and ws-sse-proxy on `2719`.

## Step 4: Access the UI

Open the **proxy** port (`2719`), not marimo's port. Copy your JupyterLab URL
and replace everything after the host:

```
https://<domain>.studio.<region>.sagemaker.aws/jupyterlab/default/proxy/2719/
```

<!-- TODO(verify): confirm the exact proxy base path on standalone SageMaker
     Studio vs SageMaker Unified Studio (they differ). See issue #8. -->

The marimo "Create a new notebook" screen appears, and cells now execute.

### Quick test

```python
import marimo as mo

slider = mo.ui.slider(0, 100, value=50)
mo.md(f"Value: {slider.value}")
```

Move the slider — the value updates automatically.

## Persistent install (optional)

Instead of pip-installing each session, attach a lifecycle configuration to
your JupyterLab app so marimo + ws-sse-proxy are always present. See
`lifecycle-config/install-marimo.sh`:

```bash
LCC_CONTENT=$(base64 < lifecycle-config/install-marimo.sh)
aws sagemaker create-studio-lifecycle-config \
    --studio-lifecycle-config-name marimo-setup \
    --studio-lifecycle-config-app-type JupyterLab \
    --studio-lifecycle-config-content "$LCC_CONTENT"
```

Then attach it to your domain / user profile / space and select it when
launching the space.
<!-- TODO(verify): confirm LCC attach + startup on a live space (issue #8). -->

## Quick tips

```bash
# Create / edit a notebook
marimo edit my_notebook.py

# Run as an app
marimo run my_notebook.py

# Execute as a plain script
python my_notebook.py

# Convert an existing Jupyter notebook
marimo convert analysis.ipynb -o analysis.py
```

## Troubleshooting

Run `bash diagnose-proxy.sh` for an automated check, or:

### Can't access the UI
Make sure you're using the **proxy** port: `/jupyterlab/default/proxy/2719/`
(port `2719`), not marimo's `2718`.

### Notebook loads but cells won't run
This is the WebSocket/403 issue. Confirm you started marimo via
`start-marimo.sh` (which puts ws-sse-proxy in front) and that you're on the
`2719` path, not `2718`. See [WEBSOCKET-STATUS.md](WEBSOCKET-STATUS.md).

### Port already in use
Override the ports:
```bash
MARIMO_PORT=2728 PROXY_PORT=2729 bash start-marimo.sh
```

### Session disconnected after idle time
SageMaker spaces idle out; your files persist on the space's EBS volume. Just
re-run `bash start-marimo.sh` after the space restarts.

## Next steps

1. ✅ Try the sample above
2. ✅ Explore [sagemaker_ml_demo.py](sagemaker_ml_demo.py)
3. ✅ Read the [blog post](blog-post.md)
4. ✅ Read [docs.marimo.io](https://docs.marimo.io)

## Resources

- marimo docs: https://docs.marimo.io
- SageMaker Studio docs: https://docs.aws.amazon.com/sagemaker/latest/dg/studio-updated.html
- ws-sse-proxy: https://github.com/scttfrdmn/ws-sse-proxy
