# Badge Options for AWS SageMaker Studio Lab

## Option 1: Bootstrap Badge (Recommended for marimo)

Since marimo uses `.py` files (not `.ipynb`), create a custom badge that links to setup instructions:

### Using Shields.io (Clickable)
```markdown
[![Setup on Studio Lab](https://img.shields.io/badge/Setup_on-SageMaker_Studio_Lab-orange?logo=amazon-aws&logoColor=white)](https://github.com/YOUR_USERNAME/aws-marimo#one-command-setup)
```

[![Setup on Studio Lab](https://img.shields.io/badge/Setup_on-SageMaker_Studio_Lab-orange?logo=amazon-aws&logoColor=white)](#)

### Alternative: Direct Bootstrap Link
```markdown
[![One-Command Setup](https://img.shields.io/badge/One--Command-Setup-success?logo=amazon-aws)](https://github.com/YOUR_USERNAME/aws-marimo/blob/main/BOOTSTRAP.md)
```

[![One-Command Setup](https://img.shields.io/badge/One--Command-Setup-success?logo=amazon-aws)](#)

## Option 2: Official AWS Badge (For Jupyter Notebooks Only)

If you convert marimo to .ipynb for demo purposes:

```markdown
[![Open In Studio Lab](https://studiolab.sagemaker.aws/studiolab.svg)](https://studiolab.sagemaker.aws/import/github/YOUR_USERNAME/aws-marimo/blob/main/demo.ipynb)
```

**Note**: This only works for `.ipynb` files, not `.py` files.

## Option 3: Combined Badge Set

Show multiple options:

```markdown
<!-- For Studio Lab Users -->
[![Setup on Studio Lab](https://img.shields.io/badge/Setup_on-Studio_Lab-orange?logo=amazon-aws&logoColor=white)](https://github.com/YOUR_USERNAME/aws-marimo/blob/main/BOOTSTRAP.md)
[![Open Demo](https://img.shields.io/badge/Try-marimo_Demo-blue?logo=python&logoColor=white)](https://github.com/YOUR_USERNAME/aws-marimo/blob/main/sagemaker_ml_demo.py)

<!-- General Badges -->
[![Python](https://img.shields.io/badge/Python-3.9+-blue?logo=python&logoColor=white)](https://www.python.org)
[![marimo](https://img.shields.io/badge/marimo-latest-green)](https://marimo.io)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
```

## Option 4: Step-by-Step Badge

Create a badge that links to QUICKSTART:

```markdown
[![5-Minute Setup](https://img.shields.io/badge/⚡_5--Minute-Setup_Guide-brightgreen)](https://github.com/YOUR_USERNAME/aws-marimo/blob/main/QUICKSTART.md)
```

[![5-Minute Setup](https://img.shields.io/badge/⚡_5--Minute-Setup_Guide-brightgreen)](#)

## Recommended README Layout

```markdown
# marimo on AWS SageMaker

Run reactive Python notebooks on AWS infrastructure

[![Setup on Studio Lab](https://img.shields.io/badge/Setup_on-Studio_Lab-orange?logo=amazon-aws&logoColor=white)](https://github.com/YOUR_USERNAME/aws-marimo/blob/main/BOOTSTRAP.md)
[![5-Minute Setup](https://img.shields.io/badge/⚡_5--Minute-Setup_Guide-brightgreen)](https://github.com/YOUR_USERNAME/aws-marimo/blob/main/QUICKSTART.md)
[![Python](https://img.shields.io/badge/Python-3.9+-blue?logo=python&logoColor=white)](https://www.python.org)
[![marimo](https://img.shields.io/badge/marimo-latest-green)](https://marimo.io)

## One-Command Setup

For SageMaker Studio Lab users:
```bash
curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/aws-marimo/main/bootstrap.sh | bash
```

[Full Documentation →](BOOTSTRAP.md)
```

## Custom Badge with Logo

If you want a badge that looks like the official AWS one:

```markdown
[![AWS](https://img.shields.io/badge/AWS-SageMaker_Studio_Lab-FF9900?style=for-the-badge&logo=amazon-aws&logoColor=white)](https://studiolab.sagemaker.aws)
```

[![AWS](https://img.shields.io/badge/AWS-SageMaker_Studio_Lab-FF9900?style=for-the-badge&logo=amazon-aws&logoColor=white)](#)

## Interactive "Try It" Section

Create a visual section in your README:

```markdown
## 🚀 Try marimo on Studio Lab

| Option | Description | Time |
|--------|-------------|------|
| [![Bootstrap](https://img.shields.io/badge/One--Command-Bootstrap-success)](BOOTSTRAP.md) | Fully automated setup from GitHub | 2 min |
| [![Manual](https://img.shields.io/badge/Manual-Setup-blue)](QUICKSTART.md) | Step-by-step installation | 5 min |
| [![Local](https://img.shields.io/badge/Run-Locally-lightgrey)](#local-setup) | Run on your machine | 1 min |
```

## Adding the Tag

Don't forget to add the official tag to your repo:
- **Tag**: `amazon-sagemaker-lab`
- AWS will discover popular repos and may feature them!

## Shields.io Customization

Build your own at: https://shields.io/badges

Example options:
- `style`: `flat`, `flat-square`, `for-the-badge`, `plastic`, `social`
- `logo`: `amazon-aws`, `python`, `jupyter`
- `logoColor`: `white`, `orange`, etc.
- `color`: Any hex code or name

## Why Custom Badges for marimo?

1. **Official badge requires .ipynb**: marimo uses `.py` files
2. **Setup is different**: Not just "open notebook", need conda env
3. **Bootstrap is better**: One command vs manual steps
4. **Clear expectations**: Users know what they're getting into

## For Maximum Visibility

Use all three in your README:
1. **Setup badge** → Links to BOOTSTRAP.md
2. **Quick start badge** → Links to QUICKSTART.md
3. **Official AWS badge** → Links to Studio Lab homepage

This covers all user types: power users (bootstrap), beginners (quickstart), and curious visitors (Studio Lab info).
