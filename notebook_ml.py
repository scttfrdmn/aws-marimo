"""
marimo on SageMaker — a complete, reactive ML workflow.

Interactive data exploration, model training with live hyperparameters, and a
peek at the SageMaker API — every cell updates on its own when you change a
control.

Dependencies (beyond marimo):
    pip install pandas numpy scikit-learn plotly boto3

Run it via the bridge (see the repo README):
    pip install pandas numpy scikit-learn plotly boto3
    bash start-marimo.sh notebook_ml.py

Note: cells whose *output* is the point (controls, tables, plots, prose) use
hide_code=True so the interactive surface stands out; the training cell is left
visible because it's the part worth reading. Code is a click away via the ⋯ menu.
"""

import marimo

__generated_with = "0.23.13"
app = marimo.App(width="full")


@app.cell(hide_code=True)
def _():
    import marimo as mo
    import pandas as pd
    import numpy as np
    import boto3
    import plotly.express as px
    import plotly.graph_objects as go
    from sklearn.model_selection import train_test_split
    from sklearn.ensemble import RandomForestClassifier
    from sklearn.metrics import confusion_matrix
    from datetime import datetime, timedelta
    import json
    return (
        RandomForestClassifier,
        boto3,
        confusion_matrix,
        go,
        mo,
        np,
        pd,
        px,
        train_test_split,
    )


@app.cell(hide_code=True)
def _(mo):
    mo.md("""
    # 🚀 marimo on Amazon SageMaker: Interactive ML Workflow

    This notebook demonstrates marimo's reactive capabilities integrated with AWS SageMaker.
    All cells automatically update when you interact with the controls below!

    ## 📊 Part 1: Reactive Data Exploration
    """)
    return


@app.cell(hide_code=True)
def _(np, pd):
    # Generate synthetic dataset
    np.random.seed(42)
    n_samples = 1000

    data = pd.DataFrame({
        'feature_1': np.random.randn(n_samples),
        'feature_2': np.random.randn(n_samples),
        'feature_3': np.random.randn(n_samples),
        'feature_4': np.random.randn(n_samples),
        'age': np.random.randint(18, 80, n_samples),
        'income': np.random.randint(20000, 150000, n_samples),
        'score': np.random.uniform(0, 100, n_samples),
    })

    # Create target variable with some logic
    data['target'] = (
        (data['feature_1'] + data['feature_2'] > 0) &
        (data['score'] > 50)
    ).astype(int)

    data
    return (data,)


@app.cell(hide_code=True)
def _(data, mo):
    # Interactive controls for data exploration
    mo.md("### 🎛️ Interactive Data Filters")

    # Age range slider
    age_range = mo.ui.range_slider(
        start=data['age'].min(),
        stop=data['age'].max(),
        value=[25, 65],
        label="Age Range",
        show_value=True
    )

    # Income threshold slider
    income_threshold = mo.ui.slider(
        start=int(data['income'].min()),
        stop=int(data['income'].max()),
        value=int(data['income'].median()),
        label="Minimum Income ($)",
        show_value=True
    )

    # Score threshold
    score_threshold = mo.ui.slider(
        start=0,
        stop=100,
        value=50,
        label="Minimum Score",
        show_value=True
    )

    # Feature selector
    feature_selector = mo.ui.multiselect(
        options=['feature_1', 'feature_2', 'feature_3', 'feature_4', 'age', 'income', 'score'],
        value=['feature_1', 'feature_2', 'age', 'income'],
        label="Select Features for Analysis"
    )

    mo.vstack([
        mo.hstack([age_range, income_threshold], justify="start"),
        mo.hstack([score_threshold, feature_selector], justify="start")
    ])
    return age_range, feature_selector, income_threshold, score_threshold


@app.cell(hide_code=True)
def _(age_range, data, income_threshold, mo, score_threshold):
    # Filter data based on interactive controls
    # This cell automatically re-executes when sliders change!
    filtered_data = data[
        (data['age'] >= age_range.value[0]) &
        (data['age'] <= age_range.value[1]) &
        (data['income'] >= income_threshold.value) &
        (data['score'] >= score_threshold.value)
    ]

    mo.md(f"""
    ### 📈 Filtered Dataset Statistics

    - **Total samples**: {len(data):,}
    - **Filtered samples**: {len(filtered_data):,} ({len(filtered_data)/len(data)*100:.1f}%)
    - **Positive class**: {filtered_data['target'].sum()} ({filtered_data['target'].mean()*100:.1f}%)
    - **Average age**: {filtered_data['age'].mean():.1f} years
    - **Average income**: ${filtered_data['income'].mean():,.0f}
    """)
    return (filtered_data,)


