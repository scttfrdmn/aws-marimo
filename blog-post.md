# Running marimo: The Next-Generation Python Notebook on Amazon SageMaker

## Introduction

For over a decade, Jupyter notebooks have been the go-to tool for data scientists and machine learning practitioners. They've enabled interactive development, iterative experimentation, and rich documentation all in one place. But if you've worked with Jupyter notebooks in production, you've likely encountered their pain points: out-of-order execution leading to hidden state bugs, merge conflicts from JSON formatting, and the notorious "works on my machine" problem when notebooks fail to reproduce.

Enter **marimo**, an open-source reactive notebook that fundamentally reimagines how notebooks work. Unlike Jupyter, marimo notebooks are reactive—when you change a variable or cell, all dependent cells automatically update. They're stored as pure Python files, making them Git-friendly and executable as scripts. And they eliminate hidden state entirely, ensuring your notebooks are always in a consistent, reproducible state.

In this post, we'll show you how to run marimo on Amazon SageMaker Studio, combining the power of AWS's managed machine learning platform with marimo's modern notebook experience. We'll provide complete infrastructure-as-code deployments using both Terraform and AWS CDK, walk through practical examples, and show you when and how to use marimo alongside your existing Jupyter workflows.

By the end of this tutorial, you'll have a production-ready SageMaker environment with marimo support, and understand how reactive notebooks can improve your ML development workflow.

## What Makes marimo Different?

### The Problem with Traditional Notebooks

Research shows that approximately 75% of Jupyter notebooks on GitHub don't run, and 96% don't reproduce the claimed results. Why? The culprit is hidden state. In Jupyter, you can execute cells out of order, creating dependencies that aren't visible in the linear notebook structure. A notebook might appear to work, but when you restart the kernel and run from top to bottom, it fails.

Additionally, Jupyter notebooks are stored as JSON files containing outputs, metadata, and execution counts. This makes version control painful—merge conflicts are common, and diffs are nearly impossible to read. For teams practicing MLOps and requiring reproducible research, these limitations are significant obstacles.

### How marimo Solves These Problems

**1. Reactive Execution**

marimo uses a reactive programming model similar to spreadsheets or modern frontend frameworks. When you modify a cell, marimo automatically determines which cells depend on that change and re-executes them in the correct order. This eliminates hidden state and ensures your notebook is always in a consistent state.

```python
# In marimo, this automatically updates when slider changes
slider = mo.ui.slider(0, 100, value=50)
result = expensive_computation(slider.value)  # Auto-recomputes
mo.md(f"Result: {result}")  # Auto-updates display
```

**2. Stored as Pure Python**

marimo notebooks are saved as `.py` files with a simple, readable structure. This means:
- Clean Git diffs showing only code changes
- No merge conflicts from execution counts or outputs
- Execute notebooks as Python scripts: `python notebook.py`
- Import notebooks as modules in other projects
- Full compatibility with AI coding assistants like Claude Code and GitHub Copilot

**3. Three Tools in One**

A single marimo file can serve as:
- An interactive notebook for development
- A Python script that runs from the command line
- A web application deployed with `marimo run notebook.py`

This eliminates the need to maintain separate notebook and production code, a common source of bugs in ML projects.

**4. Built-in Interactivity**

marimo includes rich UI components that work without callbacks:
```python
import marimo as mo

# Create interactive elements
dropdown = mo.ui.dropdown(['model-a', 'model-b', 'model-c'])
table = mo.ui.table(dataframe)  # Interactive, sortable, filterable
plot = mo.ui.plotly(figure)  # Fully interactive visualizations
```

### Important: Python-Only Platform

Unlike Jupyter's multi-kernel architecture that supports R, Julia, Scala, and other languages, **marimo is exclusively a Python notebook platform**. This design choice enables marimo's deep Python integration—notebooks are pure `.py` files that can be executed as scripts, imported as modules, and work seamlessly with Python tooling.

