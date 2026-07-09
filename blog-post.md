<!--
DRAFT — for publication on an AWS channel.
TODO(verify) markers flag every claim that needs confirmation on a live
SageMaker Studio space before publishing. See issue #8:
https://github.com/scttfrdmn/aws-marimo-sagemaker/issues/8
-->

# Running marimo reactive notebooks on Amazon SageMaker Studio

## Introduction

For over a decade, Jupyter notebooks have been the default tool for data
scientists and ML practitioners. But anyone who has run them in earnest knows
the pain points: out-of-order execution creating hidden-state bugs, merge
conflicts from JSON storage, and the "works on my machine" problem when a
notebook won't reproduce.

[marimo](https://marimo.io) is an open-source reactive notebook that rethinks
this. Cells form a dependency graph and re-run automatically, like a
spreadsheet; notebooks are stored as pure Python (`.py`) files, so they're
Git-friendly and runnable as scripts; and there's no hidden state.

This post shows how to run marimo on **Amazon SageMaker Studio** — including the
one non-obvious hurdle you'll hit (interactive notebooks won't connect) and the
small, transparent workaround that fixes it.

> **Platform note.** This targets the current **SageMaker Studio** (the
> JupyterLab experience) and **SageMaker Unified Studio**. SageMaker Studio Lab
> is [closing to new customers on 2026-07-30](https://docs.aws.amazon.com/sagemaker/latest/dg/studio-lab-availability-change.html),
> and Studio Classic is end-of-life, so neither is covered here.

## What makes marimo different?

**Reactive execution.** Change a cell and marimo re-runs exactly the cells that
depend on it, in the right order:

```python
import marimo as mo

slider = mo.ui.slider(0, 100, value=50)
result = expensive_computation(slider.value)  # auto-recomputes
mo.md(f"Result: {result}")                     # auto-updates
```

**Stored as pure Python.** Clean Git diffs, no merge conflicts from execution
counts or embedded outputs, and the same file runs as a script (`python
notebook.py`), imports as a module, and deploys as an app (`marimo run
notebook.py`).

**No hidden state.** Restart-and-run-all is the *only* state, so notebooks
reproduce.

**Built-in interactivity** with no callbacks — `mo.ui.slider`, `mo.ui.table`,
`mo.ui.plotly`, and more.

> marimo is a **Python-only** platform (no R/Julia kernels). For multi-language
> work, keep Jupyter around — the two coexist happily in the same space.

## Why marimo on SageMaker Studio?

- **Managed infrastructure** — no servers or Jupyter installs to babysit.
- **Scalable compute** — CPU/GPU instances, on demand, per space.
- **Native AWS access** — the space's execution role means `boto3` just works
  against SageMaker training jobs, endpoints, S3, and more.
- **Reproducible + Git-friendly** — marimo's `.py` format fits MLOps.

## The hurdle: notebooks won't connect

Here's the part that trips everyone up, and why a plain `pip install marimo`
isn't enough on SageMaker.

Install marimo, start it, and open it through the JupyterLab proxy:

```bash
pip install marimo jupyter-server-proxy
marimo edit --headless --no-token --port 2718
```

The marimo home page and file browser load fine. But **create a notebook and it
hangs at "connecting," with blank cells.** In the marimo server log you'll see:

```
INFO:     ("WebSocket /ws" 403)
INFO:     connection rejected (403 Forbidden)
INFO:     connection closed
```

### Root cause

marimo needs a WebSocket for cell execution and reactive updates. It sets a
**session cookie** on the initial HTTP request and requires that cookie on the
subsequent WebSocket upgrade to `/ws`. **SageMaker's JupyterLab proxy does not
forward that cookie**, so marimo rejects the handshake with **HTTP 403**. (In
the browser console this shows up as a WebSocket closing with code 1006, but
the real cause is the 403 rejection at the proxy layer.)

This is a known, still-open issue upstream —
[marimo-jupyter-extension #8](https://github.com/marimo-team/marimo-jupyter-extension/issues/8) —
independently reproduced by several people on real SageMaker Studio.

<!-- TODO(verify): reproduce the 403 baseline on a live Studio space with
     marimo 0.23.x and capture the log + browser console for the post. -->

## The fix: ws-sse-proxy

[ws-sse-proxy](https://github.com/scttfrdmn/ws-sse-proxy) is a small, generic
reverse proxy (on PyPI, MIT-licensed) that sits in front of marimo and
translates WebSocket traffic to Server-Sent Events + HTTP POST — the transports
that *do* survive the SageMaker proxy.

The key idea: **ws-sse-proxy opens the WebSocket to marimo over localhost**,
inside your space, where the session cookie and origin are intact. marimo
accepts that handshake. Only plain HTTP and SSE cross the SageMaker proxy.

```
Browser ── /jupyterlab/default/proxy/2719/ ──▶ ws-sse-proxy (:2719)
              (HTTP + SSE only)                      │
                                                     │ WebSocket over localhost
                                                     ▼ (cookie intact)
                                              marimo (127.0.0.1:2718)
```

Your notebook needs no changes. The proxy injects a tiny JavaScript shim that
tries a real WebSocket first (so it's a no-op where WebSocket already works) and
falls back to SSE when it doesn't.

<!-- TODO(verify): confirm the shim's fallback actually engages against the 403
     handshake rejection (its documented trigger is close code 1006 / stall).
     This is the single make-or-break check. Issue #8. -->

## Step-by-step

### 1. Open a JupyterLab terminal

In SageMaker Studio, launch a **JupyterLab** space and open a terminal.

### 2. Install marimo and the shim

```bash
pip install marimo ws-sse-proxy
```

### 3. Start marimo behind the proxy

```bash
curl -fsSL https://raw.githubusercontent.com/scttfrdmn/aws-marimo-sagemaker/main/start-marimo.sh -o start-marimo.sh
bash start-marimo.sh
```

`start-marimo.sh` runs marimo on `127.0.0.1:2718` (localhost only) and
ws-sse-proxy on `2719`.

### 4. Open the UI at the proxy port

Copy your JupyterLab URL and swap the path to hit **port 2719**:

```
https://<domain>.studio.<region>.sagemaker.aws/jupyterlab/default/proxy/2719/
```

<!-- TODO(verify): confirm the exact proxy base path on standalone SageMaker
     Studio vs SageMaker Unified Studio — they differ. Issue #8. -->

Cells now execute and reactive updates work.

<!-- TODO(verify): screenshot of a working reactive notebook (slider updating a
     plot) on the live space, for the post. -->

### Optional: make it persistent with a lifecycle configuration

So you don't reinstall every session, attach a JupyterLab lifecycle
configuration that installs marimo + ws-sse-proxy:

```bash
LCC_CONTENT=$(base64 < lifecycle-config/install-marimo.sh)
aws sagemaker create-studio-lifecycle-config \
    --studio-lifecycle-config-name marimo-setup \
    --studio-lifecycle-config-app-type JupyterLab \
    --studio-lifecycle-config-content "$LCC_CONTENT"
```

Then attach it to your domain, user profile, or space and select it at launch.
(The app type is `JupyterLab` for the current Studio JupyterLab app; Studio
Classic used `JupyterServer`.)

<!-- TODO(verify): confirm LCC attach + startup on a live space. Issue #8. -->

## Practical examples

### Interactive data exploration

```python
import marimo as mo
import pandas as pd
import plotly.express as px

df = pd.read_csv("s3://your-bucket/data.csv")

min_price = mo.ui.slider(
    start=df["price"].min(), stop=df["price"].max(),
    value=df["price"].median(), label="Minimum price",
)

filtered = df[df["price"] >= min_price.value]   # recomputes on slider move
mo.md(f"Showing {len(filtered)} of {len(df)} items")
mo.ui.table(filtered)
mo.ui.plotly(px.histogram(filtered, x="price", nbins=50))
```

Move the slider and the count, table, and plot all update — no callbacks, no
manual re-run.

### A SageMaker training-job monitor

```python
import marimo as mo
import boto3, pandas as pd

sagemaker = boto3.client("sagemaker")
jobs = [j["TrainingJobName"]
        for j in sagemaker.list_training_jobs(MaxResults=20)["TrainingJobSummaries"]]

selected = mo.ui.dropdown(options=jobs, value=jobs[0] if jobs else None,
                          label="Training job")

if selected.value:
    d = sagemaker.describe_training_job(TrainingJobName=selected.value)
    mo.md(f"""
    ## {selected.value}
    - **Status**: {d['TrainingJobStatus']}
    - **Instance**: {d['ResourceConfig']['InstanceType']} × {d['ResourceConfig']['InstanceCount']}
    - **Training time**: {d.get('TrainingTimeInSeconds', 0)} s
    """)
    mo.ui.table(pd.DataFrame([d["HyperParameters"]]))
```

### Converting existing Jupyter notebooks

```bash
marimo convert analysis.ipynb -o analysis.py
```

## marimo vs. Jupyter: when to use each

**marimo** for interactive apps/dashboards, reproducible research, Git-tracked
collaboration, and reusable pipelines. **Jupyter** for quick ad-hoc
exploration, multi-language kernels, or heavy investment in Jupyter extensions.
They convert back and forth — use both.

## What works where

| Capability | Local | SageMaker Studio (via shim) |
|---|---|---|
| HTTP / file browser | ✅ | ✅ |
| Cell execution (WebSocket) | ✅ | ⚠️ via ws-sse-proxy <!-- TODO(verify) --> |
| Reactive updates | ✅ | ⚠️ via ws-sse-proxy <!-- TODO(verify) --> |
| UI widgets | ✅ | ⚠️ via ws-sse-proxy <!-- TODO(verify) --> |
| `marimo run` app mode | ✅ | ⚠️ via ws-sse-proxy <!-- TODO(verify) --> |
| WASM export (no server) | ✅ | ✅ |

## Alternative: WASM export

For static or shareable notebooks that don't need space-local resources, marimo
can run entirely in the browser via WebAssembly — no server, no WebSocket, no
proxy:

```bash
marimo export html-wasm notebook.py -o out/
```

## Conclusion

marimo brings reactive, reproducible, Git-friendly notebooks to SageMaker
Studio. The one gotcha — the WebSocket 403 from the proxy stripping marimo's
session cookie — is real but small, and ws-sse-proxy closes the gap
transparently until marimo ships native SageMaker support
([track it here](https://github.com/marimo-team/marimo-jupyter-extension/issues/8)).

### Resources

- marimo docs: https://docs.marimo.io
- ws-sse-proxy: https://github.com/scttfrdmn/ws-sse-proxy
- Setup repo (scripts + this post): https://github.com/scttfrdmn/aws-marimo-sagemaker
- SageMaker Studio: https://docs.aws.amazon.com/sagemaker/latest/dg/studio-updated.html

---

*Thanks to the marimo team, and to the contributors on
[marimo-jupyter-extension #8](https://github.com/marimo-team/marimo-jupyter-extension/issues/8)
who pinned down the SageMaker cookie/403 root cause.*
