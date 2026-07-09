# marimo on Amazon SageMaker Studio

Run [marimo](https://marimo.io), the reactive Python notebook, on Amazon
SageMaker Studio — with interactive cell execution working, via a small
WebSocket-to-SSE shim.

[![5-Minute Setup](https://img.shields.io/badge/⚡_5--Minute-Setup_Guide-brightgreen)](QUICKSTART.md)
[![Python](https://img.shields.io/badge/Python-3.9+-blue?logo=python&logoColor=white)](https://www.python.org)
[![marimo](https://img.shields.io/badge/marimo-latest-green?logo=python)](https://marimo.io)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Version](https://img.shields.io/badge/version-0.2.0-blue)](VERSION)

---

> ### ⚠️ Studio Lab is no longer supported
> Earlier versions of this project targeted **SageMaker Studio Lab**. AWS is
> [closing Studio Lab to new customers on 2026-07-30](https://docs.aws.amazon.com/sagemaker/latest/dg/studio-lab-availability-change.html),
> so as of **v0.2.0** this project targets full **SageMaker Studio** (the
> JupyterLab experience) and **SageMaker Unified Studio** only. If you need the
> Studio Lab scripts, use the [`v0.1.1` release](https://github.com/scttfrdmn/aws-marimo-sagemaker/releases/tag/v0.1.1).
> SageMaker Studio *Classic* is also EOL (no new onboarding) and is not a target.

---

## The one thing you need to know

On SageMaker Studio, marimo's home page and file browser load fine, but
**notebooks get stuck "connecting" with blank cells**. The SageMaker JupyterLab
proxy strips marimo's session cookie, so marimo rejects its WebSocket handshake
with HTTP 403.

The fix is [ws-sse-proxy](https://github.com/scttfrdmn/ws-sse-proxy): it runs
marimo behind a shim that keeps the WebSocket on localhost (where the cookie is
intact) and only sends HTTP + Server-Sent Events through the SageMaker proxy.
Full detail and root cause: **[WEBSOCKET-STATUS.md](WEBSOCKET-STATUS.md)**.

## Quick start

In a SageMaker Studio JupyterLab terminal:

```bash
pip install marimo ws-sse-proxy
curl -fsSL https://raw.githubusercontent.com/scttfrdmn/aws-marimo-sagemaker/main/start-marimo.sh -o start-marimo.sh
bash start-marimo.sh
```

Then open marimo at the **proxy** port (`2719`), not marimo's port:

```
https://<domain>.studio.<region>.sagemaker.aws/jupyterlab/default/proxy/2719/
```

<!-- TODO(verify): confirm the exact proxy base path on standalone SageMaker
     Studio vs SageMaker Unified Studio — they differ. See issue #8. -->

See **[QUICKSTART.md](QUICKSTART.md)** for the step-by-step, and
`lifecycle-config/install-marimo.sh` for a persistent install via a JupyterLab
lifecycle configuration.

## Why marimo?

Traditional Jupyter notebooks have well-known issues:
- ❌ Hidden state from out-of-order execution
- ❌ JSON format causes Git conflicts
- ❌ Hard to reproduce

marimo solves these:
- ✅ Reactive execution — cells auto-update when dependencies change
- ✅ Stored as pure Python — Git-friendly, runnable as scripts
- ✅ No hidden state — deterministic, reproducible
- ✅ Interactive UI widgets with no callbacks
- ✅ One file is a notebook, a script, and a web app

## Architecture

```
┌──────────────────────────────────────────────┐
│  SageMaker Studio (JupyterLab space)          │
│                                               │
│   Browser ──/jupyterlab/default/proxy/2719/── │
│        │        (HTTP + SSE only)             │
│        ▼                                      │
│   ws-sse-proxy  (:2719)                       │
│        │  WebSocket over localhost            │
│        ▼  (session cookie intact)             │
│   marimo server (127.0.0.1:2718)              │
└──────────────────────────────────────────────┘
```

## What works where

| Capability | Local | SageMaker Studio (via shim) | Studio Lab (EOL, v0.1.x) |
|---|---|---|---|
| HTTP / file browser | ✅ | ✅ | ✅ |
| Cell execution (WebSocket) | ✅ | ⚠️ via ws-sse-proxy <!-- TODO(verify) --> | ❌ |
| Reactive updates | ✅ | ⚠️ via ws-sse-proxy <!-- TODO(verify) --> | ❌ |
| UI widgets | ✅ | ⚠️ via ws-sse-proxy <!-- TODO(verify) --> | ❌ |
| `marimo run` app mode | ✅ | ⚠️ via ws-sse-proxy <!-- TODO(verify) --> | ❌ |
| WASM export (no server) | ✅ | ✅ | ✅ |

The ⚠️ rows are the workaround this repo provides. They are pending end-to-end
verification on a live SageMaker Studio space — see
[issue #8](https://github.com/scttfrdmn/aws-marimo-sagemaker/issues/8).

## Repository structure

```
.
├── README.md                    # This file
├── QUICKSTART.md                # Step-by-step setup on SageMaker Studio
├── WEBSOCKET-STATUS.md          # Root cause + why ws-sse-proxy fixes it
├── blog-post.md                 # Long-form write-up (draft)
├── start-marimo.sh              # Launch marimo + ws-sse-proxy
├── upgrade-marimo.sh            # Upgrade marimo + ws-sse-proxy
├── uninstall.sh                 # Remove the local setup
├── diagnose-proxy.sh            # Troubleshoot proxy/access
├── lifecycle-config/
│   └── install-marimo.sh        # Persistent install via JupyterLab LCC
├── marimo-demo.py               # Simple reactive demo
├── sagemaker_ml_demo.py         # ML workflow demo
├── CONTRIBUTING.md
├── CHANGELOG.md
├── LICENSE
└── VERSION
```

## Sample

```python
import marimo as mo

slider = mo.ui.slider(0, 100, value=50)
result = slider.value ** 2          # recomputes automatically when the slider moves
mo.md(f"Value: {slider.value}, Squared: {result}")
```

See [sagemaker_ml_demo.py](sagemaker_ml_demo.py) for a complete example,
including `boto3` SageMaker integration.

## Upstream

The real fix belongs in marimo. Track / support it here:
- [marimo-jupyter-extension #8 — feat: support sagemaker](https://github.com/marimo-team/marimo-jupyter-extension/issues/8) (open)
- [marimo #8060 — WebSocket issue on SageMaker](https://github.com/marimo-team/marimo/issues/8060) (closed, redirected to #8)

Until a native fix ships, ws-sse-proxy is the working path.

## Troubleshooting

Run `bash diagnose-proxy.sh`, or see [QUICKSTART.md](QUICKSTART.md#troubleshooting).
Common gotcha: access the **proxy** port `2719`, not marimo's `2718`.

## License

This repository: MIT. marimo: Apache 2.0. ws-sse-proxy: MIT.

## Acknowledgments

- The **marimo team** for the reactive notebook platform.
- Contributors on [marimo-jupyter-extension #8](https://github.com/marimo-team/marimo-jupyter-extension/issues/8) who pinned down the SageMaker cookie/403 root cause.

---

- **Version**: 0.2.0 ([SemVer](https://semver.org/)) · **License**: [MIT](LICENSE) · © 2026 Scott Friedman
- Contributions welcome — see [CONTRIBUTING.md](CONTRIBUTING.md).
