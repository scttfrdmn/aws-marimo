# marimo on Amazon SageMaker

Run [marimo](https://marimo.io), the reactive Python notebook, on Amazon SageMaker Studio and Studio Lab.

[![Setup on Studio Lab](https://img.shields.io/badge/Setup_on-SageMaker_Studio_Lab-orange?logo=amazon-aws&logoColor=white)](BOOTSTRAP.md)
[![5-Minute Setup](https://img.shields.io/badge/⚡_5--Minute-Setup_Guide-brightgreen)](QUICKSTART.md)
[![Python](https://img.shields.io/badge/Python-3.9+-blue?logo=python&logoColor=white)](https://www.python.org)
[![marimo](https://img.shields.io/badge/marimo-0.17.6+-green?logo=python)](https://marimo.io)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Version](https://img.shields.io/badge/version-0.1.0-blue)](VERSION)

---

## ⚡ One-Command Setup

For SageMaker Studio Lab (free, no AWS account required):

```bash
curl -fsSL https://raw.githubusercontent.com/scttfrdmn/aws-marimo/main/bootstrap.sh | bash
```

**Then start marimo:**
```bash
~/start-marimo.sh
```

[📖 Full Bootstrap Guide](BOOTSTRAP.md) | [⚙️ Manual Setup](QUICKSTART.md)

---

## 🚀 Quick Start (5 Minutes)

**Want to try marimo right now?**

👉 **[Start with the Quick Start Guide](QUICKSTART.md)** - Get marimo running in 5 minutes on SageMaker Studio Lab (free!) or Studio.

## 📚 What's Included

This repository provides:

1. **📖 [Complete Blog Post](blog-post.md)** (~2000 words)
   - Deep dive into marimo's features
   - Why use marimo on SageMaker
   - Architecture overview
   - Deployment strategies
   - Best practices and troubleshooting

2. **⚡ [Quick Start Guide](QUICKSTART.md)**
   - 5-minute setup for Studio Lab (free)
   - Easy installation for Studio
   - Sample notebooks
   - Troubleshooting tips

3. **🔧 Infrastructure as Code**
   - `terraform/` - Complete Terraform deployment
   - `cdk/` - AWS CDK (Python) deployment
   - Lifecycle configurations
   - Sample notebooks

4. **🎓 [Demo Notebook](sagemaker_ml_demo.py)**
   - Complete ML workflow
   - Interactive data exploration
   - Model training with reactive parameters
   - SageMaker integration examples

## 🎯 Choose Your Path

### Path 1: Just Try It (Fastest)
**Perfect for**: Learning, experimenting, quick demos

1. Get free SageMaker Studio Lab account
2. Follow [QUICKSTART.md](QUICKSTART.md)
3. Try the sample notebook
4. Total time: ~10 minutes

### Path 2: Manual Setup on Studio
**Perfect for**: Individual users, existing Studio environment

1. Open SageMaker Studio
2. Run `pip install marimo jupyter-server-proxy`
3. Start with `marimo edit`
4. See [QUICKSTART.md](QUICKSTART.md) for details

### Path 3: Production Deployment
**Perfect for**: Teams, production workloads, persistent setup

1. Read the [blog post](blog-post.md) for architecture understanding
2. Choose Terraform or CDK
3. Deploy with one command
4. Get automated, persistent marimo installation

## 💡 Why marimo?

Traditional Jupyter notebooks have well-known issues:
- ❌ Hidden state from out-of-order execution
- ❌ JSON format causes Git conflicts
- ❌ ~75% of notebooks on GitHub don't run
- ❌ Hard to reproduce research

**marimo solves these problems:**
- ✅ Reactive execution - cells auto-update when dependencies change
- ✅ Stored as pure Python - Git-friendly, executable as scripts
- ✅ No hidden state - deterministic, reproducible
- ✅ Interactive UI widgets - no callbacks needed
- ✅ Three tools in one - notebook, script, and web app

## 🏗️ Architecture

```
┌─────────────────────────────────────┐
│   SageMaker Studio / Studio Lab     │
│  ┌───────────────────────────────┐  │
│  │  JupyterLab Environment       │  │
│  │  ┌─────────────────────────┐  │  │
│  │  │ jupyter-server-proxy    │  │  │
│  │  │         ↓                │  │  │
│  │  │ marimo server (:8888)   │  │  │
│  │  └─────────────────────────┘  │  │
│  └───────────────────────────────┘  │
└─────────────────────────────────────┘
```

## 📦 Repository Structure

```
.
├── README.md                    # This file
├── QUICKSTART.md               # 5-minute setup guide
├── BOOTSTRAP.md                # One-command bootstrap guide
├── STUDIO-LAB-SETUP.md         # Automated Studio Lab setup
├── BADGES.md                   # Badge options for READMEs
├── CONTRIBUTING.md             # Contribution guidelines
├── CHANGELOG.md                # Version history (Keep a Changelog)
├── LICENSE                     # MIT License
├── VERSION                     # Semantic version (0.1.0)
├── blog-post.md                # Full blog post (~2000 words)
├── chat.md                     # Research notes
├── sagemaker_ml_demo.py        # Complete demo notebook
├── bootstrap.sh                # One-command setup script
├── studio-lab-setup.sh         # Setup script with conda env
├── terraform/                  # Terraform IaC (coming soon)
├── cdk/                        # AWS CDK IaC (coming soon)
└── notebooks/                  # Sample notebooks (coming soon)
```

## 🎓 Sample Notebooks

### Quick Demo
```python
import marimo as mo

# Interactive slider
slider = mo.ui.slider(0, 100, value=50)

# Automatically updates when slider changes!
result = slider.value ** 2
mo.md(f"Value: {slider.value}, Squared: {result}")
```

### SageMaker Integration
```python
import marimo as mo
import boto3

sagemaker = boto3.client('sagemaker')

# List training jobs
jobs = sagemaker.list_training_jobs(MaxResults=10)

# Interactive table
mo.ui.table(jobs['TrainingJobSummaries'])
```

See [sagemaker_ml_demo.py](sagemaker_ml_demo.py) for a complete, production-ready example.

## 🚢 Deployment Options

### Option 1: Terraform

```bash
cd terraform
terraform init
terraform apply
```

Creates:
- SageMaker Studio Domain
- VPC and security groups
- IAM roles
- Lifecycle configuration for marimo
- S3 bucket for artifacts

### Option 2: AWS CDK

```bash
cd cdk
pip install -r requirements.txt
cdk deploy
```

Same infrastructure as Terraform, using Python CDK constructs.

### Option 3: Manual (Quickest)

See [QUICKSTART.md](QUICKSTART.md) - just `pip install marimo` and go!

## 💰 Cost Comparison

| Option | Cost | Best For |
|--------|------|----------|
| **Studio Lab** | **$0** (100% free) | Learning, small projects |
| **Studio (manual)** | ~$0.05-2/hour | Individual use, testing |
| **Studio (IaC)** | ~$1-5/hour | Teams, production |

marimo's lightweight architecture means minimal overhead costs.

## 🔧 Maintenance

### Updating marimo

**Studio Lab / Manual:**
```bash
pip install --upgrade marimo
```

**With Lifecycle Config:**
Update the version in `install-marimo.sh` and redeploy lifecycle configuration.

### Cleanup

**Terraform:**
```bash
terraform destroy
```

**CDK:**
```bash
cdk destroy
```

**Manual:**
Just stop using it - no infrastructure to clean up!

## 📖 Documentation

- **Quick Start**: [QUICKSTART.md](QUICKSTART.md) - Get running in 5 minutes
- **Blog Post**: [blog-post.md](blog-post.md) - Comprehensive guide (~2000 words)
- **Demo Notebook**: [sagemaker_ml_demo.py](sagemaker_ml_demo.py) - Complete working example
- **marimo docs**: https://docs.marimo.io
- **SageMaker docs**: https://docs.aws.amazon.com/sagemaker/

## 🤝 Use Cases

marimo on SageMaker is perfect for:

- 🔬 **Reproducible Research** - Pure Python format, no hidden state
- 👥 **Team Collaboration** - Git-friendly, version-controlled notebooks
- 📊 **Interactive Dashboards** - Reactive UI updates, deploy as web apps
- 🚀 **MLOps Pipelines** - Run notebooks as scripts in CI/CD
- 🎓 **Teaching & Demos** - Predictable execution, professional output
- 🔍 **Data Exploration** - Interactive filtering and visualization

## 🆚 marimo vs Jupyter

**When to use marimo:**
- ✅ Building dashboards or interactive apps
- ✅ Need reproducible, version-controlled research
- ✅ Want reactive, automatic updates
- ✅ Creating reusable modules or pipelines
- ✅ Teaching or presenting (no hidden state issues)

**When to use Jupyter:**
- ✅ Quick ad-hoc exploration
- ✅ Team heavily invested in Jupyter ecosystem
- ✅ Need specific Jupyter extensions

**Best practice:** Use both! Convert between formats as needed with `marimo convert`.

## ❓ Troubleshooting

Common issues and solutions are in [QUICKSTART.md](QUICKSTART.md#troubleshooting).

Quick fixes:
- **Can't access UI**: Check proxy URL path
- **Port in use**: Use different port (`--port 8889`)
- **Proxy not working**: Run `jupyter serverextension enable --py jupyter_server_proxy`

## 🎯 Next Steps

1. ✅ Try the [Quick Start](QUICKSTART.md) (5 minutes)
2. ✅ Read the [blog post](blog-post.md) for deep dive
3. ✅ Run the [demo notebook](sagemaker_ml_demo.py)
4. ✅ Convert your Jupyter notebooks: `marimo convert notebook.ipynb`
5. ✅ Deploy with infrastructure-as-code for production use

## 🌟 Features Showcase

### Reactive Execution
```python
# Change slider, everything updates automatically
slider = mo.ui.slider(0, 100)
filtered_data = data[data['value'] > slider.value]
plot = create_plot(filtered_data)  # Auto-updates!
```

### Git-Friendly
```bash
# Clean diffs, no JSON
git diff notebook.py

# Run as script
python notebook.py

# Deploy as app
marimo run notebook.py
```

### Interactive UI
```python
# No callbacks needed!
dropdown = mo.ui.dropdown(['A', 'B', 'C'])
table = mo.ui.table(dataframe)
plot = mo.ui.plotly(figure)
```

## 📝 Contributing

Found an issue or have an improvement? Contributions welcome!

1. Fork the repository
2. Create a feature branch
3. Submit a pull request

## 📄 License

This repository: Apache 2.0 License

marimo: Apache 2.0 License

## 🙏 Acknowledgments

- **marimo team** - for building an amazing reactive notebook platform
- **AWS SageMaker team** - for creating a flexible ML platform
- **Community** - for feedback and contributions

## 📬 Support

- **Issues**: Open an issue in this repository
- **marimo Discord**: https://marimo.io/discord
- **AWS Support**: https://aws.amazon.com/support/

---

## 📚 Documentation

- **[Quick Start Guide](QUICKSTART.md)** - Get running in 5 minutes
- **[Bootstrap Guide](BOOTSTRAP.md)** - One-command automated setup
- **[Studio Lab Setup](STUDIO-LAB-SETUP.md)** - Persistent conda environment
- **[Blog Post](blog-post.md)** - Complete guide (~2000 words)
- **[Badge Options](BADGES.md)** - Add badges to your own projects
- **[Contributing](CONTRIBUTING.md)** - How to contribute
- **[Changelog](CHANGELOG.md)** - Version history

## 📝 Project Info

- **Version**: 0.1.0 ([Semantic Versioning](https://semver.org/))
- **License**: [MIT](LICENSE)
- **Copyright**: © 2026 Scott Friedman
- **Changelog**: [Keep a Changelog](https://keepachangelog.com/) format

## 🤝 Contributing

Contributions are welcome! Please read [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

To contribute:
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

See [CHANGELOG.md](CHANGELOG.md) for version history.

---

**Ready to get started?**

👉 One command: `curl -fsSL https://raw.githubusercontent.com/scttfrdmn/aws-marimo/main/bootstrap.sh | bash`

👉 Or manual: [QUICKSTART.md](QUICKSTART.md)

👉 Deep dive: [Full blog post](blog-post.md)

Happy reactive coding! 🚀
