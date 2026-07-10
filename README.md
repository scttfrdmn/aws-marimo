# marimo on Amazon SageMaker Studio

Run [marimo](https://marimo.io) — the reactive Python notebook — on Amazon
SageMaker Studio.

[![Python](https://img.shields.io/badge/Python-3.9+-blue?logo=python&logoColor=white)](https://www.python.org)
[![marimo](https://img.shields.io/badge/marimo-latest-green?logo=python)](https://marimo.io)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

Out of the box, marimo notebooks on SageMaker Studio get stuck **"connecting"
with blank cells** — SageMaker's proxy drops the WebSocket query string that
marimo needs, so the connection is rejected. This repo ships a tiny bridge that
fixes it. ([Why, in detail →](docs/why-the-bridge.md))

## Quick start

In a SageMaker Studio **JupyterLab** space, open a terminal and run:

```bash
curl -fsSL https://raw.githubusercontent.com/scttfrdmn/aws-marimo-sagemaker/main/start-marimo.sh | bash
```

Or, if you'd rather read it before running it:

```bash
git clone https://github.com/scttfrdmn/aws-marimo-sagemaker.git
cd aws-marimo-sagemaker
bash start-marimo.sh
```

Either way it installs marimo (if needed), starts it, and prints a URL.
**Open that URL** — it's your JupyterLab host with the path replaced by:

```
/jupyterlab/default/proxy/2719/
```

The notebook renders, cells are editable, and running a cell returns output.

> **Open the bridge port (2719), not marimo's port (2718).** Port 2718 is
> marimo directly, which has the broken WebSocket; 2719 is the bridge that
> fixes it.

## Open a specific notebook

```bash
bash start-marimo.sh my_notebook.py
```

The repo includes [`marimo-demo.py`](marimo-demo.py) to try.

## Make it persist across restarts

Running the script each session works, but for regular use a Studio
**lifecycle configuration** installs marimo and the bridge once, so they
survive space restarts. See [`lifecycle-config/`](lifecycle-config/).

A custom Studio JupyterLab image can bake them in too, but note the bridge is
still required either way — it's what makes the WebSocket connect, not just
what installs marimo.

## How it works

marimo runs on `localhost:2718`; the bridge runs on `2719` and is what you open
through SageMaker. The bridge reverse-proxies marimo's HTTP and **restores the
WebSocket query string that SageMaker strips**, connecting to marimo over
localhost where everything is intact. It prefers a native WebSocket and becomes
a transparent passthrough if AWS ever fixes the underlying issue.

```
Browser ──/jupyterlab/default/proxy/2719/── SageMaker ──── bridge ──── marimo
                                                              (:2719)   (127.0.0.1:2718)
```

Full explanation, and the evidence this is a SageMaker-specific issue (not
marimo, not `jupyter-server-proxy`): **[docs/why-the-bridge.md](docs/why-the-bridge.md)**.

## Requirements

- A SageMaker Studio **JupyterLab** space (the current Studio experience).
- Nothing beyond marimo — the bridge uses libraries marimo already installs
  (`starlette`, `uvicorn`, `httpx`, `websockets`).

## Not supported

- **SageMaker Studio Lab** — [closed to new customers 2026-07-30](https://docs.aws.amazon.com/sagemaker/latest/dg/studio-lab-availability-change.html).
  The last Studio Lab release is [`v0.1.1`](https://github.com/scttfrdmn/aws-marimo-sagemaker/releases/tag/v0.1.1).
- **SageMaker Studio Classic** — end of maintenance, no new onboarding.

## License

MIT — see [LICENSE](LICENSE). marimo is Apache 2.0.