@app.cell(hide_code=True)
def _(filtered_data, mo):
    # Interactive table - automatically updates with filtered data
    mo.ui.table(
        filtered_data.head(20),
        selection='multi',
        pagination=True,
        page_size=10
    )
    return


@app.cell(hide_code=True)
def _(filtered_data, go, mo, px):
    # Visualizations - automatically update when data changes
    mo.md("### 📊 Interactive Visualizations")

    # Create scatter plot
    fig_scatter = px.scatter(
        filtered_data,
        x='feature_1',
        y='feature_2',
        color='target',
        size='score',
        hover_data=['age', 'income'],
        title='Feature Space (automatically updates!)',
        color_continuous_scale='viridis'
    )

    # Create distribution plot
    fig_dist = go.Figure()
    fig_dist.add_trace(go.Histogram(
        x=filtered_data[filtered_data['target'] == 0]['score'],
        name='Class 0',
        opacity=0.7
    ))
    fig_dist.add_trace(go.Histogram(
        x=filtered_data[filtered_data['target'] == 1]['score'],
        name='Class 1',
        opacity=0.7
    ))
    fig_dist.update_layout(
        title='Score Distribution by Class',
        barmode='overlay',
        xaxis_title='Score',
        yaxis_title='Count'
    )

    mo.hstack([
        mo.ui.plotly(fig_scatter),
        mo.ui.plotly(fig_dist)
    ])
    return


@app.cell(hide_code=True)
def _(mo):
    mo.md("""
    ## 🤖 Part 2: Model Training with Reactive Parameters

    Adjust the model parameters below and watch the results update automatically!
    """)
    return


@app.cell(hide_code=True)
def _(mo):
    # Model hyperparameters
    n_estimators_slider = mo.ui.slider(
        start=10,
        stop=200,
        step=10,
        value=100,
        label="Number of Trees",
        show_value=True
    )

    max_depth_slider = mo.ui.slider(
        start=2,
        stop=20,
        value=10,
        label="Max Depth",
        show_value=True
    )

    test_size_slider = mo.ui.slider(
        start=0.1,
        stop=0.4,
        step=0.05,
        value=0.2,
        label="Test Set Size",
        show_value=True
    )

    mo.vstack([
        mo.md("### 🎛️ Model Hyperparameters"),
        n_estimators_slider,
        max_depth_slider,
        test_size_slider
    ])
    return max_depth_slider, n_estimators_slider, test_size_slider


@app.cell
def _(
    RandomForestClassifier,
    feature_selector,
    filtered_data,
    max_depth_slider,
    n_estimators_slider,
    test_size_slider,
    train_test_split,
):
    # Train model - automatically retrains when parameters change!
    if len(filtered_data) > 50 and len(feature_selector.value) > 0:
        X = filtered_data[feature_selector.value]
        y = filtered_data['target']

        X_train, X_test, y_train, y_test = train_test_split(
            X, y,
            test_size=test_size_slider.value,
            random_state=42
        )

        model = RandomForestClassifier(
            n_estimators=n_estimators_slider.value,
            max_depth=max_depth_slider.value,
            random_state=42,
            n_jobs=-1
        )

        model.fit(X_train, y_train)
        train_score = model.score(X_train, y_train)
        test_score = model.score(X_test, y_test)
        predictions = model.predict(X_test)

        model_trained = True
    else:
        model_trained = False
        train_score = test_score = 0
        predictions = None
        y_test = None
        X_test = None
        model = None
    return model, model_trained, predictions, test_score, train_score, y_test


@app.cell(hide_code=True)
def _(mo, model_trained, test_score, train_score):
    # Display model performance — automatically updates.
    if model_trained:
        performance = mo.callout(
            mo.md(f"""
            ### 🎯 Model performance

            - **Training accuracy**: {train_score:.3f}
            - **Test accuracy**: {test_score:.3f}
            - **Gap (train − test)**: {train_score - test_score:.3f}

            {'✅ Good generalization!' if (train_score - test_score) < 0.1 else '⚠️ May be overfitting'}
            """),
            kind="success" if test_score > 0.75 else "warn",
        )
    else:
        performance = mo.callout(
            mo.md("⚠️ Need at least 50 samples and 1 feature to train a model."),
            kind="warn",
        )
    performance
    return


