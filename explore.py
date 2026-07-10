"""Interactive weather-anomaly explorer — marimo on SageMaker Studio.

Fits a seasonal model to a NOAA GHCN station's 2023 daily-high temperatures
(read straight from S3, no download) and flags days that are unusually hot or
cold for the time of year. Change the station and the model refits; drag the
threshold and the anomalies re-flag — reactively, in order, every time.

Data: NOAA GHCN-Daily on the AWS Open Data Registry
      https://registry.opendata.aws/noaa-ghcn/  (public bucket, no credentials)

Run it via the bridge (see the repo README):
    pip install polars pyarrow s3fs scikit-learn altair
    bash start-marimo.sh explore.py

Note: the "display" cells below use hide_code=True so the controls, the summary,
and the chart render on their own — the code is a click away via the ⋯ menu.
"""

import marimo

__generated_with = "0.23.13"
app = marimo.App(width="medium")


@app.cell(hide_code=True)
def _():
    import marimo as mo
    import numpy as np
    import polars as pl
    import altair as alt
    from sklearn.linear_model import LinearRegression
    return LinearRegression, alt, mo, np, pl


@app.cell(hide_code=True)
def _(mo):
    mo.md(
        """
        # Weather anomalies, live — marimo on SageMaker

        Which days in 2023 were unusually hot or cold for the time of year at a
        given weather station? We fit a smooth seasonal model, then flag the
        days that deviate most. Everything below recomputes as you change the
        controls.
        """
    )
    return


@app.cell(hide_code=True)
def _(pl):
    # Daily maximum temperature (TMAX) for 2023, read directly from S3.
    # DATA_VALUE is in tenths of °C. This is millions of rows across many
    # files — fast next to the bucket, awkward to pull to a laptop.
    tmax = pl.read_parquet(
        "s3://noaa-ghcn-pds/parquet/by_year/YEAR=2023/ELEMENT=TMAX/*.parquet",
        storage_options={
            # Public bucket → no signing. The bucket is in us-east-1; pin it so
            # the read works from a space in any region. (For your own private
            # data, drop both of these — your instance's credentials/region are
            # used automatically.)
            "skip_signature": "true",
            "aws_region": "us-east-1",
        },
        columns=["ID", "DATE", "DATA_VALUE"],
    ).with_columns(
        (pl.col("DATA_VALUE") / 10).alias("tmax_c"),
        pl.col("DATE").str.strptime(pl.Date, "%Y%m%d"),
    )
    return (tmax,)


@app.cell(hide_code=True)
def _(mo):
    # Controls are just values — no callbacks, no "on change" wiring.
    station = mo.ui.dropdown(
        {
            "New York (Central Park)": "USW00094728",
            "Chicago O'Hare": "USW00094846",
            "Denver Intl": "USW00003017",
            "Phoenix Sky Harbor": "USW00023183",
        },
        value="New York (Central Park)",
        label="Station",
    )
    sensitivity = mo.ui.slider(
        1.5, 3.5, value=2.5, step=0.5, label="Anomaly threshold (σ)"
    )
    return sensitivity, station


@app.cell(hide_code=True)
def _(mo, sensitivity, station):
    # Display the controls on their own (no code around them).
    mo.hstack([station, sensitivity], justify="start", gap=2)
    return


@app.cell
def _(LinearRegression, np, pl, station, tmax):
    # Fit the "normal" yearly cycle with a couple of harmonics of the annual
    # period — a small, interpretable model, not a black box. Refits whenever
    # the selected station changes.
    s = tmax.filter(pl.col("ID") == station.value).sort("DATE")

    doy = np.array([d.timetuple().tm_yday for d in s["DATE"].to_list()])
    y = s["tmax_c"].to_numpy()

    X = np.column_stack([
        np.sin(2 * np.pi * doy / 365), np.cos(2 * np.pi * doy / 365),
        np.sin(4 * np.pi * doy / 365), np.cos(4 * np.pi * doy / 365),
    ])
    model = LinearRegression().fit(X, y)
    expected = model.predict(X)
    residual = y - expected

    # Classify anomalies at the chosen threshold.
    z = (residual - residual.mean()) / residual.std()
    return X, expected, model, s, y, z


@app.cell
def _(X, expected, model, np, s, sensitivity, y, z):
    result = s.with_columns(
        expected=expected,
        is_anomaly=np.abs(z) > sensitivity.value,
    )
    n_anomalies = int(result["is_anomaly"].sum())
    r2 = model.score(X, y)
    return n_anomalies, r2, result


@app.cell(hide_code=True)
def _(mo, n_anomalies, r2, sensitivity):
    # The headline result, on its own line.
    mo.md(
        f"### **{n_anomalies}** anomalous days at {sensitivity.value}σ "
        f"&nbsp;·&nbsp; seasonal fit R² = {r2:.2f}"
    )
    return


@app.cell(hide_code=True)
def _(alt, result, station):
    base = alt.Chart(result.to_pandas()).encode(x="DATE:T")
    line = base.mark_line(color="steelblue").encode(
        y=alt.Y("tmax_c:Q", title="Daily high (°C)")
    )
    fit = base.mark_line(color="orange").encode(y="expected:Q")
    flags = base.transform_filter("datum.is_anomaly").mark_point(
        color="red", size=60
    ).encode(y="tmax_c:Q")
    (line + fit + flags).properties(
        title=f"{station.selected_key} — 2023 daily highs (orange = seasonal fit, red = anomaly)",
        width=680,
        height=340,
    )
    return


if __name__ == "__main__":
    app.run()
