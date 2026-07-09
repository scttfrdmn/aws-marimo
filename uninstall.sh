#!/bin/bash
# Uninstall marimo + ws-sse-proxy from a SageMaker Studio space.
#
# v0.2.0 uses a plain pip install (no dedicated conda env, no bootstrap clone,
# no .bashrc changes), so cleanup is just: stop processes and uninstall the
# packages. Downloaded helper scripts (start-marimo.sh, etc.) are removed too.

set -e

echo "================================================"
echo "  marimo uninstall (SageMaker Studio)"
echo "================================================"
echo ""
echo "This will:"
echo "  • stop running marimo / ws-sse-proxy processes"
echo "  • pip uninstall marimo and ws-sse-proxy"
echo "  • remove downloaded helper scripts in the current directory / \$HOME"
echo ""

read -p "Proceed? (yes/no): " -r
echo
if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
    echo "Uninstall cancelled."
    exit 0
fi

echo "1) Stopping processes..."
pkill -f "marimo edit" 2>/dev/null || true
pkill -f "marimo run" 2>/dev/null || true
pkill -f "ws-sse-proxy" 2>/dev/null || true
echo "   done."

echo ""
echo "2) Uninstalling packages..."
pip uninstall -y marimo ws-sse-proxy 2>/dev/null || true
echo "   done."

echo ""
echo "3) Removing downloaded helper scripts..."
for f in ./start-marimo.sh ~/start-marimo.sh ~/upgrade-marimo.sh; do
    [ -f "$f" ] && rm -f "$f" && echo "   removed $f"
done
echo "   done."

echo ""
echo "Uninstall complete. (Your notebooks were not touched.)"
echo "To reinstall:  pip install marimo ws-sse-proxy  &&  bash start-marimo.sh"
