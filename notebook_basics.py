"""
marimo quick demo — SageMaker Studio.

A minimal reactive notebook: move the slider and every dependent cell updates,
with nothing re-run by hand.

Dependencies (beyond marimo):
    pip install plotly

Run it via the bridge (see the repo README):
    pip install plotly
    bash start-marimo.sh notebook_basics.py

Note: the setup, markdown, and plotting cells use hide_code=True so the slider
and its live outputs stand out — the code is a click away via the ⋯ menu.
"""

import marimo

__generated_with = "0.23.13"
app = marimo.App(width="medium")


@app.cell(hide_code=True)
def _():
    import marimo as mo
    import plotly.graph_objects as go
    return go, mo


@app.cell(hide_code=True)
def _(mo):
    mo.md(
        """
        # Welcome to marimo on SageMaker Studio! 🚀

        This notebook demonstrates reactive execution. Move the slider below —
        the numbers and the chart update on their own.
        """
    )
    return


@app.cell(hide_code=True)
def _(mo):
    slider = mo.ui.slider(1, 100, value=25, label="Select a number")
    slider
    return (slider,)


@app.cell(hide_code=True)
def _(mo, slider):
    # Recomputes whenever the slider changes — no callbacks, no manual re-run.
    mo.md(
        f"""
        - **Value**: {slider.value}
        - **Squared**: {slider.value ** 2}
        - **Cubed**: {slider.value ** 3}
        """
    )
    return


@app.cell(hide_code=True)
def _(go, mo, slider):
    x = list(range(1, 101))
    fig = go.Figure()
    fig.add_trace(go.Scatter(x=x, y=[v**2 for v in x], mode="lines", name="x²",
                             line=dict(color="blue")))
    fig.add_trace(go.Scatter(x=x, y=[v**3 for v in x], mode="lines", name="x³",
                             line=dict(color="red")))
    fig.add_trace(go.Scatter(x=[slider.value], y=[slider.value**2], mode="markers",
                             name="current x²", marker=dict(size=12, color="blue")))
    fig.add_trace(go.Scatter(x=[slider.value], y=[slider.value**3], mode="markers",
                             name="current x³", marker=dict(size=12, color="red")))
    fig.update_layout(title="Polynomial functions", xaxis_title="x",
                      yaxis_title="y", hovermode="closest")
    mo.ui.plotly(fig)
    return


@app.cell(hide_code=True)
def _(mo):
    mo.md(
        """
        ## What's happening?

        Unlike a traditional notebook:

        - No manual re-running of cells
        - No hidden state or out-of-order execution
        - Changes propagate automatically, in dependency order

        **Next:** the full workflow demo in `notebook_ml.py`, or read
        <https://docs.marimo.io>.
        """
    )
    return


if __name__ == "__main__":
    app.run()
