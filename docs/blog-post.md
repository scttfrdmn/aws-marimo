# Interactive notebooks where your data lives: marimo on SageMaker Studio

If you've used [marimo](https://marimo.io), you already know the pitch: a Python
notebook that's *reactive* (change a cell and everything that depends on it
re-runs), has *no hidden state* (no more "restart kernel and run all" to find
out what your notebook actually does), and is stored as a plain `.py` file you
can diff, review, and run as a script. For anyone who's been burned by a
Jupyter notebook that only works if you run the cells in exactly the right
order, it's a relief.

Here's the thing, though: a lot of our data doesn't live on our laptops. It
lives in S3, behind an account boundary, next to the compute that's allowed to
touch it. That's the whole point of SageMaker Studio — you work *where the data
is*, on an instance sized for the job, without copying anything to your
machine. So the natural question is: can I have marimo's reactive, reproducible
workflow *in that environment*?

Until recently the answer was "sort of." marimo would load in SageMaker
Studio's JupyterLab, but notebooks got stuck **"connecting," with blank cells** —
you could see the file, but you couldn't run anything. Not much use.

That's fixed now, with a small bridge you start alongside marimo. This post
shows how to get it running, and then builds a small but real example that only
makes sense *because* it's on SageMaker — fitting a model over a public dataset
that's far too big to pull down to a laptop, and exploring its results live.

## Getting marimo running (about a minute)

In a SageMaker Studio **JupyterLab** space, open a terminal and run:

```bash
curl -fsSL https://raw.githubusercontent.com/scttfrdmn/aws-marimo-sagemaker/main/start-marimo.sh | bash
```

It installs marimo if needed, starts it behind the bridge, and prints a
clickable link. Click it, and you're in a working marimo notebook — cells
render, edit, and execute.

Prefer to read before you run? Clone the repo and run `bash start-marimo.sh`
instead. Either way, to open a specific notebook:

```bash
bash start-marimo.sh explore.py
```

### Why the bridge, in one paragraph

