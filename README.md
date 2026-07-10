# marimo on Amazon SageMaker Studio

Run [marimo](https://marimo.io) — the reactive Python notebook — on Amazon
SageMaker Studio.

[![Python](https://img.shields.io/badge/Python-3.9+-blue?logo=python&logoColor=white)](https://www.python.org)
[![marimo](https://img.shields.io/badge/marimo-latest-green?logo=python)](https://marimo.io)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

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

It installs marimo (if needed), starts it, and prints a **clickable link** to
open marimo in your browser. Click it.

The notebook renders, cells are editable, and running a cell returns output.

## Open a specific notebook

```bash
bash start-marimo.sh my_notebook.py
```

Two notebooks to try are included:

- [`marimo-demo.py`](marimo-demo.py) — a minimal reactive demo (marimo only).
- [`explore.py`](explore.py) — reads NOAA weather data from S3, fits a seasonal
  model, and flags anomalous days live. Install its extras first:
  `pip install polars pyarrow s3fs scikit-learn altair`.

## Make it persist across restarts

Running the script each session works, but for regular use a Studio
**lifecycle configuration** installs marimo and the bridge once, so they
survive space restarts. See [`lifecycle-config/`](lifecycle-config/).

A custom Studio JupyterLab image can bake them in too. Either way, the bridge
is required — it's what enables marimo to work on SageMaker.

## How it works

marimo runs on `localhost:2718`. The bridge runs on `2719` — the port you open
through SageMaker — and forwards to marimo.

```
Browser ──▶ SageMaker proxy ──▶ bridge ──▶ marimo
            /proxy/2719/        :2719       127.0.0.1:2718
```

For what the bridge does and why SageMaker needs it, see
**[docs/why-the-bridge.md](docs/why-the-bridge.md)**.

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