If your workflow requires R, Julia, or other languages, you'll need to continue using Jupyter for those notebooks. However, for Python-focused ML and data science work (which represents the vast majority of SageMaker use cases), marimo's Python-native design provides significant advantages in reproducibility and developer experience.

The good news: marimo and Jupyter can coexist in the same SageMaker environment, so you can use marimo for Python workflows while keeping Jupyter available for multi-language projects.

## Why marimo on SageMaker?

Combining marimo with Amazon SageMaker gives you:

- **Managed Infrastructure**: No need to manage servers, Jupyter installations, or dependencies
- **Scalable Compute**: Access to GPUs, large memory instances, and distributed training
- **SageMaker Integration**: Direct access to SageMaker training jobs, endpoints, Feature Store, and Model Registry
- **Team Collaboration**: Shared environments with consistent configurations
- **Security and Compliance**: VPC isolation, IAM roles, and audit logging
- **Cost Optimization**: Pay only for compute you use, with automatic scaling

marimo's lightweight architecture makes it perfect for SageMaker—it runs efficiently on the JupyterServer instance without requiring expensive compute for the interface itself.

## Architecture Overview

Our deployment creates a complete SageMaker Studio environment with marimo support:

```
┌─────────────────────────────────────────────┐
│     SageMaker Studio Domain                 │
│  ┌───────────────────────────────────────┐  │
│  │  JupyterLab Environment               │  │
│  │  ┌─────────────────────────────────┐  │  │
│  │  │ jupyter-server-proxy            │  │  │
│  │  │         ↓                        │  │  │
│  │  │ marimo server (port 8888)       │  │  │
│  │  └─────────────────────────────────┘  │  │
│  └───────────────────────────────────────┘  │
│                                             │
│  Lifecycle Configuration:                   │
│  - Install marimo                           │
│  - Configure proxy                          │
│  - Setup helper scripts                     │
└─────────────────────────────────────────────┘
         │
         ├─→ S3 (notebooks, data, artifacts)
         ├─→ VPC (secure networking)
         └─→ IAM (permissions)
```

**Key Components:**

1. **SageMaker Studio Domain**: Your team's workspace with user profiles and shared settings
2. **Lifecycle Configuration**: Automatically installs marimo and jupyter-server-proxy when JupyterServer starts
3. **jupyter-server-proxy**: Enables accessing marimo's web UI through SageMaker's proxy system
4. **VPC Configuration**: Secure networking with private subnets and security groups
5. **IAM Roles**: Appropriate permissions for SageMaker operations and AWS service access

## Deployment

We provide two deployment options: Terraform and AWS CDK. Both create identical infrastructure—choose based on your team's preferences.

### Option 1: Terraform Deployment

```bash
cd terraform
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

This creates:
- SageMaker Studio Domain and user profile
- VPC with public and private subnets
- Security groups with appropriate rules
- IAM execution role with necessary permissions
- Lifecycle configuration for marimo installation
- S3 bucket for artifacts and sample notebooks

After deployment, Terraform outputs the Studio domain URL and other useful information.

### Option 2: AWS CDK Deployment

```bash
cd cdk
python -m venv .venv
source .venv/bin/activate  # On Windows: .venv\Scripts\activate
pip install -r requirements.txt
cdk deploy
```

The CDK stack provides the same infrastructure with the added benefit of type checking and the ability to easily extend with additional AWS constructs.

## Getting Started with marimo on SageMaker

### Step 1: Access SageMaker Studio

After deployment, navigate to the SageMaker Console and open Studio using the domain URL from your deployment outputs. When JupyterServer starts, the lifecycle configuration automatically installs marimo and configures the proxy.

### Step 2: Start the marimo Server

Open a terminal in JupyterLab and run:

```bash
./start-marimo.sh
```

This helper script (created by the lifecycle configuration) starts the marimo server on port 8888.

### Step 3: Access the marimo UI

Navigate to:
```
https://<your-domain>.studio.<region>.sagemaker.aws/jupyter/default/proxy/8888/
```

You'll see the marimo editor interface, ready to create or open notebooks.

### Step 4: Create Your First Notebook

In the terminal:
```bash
cd marimo-notebooks
marimo edit my_analysis.py
```

Or create a new notebook from the marimo UI.

## Practical Examples

### Example 1: Interactive Data Exploration

One of marimo's killer features is effortless interactivity. Here's a complete example that lets you filter and visualize data reactively:

```python
import marimo as mo
import pandas as pd
import plotly.express as px

