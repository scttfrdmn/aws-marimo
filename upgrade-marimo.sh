#!/bin/bash
# Upgrade marimo and ws-sse-proxy in the current environment.
#
# On SageMaker Studio (JupyterLab space) the space's own Python environment is
# already active — there is no dedicated conda env to activate (that was the
# Studio Lab model, removed in v0.2.0).

set -e

echo "================================================"
echo "  marimo + ws-sse-proxy upgrade"
echo "================================================"
echo ""

echo "Current versions:"
marimo --version 2>&1 | sed 's/^/  marimo: /' || echo "  marimo: not installed"
python -c "import importlib.metadata as m; print('  ws-sse-proxy:', m.version('ws-sse-proxy'))" 2>/dev/null \
    || echo "  ws-sse-proxy: not installed"
echo ""

echo "Upgrading..."
pip install --upgrade marimo ws-sse-proxy

echo ""
echo "New versions:"
marimo --version 2>&1 | sed 's/^/  marimo: /'
python -c "import importlib.metadata as m; print('  ws-sse-proxy:', m.version('ws-sse-proxy'))" 2>/dev/null || true

echo ""
echo "Upgrade complete. Start marimo with:  bash start-marimo.sh"
