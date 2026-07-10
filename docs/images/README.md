# Blog post images

Placeholders referenced by `../blog-post.md` (paths are relative to the post,
i.e. `images/<file>`). Capture on a live SageMaker Studio JupyterLab space
running `explore.py` via the bridge.

| File | Priority | What to capture |
|---|---|---|
| `marimo-on-sagemaker.png` | **essential** | Hero shot: `explore.py` running live — station dropdown + σ-slider on top, chart below (blue actual / orange fit / red anomalies), address bar showing `/jupyterlab/default/proxy/2719/`. |
| `reactivity.gif` | **essential** | One control change propagating (drag σ-slider or switch station); fit, count, and red dots update with nothing re-run. Two-panel PNG before/after is an acceptable fallback. |
| `architecture.png` | nice-to-have | Clean 4-box horizontal flow: Browser → SageMaker proxy (`/proxy/2719/`) → bridge (`:2719`) → marimo (`127.0.0.1:2718`). |
| `blank-notebook.png` | optional | The pre-fix failure state: blank canvas, stuck "connecting". |
| (terminal link) | optional | Terminal after `start-marimo.sh` showing the printed clickable link. No file wired in the post; add if desired. |

Keep images reasonably sized (≤ ~1600px wide) so the repo stays light.
