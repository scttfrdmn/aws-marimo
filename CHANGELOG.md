# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.3.0] - 2026-07-10

**marimo now runs interactively on SageMaker Studio, verified end-to-end** — a
cell renders, edits, and executes in a browser on a live Studio JupyterLab space.

### Changed
- Replaced the external `ws-sse-proxy` dependency with a single vendored file,
  [`sagemaker_marimo_bridge.py`](sagemaker_marimo_bridge.py). No extra install —
  it uses libraries marimo already ships (`starlette`, `uvicorn`, `httpx`,
  `websockets`).
- `start-marimo.sh` now runs the vendored bridge, works both cloned and via
  `curl … | bash`, and can open a specific notebook (`bash start-marimo.sh nb.py`).
- Trimmed the docs to a cut-to-the-chase README plus one explainer,
  [docs/why-the-bridge.md](docs/why-the-bridge.md).

### Fixed
- **Corrected the root cause.** It is **not** a stripped session *cookie*.
  SageMaker Studio's proxy **drops the query string on WebSocket upgrades**, so
  marimo's `session_id` never reaches the backend and marimo 403s the `/ws`
  handshake (→ blank notebook). The bridge restores the query — smuggled through
  the URL path, which SageMaker preserves — and connects to marimo over
  localhost. Verified that marimo and `jupyter-server-proxy` are both correct;
  the strip is SageMaker-specific.

### Removed
- `WEBSOCKET-STATUS.md`, `QUICKSTART.md`, `blog-post.md` (draft),
  `diagnose-proxy.sh`, `upgrade-marimo.sh`, `uninstall.sh`, and the `test/`
  debugging harnesses — superseded (still in git history).

## [0.2.0] - 2026-07-08

Retargets the project from the now-EOL SageMaker Studio Lab to full **SageMaker
Studio** (JupyterLab) and **SageMaker Unified Studio**, with `ws-sse-proxy` as
the built-in fix for marimo's WebSocket problem.

> **Verification pending:** the interactive path (cell execution via
> ws-sse-proxy) is designed and wired but not yet confirmed end-to-end on a live
> SageMaker Studio space. Docs mark such claims with `TODO(verify)`. Tracking:
> [issue #8](https://github.com/scttfrdmn/aws-marimo-sagemaker/issues/8).

### Added
- `start-marimo.sh` — launches marimo (127.0.0.1:2718) + ws-sse-proxy (2719).
- `lifecycle-config/install-marimo.sh` — persistent install via a JupyterLab
  lifecycle configuration (app type `JupyterLab`).
- Per-platform "what works where" support matrix in README and blog post.

### Changed
- Corrected the WebSocket root cause in `WEBSOCKET-STATUS.md`: SageMaker's
  JupyterLab proxy strips marimo's session cookie, so marimo rejects the `/ws`
  handshake with **HTTP 403** (not an ALB `Connection: Upgrade` rewrite).
- Rewrote `README.md`, `QUICKSTART.md`, and `blog-post.md` around SageMaker
  Studio + ws-sse-proxy; corrected the proxy path to `/jupyterlab/default/proxy/`.
- `upgrade-marimo.sh`, `uninstall.sh`, `diagnose-proxy.sh` no longer assume the
  Studio Lab `marimo-env` conda env or bootstrap clone.
- Demo notebooks: dropped the Studio-Lab `__generated_with` sed-rewrite comment.

### Removed
- Studio Lab scripts and docs: `studio-lab-setup.sh`, `bootstrap.sh`,
  `start-marimo-improved.sh`, `start-marimo-shim.sh`, `fix-proxy.sh`,
  `fix-proxy-version.sh`, `STUDIO-LAB-SETUP.md`, `STUDIO-LAB-ACCESS.md`,
  `BOOTSTRAP.md`, `BADGES.md`, and the `chat.md` build-log artifact.
  (Studio Lab support remains available in the `v0.1.1` release.)

## [0.1.1] - 2026-07-08

**Final SageMaker Studio Lab release.** AWS is closing Studio Lab to new
customers on 2026-07-30, so this is the last version targeting it. Development
continues in v0.2.0, which drops Studio Lab and focuses on full SageMaker
Studio (JupyterLab). See the
[Studio Lab availability change](https://docs.aws.amazon.com/sagemaker/latest/dg/studio-lab-availability-change.html).

### Fixed
- Corrected stale `aws-marimo` repository/directory references to
  `aws-marimo-sagemaker` across all scripts and docs (the mismatch broke the
  auto-update logic in `~/start-marimo.sh`, which looked for a directory
  `bootstrap.sh` never created)
- Replaced `YOUR_USERNAME` placeholders with `scttfrdmn` in this project's own
  setup instructions and badges (kept as placeholders only in the fork/clone
  guidance where they belong)
- Removed a hard-coded personal Studio Lab domain from `fix-proxy.sh`

### Changed
- Marked the Terraform, CDK, and `notebooks/` infrastructure-as-code as planned
  (not yet shipped) in README and blog-post, instead of documenting them as if
  they were available

## [0.1.0] - 2026-01-14

### Added
- Complete marimo ML workflow demo (`sagemaker_ml_demo.py`)
- SageMaker Studio Lab automated setup scripts
- One-command bootstrap from GitHub (`bootstrap.sh`)
- Studio Lab setup with conda environment (`studio-lab-setup.sh`)
- Auto-updating start script
- Quick start guide (`QUICKSTART.md`)
- Comprehensive blog post (`blog-post.md`)
- Bootstrap documentation (`BOOTSTRAP.md`)
- Badge options guide (`BADGES.md`)
- Studio Lab setup guide (`STUDIO-LAB-SETUP.md`)
- Demo notebook with reactive visualizations
- Support for Python 3.9+
- Dependencies: marimo, pandas, numpy, boto3, plotly, scikit-learn

### Documentation
- Added Python-only platform clarification in blog post
- Installation instructions for both Studio Lab and Studio
- Troubleshooting sections
- Comparison tables (Studio Lab vs Studio)

[unreleased]: https://github.com/scttfrdmn/aws-marimo-sagemaker/compare/v0.3.0...HEAD
[0.3.0]: https://github.com/scttfrdmn/aws-marimo-sagemaker/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/scttfrdmn/aws-marimo-sagemaker/compare/v0.1.1...v0.2.0
[0.1.1]: https://github.com/scttfrdmn/aws-marimo-sagemaker/compare/v0.1.0...v0.1.1
[0.1.0]: https://github.com/scttfrdmn/aws-marimo-sagemaker/releases/tag/v0.1.0