# Load sample data
df = pd.read_csv('s3://your-bucket/data.csv')

# Create interactive filter
min_value = mo.ui.slider(
    start=df['price'].min(),
    stop=df['price'].max(),
    value=df['price'].median(),
    label="Minimum Price"
)

# Filter data (automatically updates when slider changes)
filtered_df = df[df['price'] >= min_value.value]

# Display results
mo.md(f"Showing {len(filtered_df)} of {len(df)} items")
mo.ui.table(filtered_df)

# Plot (automatically updates)
fig = px.histogram(filtered_df, x='price', nbins=50)
mo.ui.plotly(fig)
```

When you move the slider, everything updates automatically—the filtered dataframe, the count, the table, and the plot. No callbacks, no manual re-execution needed.

### Example 2: SageMaker Training Job Monitor

marimo integrates seamlessly with AWS services. Here's a reactive dashboard for monitoring SageMaker training jobs:

```python
import marimo as mo
import boto3
import pandas as pd
from datetime import datetime

# Initialize SageMaker client
sagemaker = boto3.client('sagemaker')

# List training jobs
response = sagemaker.list_training_jobs(MaxResults=20)
job_names = [job['TrainingJobName'] for job in response['TrainingJobSummaries']]

# Interactive job selector
selected_job = mo.ui.dropdown(
    options=job_names,
    value=job_names[0] if job_names else None,
    label="Select Training Job"
)

# Get job details (automatically updates when selection changes)
if selected_job.value:
    job_details = sagemaker.describe_training_job(
        TrainingJobName=selected_job.value
    )

    # Display key metrics
    mo.md(f"""
    ## Training Job: {selected_job.value}

    - **Status**: {job_details['TrainingJobStatus']}
    - **Instance Type**: {job_details['ResourceConfig']['InstanceType']}
    - **Instance Count**: {job_details['ResourceConfig']['InstanceCount']}
    - **Training Time**: {job_details.get('TrainingTimeInSeconds', 0)} seconds
    """)

    # Show hyperparameters
    mo.ui.table(pd.DataFrame([job_details['HyperParameters']]))
```

### Example 3: Converting Existing Jupyter Notebooks

Already have Jupyter notebooks? Convert them to marimo:

```bash
marimo convert analysis.ipynb -o analysis.py
```

marimo does its best to handle the conversion, and you can then refine the reactive structure.

## marimo vs. Jupyter: When to Use Each

Both tools have their place in your ML workflow:

**Use marimo when:**
- ✅ Building interactive dashboards and applications
- ✅ Creating reproducible research that must run top-to-bottom
- ✅ Working collaboratively with Git version control
- ✅ Creating reusable modules or production pipelines
- ✅ You want reactive, automatic updates
- ✅ Sharing notebooks that others need to run reliably

**Use Jupyter when:**
- ✅ Doing quick, ad-hoc exploration
- ✅ Using SageMaker-specific notebook features
- ✅ Your team has heavy investment in Jupyter extensions
- ✅ You need specific Jupyter widgets or integrations
- ✅ Experimenting where order of execution doesn't matter

**Best practice**: Use both! Each has strengths, and you can convert between formats as needed.

## Best Practices

### 1. Version Control

Because marimo notebooks are Python files, version control is straightforward:

```bash
git add my_notebook.py
git commit -m "Add data analysis notebook"
git push
```

Git diffs show exactly what changed in your code, not JSON metadata.

### 2. Team Deployment

Use lifecycle configurations to ensure all team members have consistent environments:

```bash
#!/bin/bash
pip install marimo==0.9.0  # Pin specific version
pip install jupyter-server-proxy
# Install team-specific packages
pip install -r /home/sagemaker-user/requirements.txt
```

### 3. Resource Management

marimo's server runs on JupyterServer (system instance, minimal cost). Heavy computation should use:
- Kernel Gateway instances (for interactive work)
- SageMaker Training Jobs (for large-scale training)
- SageMaker Processing Jobs (for data processing)

This separation keeps costs down while providing access to powerful compute when needed.

### 4. Running as Scripts

marimo notebooks can execute as Python scripts in CI/CD pipelines:

```yaml
# GitHub Actions
- name: Test notebooks
  run: |
    python analysis.py
    python training_pipeline.py