You don't need this to use marimo, but you might be curious. SageMaker Studio
serves apps under a proxy path (`/jupyterlab/default/proxy/PORT/`), and that
proxy **drops the query string from WebSocket upgrade requests**. marimo puts
its session ID in that query, so the backend never receives it and rejects the
connection — hence the blank, stuck notebook. The bridge simply restores what
gets dropped and connects to marimo over localhost. (Interestingly, this isn't
marimo's fault or the open-source proxy's fault — both handle the query
correctly; it's specific to SageMaker's layer. There's a
[short write-up](https://github.com/scttfrdmn/aws-marimo-sagemaker/blob/main/docs/why-the-bridge.md)
if you want the details.) It prefers a normal WebSocket, so if AWS ever fixes
the underlying behavior, the bridge quietly gets out of the way.

## An example that earns its place on SageMaker

Toy examples undersell this, so let's use real data that would be genuinely
awkward to handle anywhere else. NOAA's Global Historical Climatology Network
lives on the
[AWS Open Data Registry](https://registry.opendata.aws/noaa-ghcn/) as
partitioned Parquet — daily weather observations from tens of thousands of
stations worldwide, roughly **9 GB** just for the recent years. It's public, so
you can run exactly this, but it's the right *shape*: too big to casually pull
to a laptop, and fast to read from an instance in the same region.

A couple of libraries beyond marimo (once):

```bash
pip install polars pyarrow s3fs scikit-learn altair
```

On SageMaker, reading straight from S3 needs no setup — the credentials and
network path are already there:

```python
import marimo as mo
import polars as pl
```

```python
# Daily maximum temperature (TMAX) for 2023, read directly from S3.
# No download, no credentials to wire up. DATA_VALUE is in tenths of °C.
tmax = pl.read_parquet(
    "s3://noaa-ghcn-pds/parquet/by_year/YEAR=2023/ELEMENT=TMAX/*.parquet",
    storage_options={"anon": "true"},  # public bucket; drop this for your own data
    columns=["ID", "DATE", "DATA_VALUE"],
).with_columns(
    (pl.col("DATA_VALUE") / 10).alias("tmax_c"),
    pl.col("DATE").str.strptime(pl.Date, "%Y%m%d"),
)
```

That's already something you can't comfortably do on a laptop — millions of
rows across many files — and on a modest instance it reads in seconds because
you're next to the bucket. That's the "why SageMaker" half: proximity to data
and compute you don't have at home.

Reading the data isn't the interesting part, though — this is SageMaker, so
let's actually *model* something. A natural question for any station: **which
days in 2023 were unusually hot or cold for the time of year?** "Unusual" only
means something relative to the expected seasonal pattern, so we (1) fit a
model of the normal yearly cycle, then (2) flag the days that deviate most.

First, the controls — just values:

```python
# A few well-known US stations; add your own GHCN IDs freely.
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
sensitivity = mo.ui.slider(1.5, 3.5, value=2.5, step=0.5,
                           label="Anomaly threshold (σ)")
mo.hstack([station, sensitivity])
```

Now the model. Temperature's yearly cycle is smooth and periodic, so a handful
of sine/cosine terms (a harmonic regression) captures the "normal" curve well —
a small, honest, interpretable model, not a black box:

```python
import numpy as np
from sklearn.linear_model import LinearRegression

s = tmax.filter(pl.col("ID") == station.value).sort("DATE")

doy = np.array([d.timetuple().tm_yday for d in s["DATE"].to_list()])
y = s["tmax_c"].to_numpy()

# Two harmonics of the annual cycle → the expected daily high for each day.
X = np.column_stack([
    np.sin(2 * np.pi * doy / 365), np.cos(2 * np.pi * doy / 365),
    np.sin(4 * np.pi * doy / 365), np.cos(4 * np.pi * doy / 365),
])
model = LinearRegression().fit(X, y)
expected = model.predict(X)
residual = y - expected
```

The anomalies are the days whose residual exceeds the threshold you set — and
because it's marimo, moving the slider re-classifies them live:

```python
z = (residual - residual.mean()) / residual.std()
result = s.with_columns(
    expected=expected,
    is_anomaly=np.abs(z) > sensitivity.value,
)
n = int(result["is_anomaly"].sum())
mo.md(f"**{n}** anomalous days at {sensitivity.value}σ "
      f"(seasonal fit R² = {model.score(X, y):.2f})")
```

```python
import altair as alt

base = alt.Chart(result.to_pandas()).encode(x="DATE:T")
line = base.mark_line(color="steelblue").encode(y=alt.Y("tmax_c:Q", title="Daily high (°C)"))
fit = base.mark_line(color="orange").encode(y="expected:Q")
flags = base.transform_filter("datum.is_anomaly").mark_point(
    color="red", size=60).encode(y="tmax_c:Q")
(line + fit + flags).properties(title=f"{station.selected_key} — 2023, hot/cold anomalies")
```

Here's what makes this feel different from a normal notebook: **change the
station and the model refits; drag the threshold and the anomalies re-flag — the
regression, the classification, the summary, and the chart all recompute
automatically, in order, every time.** You never re-run a cell by hand. You
can't accidentally leave a model fitted on the *previous* station lying around,
because marimo tracks the dependencies between cells and re-runs exactly what's
affected. When the chart says "8 anomalous days," the model on screen is the one
that produced them — the notebook can't drift out of sync with itself.

(For Central Park in 2023 you'll see a seasonal fit around R² = 0.77 and, at
2.5σ, a handful of flagged days — the sharp warm and cold snaps that stand out
against an otherwise smooth year.)

Try to reproduce that experience elsewhere and you feel the friction:

- **On a laptop**, the dataset doesn't fit, and (if it's governed) legally
  can't be there. Full stop.
- **In a classic Jupyter notebook** on the same instance, you *can* read the
  data — but the interactivity is where it falls apart. You'd wire up
  `ipywidgets` callbacks by hand, and every time you change the station you have
  to remember to re-run the fit cell, *then* the classification cell, *then* the
  plot — in that order. Miss one and the chart shows last station's model over
  this station's data, and nothing warns you. That stale-model trap is exactly
  the hidden, order-dependent state notebooks are notorious for.

marimo gives you the live exploration *and* the guarantee that the model on
screen is the one that produced the result — on the instance that's allowed to
see the data. That combination is the point.

## The part your colleagues will thank you for

Because a marimo notebook is a plain Python file, everything downstream just
works:

- **It's reviewable.** `explore.py` is real code. It goes in the repo, it shows
  up in a pull request as a readable diff, and a teammate can see exactly what
  changed — not a wall of JSON and base64 image blobs.
- **It's reproducible.** A colleague opens the same file on their own SageMaker
  space, and because there's no hidden execution order to reconstruct, they get
  the same explorer you did. This matters more in research than we usually
  admit: "it worked when I ran the cells in this particular sequence" is not
  reproducibility.
- **It's shareable as an app.** The same file runs read-only with:

  ```bash
  marimo run explore.py
  ```

  Point the bridge at that instead, and a non-notebook colleague — a domain
  expert, a manager — gets the sliders and the chart without ever seeing (or
  being able to break) the code. Same file, no rewrite, no separate dashboard
  framework.

So the artifact you commit is simultaneously your analysis, a reproducible
record of it, and a small interactive app. On SageMaker, it's all sitting next
to the data that made it possible.

## Wrapping up

None of this is exotic. It's a notebook, a dataset in S3, a small model, and a
chart. But the *combination* is one that's been oddly hard to get:

- **marimo** gives you interactivity without callback plumbing, and
  reproducibility without ceremony — your notebook is honest about what it
  computes, and it's a `.py` file you can review and rerun.
- **SageMaker** gives you the data and the compute in a place you can't
  replicate on a laptop, for reasons of size, speed, or governance.
- The **bridge** is the small missing piece that lets the first run in the
  second — one command, then a clickable link.

If you've been keeping marimo for local work and reaching for something clunkier
the moment your data moves to the cloud, you don't have to anymore. Start it up,
point it at your bucket, and let the model refit as you explore.

The setup, the bridge, and a runnable demo notebook are here:
**https://github.com/scttfrdmn/aws-marimo-sagemaker**

---

*The example uses [polars](https://pola.rs), [scikit-learn](https://scikit-learn.org),
and [Altair](https://altair-viz.github.io/); pandas and Matplotlib work just as
well. The full notebook is [`explore.py`](https://github.com/scttfrdmn/aws-marimo-sagemaker/blob/main/explore.py)
in the repo. Swap the S3 path for your own bucket — or any of the public
datasets on the [AWS Open Data Registry](https://registry.opendata.aws/) — and
you're off.*
