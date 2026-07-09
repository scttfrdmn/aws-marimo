# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.1] - 2026-07-08

**Final SageMaker Studio Lab release.** AWS is closing Studio Lab to new
customers on 2026-07-30, so this is the last version targeting it. Development
continues in v0.2.0, which drops Studio Lab and focuses on full SageMaker
Studio (JupyterLab). See the
[Studio Lab availability change](https://docs.aws.amazon.com/sagemaker/latest/dg/studio-lab-availability-change.html).

### Fixed
- Corrected stale `aws-marimo` repository/directory references to
  `aws-marimo-sagemaker` across all scripts and docs (the mismatch broke the
  auto-update logic in `~/start-marimo.sh`, which looked for a directory
  `bootstrap.sh` never created)
- Replaced `YOUR_USERNAME` placeholders with `scttfrdmn` in this project's own
  setup instructions and badges (kept as placeholders only in the fork/clone
  guidance where they belong)
- Removed a hard-coded personal Studio Lab domain from `fix-proxy.sh`

### Changed
- Marked the Terraform, CDK, and `notebooks/` infrastructure-as-code as planned
  (not yet shipped) in README and blog-post, instead of documenting them as if
  they were available

## [0.1.0] - 2026-01-14

### Added
- Complete marimo ML workflow demo (`sagemaker_ml_demo.py`)
- SageMaker Studio Lab automated setup scripts
- One-command bootstrap from GitHub (`bootstrap.sh`)
- Studio Lab setup with conda environment (`studio-lab-setup.sh`)
- Auto-updating start script
- Quick start guide (`QUICKSTART.md`)
- Comprehensive blog post (`blog-post.md`)
- Bootstrap documentation (`BOOTSTRAP.md`)
- Badge options guide (`BADGES.md`)
- Studio Lab setup guide (`STUDIO-LAB-SETUP.md`)
- Demo notebook with reactive visualizations
- Support for Python 3.9+
- Dependencies: marimo, pandas, numpy, boto3, plotly, scikit-learn

### Documentation
- Added Python-only platform clarification in blog post
- Installation instructions for both Studio Lab and Studio
- Troubleshooting sections
- Comparison tables (Studio Lab vs Studio)

[unreleased]: https://github.com/scttfrdmn/aws-marimo-sagemaker/compare/v0.1.1...HEAD
[0.1.1]: https://github.com/scttfrdmn/aws-marimo-sagemaker/compare/v0.1.0...v0.1.1
[0.1.0]: https://github.com/scttfrdmn/aws-marimo-sagemaker/releases/tag/v0.1.0