```

This ensures your notebooks stay executable and reproducible.

## Cost Considerations

Running marimo on SageMaker is cost-effective:

- **JupyterServer**: ~$0.05/hour (system instance type)
- **Kernel Gateway**: Varies by instance type (ml.t3.medium ~$0.05/hour, GPU instances more)
- **S3 Storage**: Standard S3 pricing (~$0.023/GB/month)
- **Data Transfer**: Minimal within same region

marimo's lightweight architecture means you're not paying for heavy notebook infrastructure—just the compute you actually need.

## Troubleshooting

**Issue: Can't access marimo UI**
```bash
# Verify jupyter-server-proxy is enabled
jupyter serverextension list
# Should show jupyter_server_proxy enabled and validated
```

**Issue: Lifecycle configuration didn't run**
- Check CloudWatch logs at `/aws/sagemaker/studio`
- Verify IAM permissions allow lifecycle config execution
- Ensure lifecycle config is attached to user profile

**Issue: Packages missing**
```bash
# Install in JupyterServer terminal
pip install package-name
# Or add to lifecycle configuration for permanent installation
```

## Conclusion

marimo brings modern reactive programming to Amazon SageMaker, enabling truly reproducible notebooks that integrate seamlessly with AWS's ML platform. By combining marimo's reactive execution, Git-friendly format, and built-in interactivity with SageMaker's managed infrastructure and powerful compute, you get the best of both worlds: rapid interactive development and production-ready, reproducible code.

Whether you're exploring data, training models, or building ML pipelines, this combination provides powerful tools for every stage of the ML lifecycle. The reactive model eliminates hidden state bugs, the Python file format enables proper version control, and the SageMaker integration gives you access to scalable compute and managed services.

### Next Steps

1. **Deploy**: Use the provided Terraform or CDK code to set up your environment
2. **Experiment**: Try the sample notebooks and convert an existing Jupyter notebook
3. **Integrate**: Connect marimo notebooks with your SageMaker training jobs and endpoints
4. **Share**: Commit your marimo notebooks to Git and share with your team
5. **Explore**: Check out marimo's documentation for advanced features

### Resources

- **marimo Documentation**: https://docs.marimo.io
- **marimo GitHub**: https://github.com/marimo-team/marimo
- **SageMaker Studio Guide**: https://docs.aws.amazon.com/sagemaker/latest/dg/studio.html
- **Sample Code Repository**: [Your GitHub repo with Terraform/CDK code]

### Cleanup

When you're done experimenting, clean up resources to avoid charges:

```bash
# Terraform
terraform destroy

# CDK
cdk destroy
```

The future of notebooks is reactive, reproducible, and Git-friendly. With marimo on SageMaker, that future is available today. Happy coding!

---

*About the Author: [Your bio here]*

*Special thanks to the marimo team for building an amazing tool, and to the AWS SageMaker team for creating such a flexible ML platform.*
