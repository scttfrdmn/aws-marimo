"""Interactive weather-anomaly explorer — marimo on SageMaker Studio.

Fits a seasonal model to a NOAA GHCN station's 2023 daily-high temperatures
(read straight from S3, no download) and flags days that are unusually hot or
cold for the time of year. Change the station and the model refits; drag the
threshold and the anomalies re-flag — reactively, in order, every time.

Data: NOAA GHCN-Daily on the AWS Open Data Registry
      https://registry.opendata.aws/noaa-ghcn/  (public bucket, no credentials)

Dependencies (beyond marimo):
    pip install polars pyarrow s3fs scikit-learn altair

Run it via the bridge (see the repo README):
    pip install polars pyarrow s3fs scikit-learn altair
    bash start-marimo.sh explore.py
"""

import marimo

__generated_with = "0.23.13"
app = marimo.App(width="medium")


@app.cell
def _():
    import marimo as mo
    import numpy as np
    import polars as pl
    import altair as alt
    from sklearn.linear_model import LinearRegression
    return LinearRegression, alt, mo, np, pl


@app.cell
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


@app.cell
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


@app.cell
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
    mo.hstack([station, sensitivity])
    return sensitivity, station


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
    return X, expected, model, residual, s, y


@app.cell
def _(expected, mo, model, np, residual, s, sensitivity, X, y):
    # Classify anomalies at the chosen threshold — re-runs when the slider moves.
    z = (residual - residual.mean()) / residual.std()
    result = s.with_columns(
        expected=expected,
        is_anomaly=np.abs(z) > sensitivity.value,
    )
    n = int(result["is_anomaly"].sum())
    summary = mo.md(
        f"**{n}** anomalous days at {sensitivity.value}σ "
        f"(seasonal fit R² = {model.score(X, y):.2f})"
    )
    summary
    return (result,)


@app.cell
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
