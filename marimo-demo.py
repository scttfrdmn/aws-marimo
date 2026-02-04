"""
marimo Quick Demo - SageMaker Studio Lab
Try this to see reactive programming in action!
"""

import marimo

__generated_with = "0.19.7"
app = marimo.App(width="medium")


@app.cell
def __():
    import marimo as mo
    return mo,


@app.cell
def __(mo):
    mo.md(
        """
        # Welcome to marimo on Studio Lab! 🚀

        This notebook demonstrates reactive execution. Try moving the slider below!
        """
    )
    return


@app.cell
def __(mo):
    # Create an interactive slider
    slider = mo.ui.slider(1, 100, value=25, label="Select a number")
    slider
    return slider,


@app.cell
def __(mo, slider):
    # This cell automatically updates when slider changes!
    squared = slider.value ** 2
    cubed = slider.value ** 3

    mo.md(
        f"""
        ## Reactive Calculations

        - **Value**: {slider.value}
        - **Squared**: {squared}
        - **Cubed**: {cubed}

        *Move the slider and watch these update automatically!*
        """
    )
    return cubed, squared


@app.cell
def __(mo, slider):
    # Interactive visualization
    import plotly.graph_objects as go

    x_values = list(range(1, 101))
    y_squared = [x**2 for x in x_values]
    y_cubed = [x**3 for x in x_values]

    fig = go.Figure()

    fig.add_trace(go.Scatter(
        x=x_values,
        y=y_squared,
        mode='lines',
        name='x²',
        line=dict(color='blue')
    ))

    fig.add_trace(go.Scatter(
        x=x_values,
        y=y_cubed,
        mode='lines',
        name='x³',
        line=dict(color='red')
    ))

    # Highlight current value
    fig.add_trace(go.Scatter(
        x=[slider.value],
        y=[slider.value**2],
        mode='markers',
        name='Current x²',
        marker=dict(size=12, color='blue')
    ))

    fig.add_trace(go.Scatter(
        x=[slider.value],
        y=[slider.value**3],
        mode='markers',
        name='Current x³',
        marker=dict(size=12, color='red')
    ))

    fig.update_layout(
        title='Polynomial Functions',
        xaxis_title='x',
        yaxis_title='y',
        hovermode='closest'
    )

    mo.ui.plotly(fig)
    return fig, go, x_values, y_cubed, y_squared


@app.cell
def __(mo):
    mo.md(
        """
        ## What's Happening?

        Unlike traditional notebooks:
        - ✅ No manual re-running of cells
        - ✅ No hidden state or out-of-order execution
        - ✅ Changes propagate automatically
        - ✅ Everything stays synchronized

        ## Try This:
        1. Move the slider
        2. Watch calculations and plots update instantly
        3. Notice you didn't click "Run" on any cell!

        ## Next Steps:
        - Try the full ML demo: `sagemaker_ml_demo.py`
        - Read the docs: https://docs.marimo.io
        """
    )
    return


if __name__ == "__main__":
    app.run()