@app.cell(hide_code=True)
def _(confusion_matrix, go, mo, model_trained, predictions, y_test):
    # Confusion matrix visualization
    if model_trained:
        cm = confusion_matrix(y_test, predictions)

        fig_cm = go.Figure(data=go.Heatmap(
            z=cm,
            x=['Predicted 0', 'Predicted 1'],
            y=['Actual 0', 'Actual 1'],
            colorscale='Blues',
            text=cm,
            texttemplate='%{text}',
            textfont={"size": 20}
        ))

        fig_cm.update_layout(
            title='Confusion matrix (updates automatically)',
            xaxis_title='Predicted label',
            yaxis_title='True label'
        )

        cm_view = mo.ui.plotly(fig_cm)
    else:
        cm_view = None
    cm_view
    return


@app.cell(hide_code=True)
def _(feature_selector, go, mo, model, model_trained):
    # Feature importance - automatically updates!
    if model_trained:
        importance_df = {
            'feature': feature_selector.value,
            'importance': model.feature_importances_
        }

        fig_importance = go.Figure(data=[
            go.Bar(
                x=list(importance_df['feature']),
                y=list(importance_df['importance']),
                marker_color='lightblue'
            )
        ])

        fig_importance.update_layout(
            title='Feature importance (updates with model)',
            xaxis_title='Feature',
            yaxis_title='Importance'
        )

        importance_view = mo.ui.plotly(fig_importance)
    else:
        importance_view = None
    importance_view
    return


@app.cell(hide_code=True)
def _(mo):
    mo.md("""
    ## ☁️ Part 3: AWS SageMaker Integration

    Connect to SageMaker services to list training jobs, check endpoints, and more.
    """)
    return


@app.cell(hide_code=True)
def _(mo):
    # AWS Region selector
    region_selector = mo.ui.dropdown(
        options=['us-east-1', 'us-west-2', 'eu-west-1', 'ap-southeast-1'],
        value='us-east-1',
        label="AWS Region"
    )

    mo.hstack([
        mo.md("### Select AWS Region:"),
        region_selector
    ])
    return (region_selector,)


@app.cell(hide_code=True)
def _(boto3, region_selector):
    # Initialize AWS clients - automatically updates when region changes!
    try:
        sagemaker_client = boto3.client('sagemaker', region_name=region_selector.value)
        s3_client = boto3.client('s3', region_name=region_selector.value)
        aws_connected = True
    except Exception as e:
        aws_connected = False
        connection_error = str(e)
    return aws_connected, sagemaker_client


@app.cell(hide_code=True)
def _(aws_connected, mo, pd, sagemaker_client):
    # List recent SageMaker training jobs — a real API call when creds are present.
    if not aws_connected:
        jobs_view = mo.callout(
            mo.md("""
            ⚠️ **AWS credentials required**

            To reach SageMaker, this space needs credentials — normally the
            space's IAM role provides them automatically.
            """),
            kind="info",
        )
    else:
        try:
            response = sagemaker_client.list_training_jobs(
                MaxResults=10, SortBy='CreationTime', SortOrder='Descending'
            )
            summaries = response['TrainingJobSummaries']
            if summaries:
                jobs_df = pd.DataFrame([
                    {
                        'Job name': job['TrainingJobName'],
                        'Status': job['TrainingJobStatus'],
                        'Created': job['CreationTime'].strftime('%Y-%m-%d %H:%M'),
                    }
                    for job in summaries
                ])
                jobs_view = mo.vstack([
                    mo.md("### 📋 Recent SageMaker training jobs"),
                    mo.ui.table(jobs_df, selection=None),
                ])
            else:
                jobs_view = mo.callout(
                    mo.md("No training jobs found in this region."), kind="info"
                )
        except Exception as e:  # noqa: BLE001
            jobs_view = mo.callout(
                mo.md(f"⚠️ Couldn't fetch training jobs: {e}"), kind="warn"
            )
    jobs_view
    return


@app.cell(hide_code=True)
def _(mo):
    mo.md("""
    ## 🎓 Key Takeaways

    This notebook demonstrated:

    1. **Reactive Execution**: All cells automatically update when you change inputs
    2. **Interactive Widgets**: Sliders, selectors, and more with no callbacks needed
    3. **Real-time Visualizations**: Plots that update instantly with your data
    4. **ML Workflow**: Complete training pipeline with hyperparameter tuning
    5. **AWS Integration**: Connect to SageMaker services seamlessly

    ## 🚀 Next Steps

    - Save this notebook: It's just a Python file!
    - Run as a script: `python notebook_ml.py`
    - Deploy as a web app: `marimo run notebook_ml.py`
    - Version control: `git add notebook_ml.py && git commit -m "Add ML demo"`

    ---

    **Try modifying the sliders above and watch everything update automatically!**
    This is the power of reactive notebooks. 🎉
    """)
    return


@app.cell(hide_code=True)
def _(mo):
    mo.md(r"""
 
    """)
    return


if __name__ == "__main__":
    app.run()
