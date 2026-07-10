# Contributing to aws-marimo-sagemaker

Thank you for your interest in contributing to aws-marimo-sagemaker! This document provides guidelines for contributing to the project.

## Code of Conduct

Be respectful, inclusive, and considerate in all interactions.

## How to Contribute

### Reporting Bugs

If you find a bug, please open an issue with:
- Clear description of the problem
- Steps to reproduce
- Expected vs actual behavior
- Environment details (SageMaker Studio JupyterLab, marimo version, Python version)

### Suggesting Enhancements

Open an issue describing:
- The enhancement you'd like to see
- Why it would be useful
- How it might work

### Pull Requests

1. **Fork the repository**
2. **Create a feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

3. **Make your changes**
   - Follow existing code style
   - Add tests if applicable
   - Update documentation

4. **Test your changes**
   - Test on SageMaker Studio (JupyterLab) if possible
   - Ensure `start-marimo.sh` launches marimo + the bridge
   - Verify demo notebooks run

5. **Commit your changes**
   ```bash
   git commit -m "Add: brief description of changes"
   ```

   Use conventional commit prefixes:
   - `Add:` for new features
   - `Fix:` for bug fixes
   - `Update:` for updates to existing features
   - `Docs:` for documentation changes
   - `Refactor:` for code refactoring

6. **Push to your fork**
   ```bash
   git push origin feature/your-feature-name
   ```

7. **Open a Pull Request**
   - Provide clear description of changes
   - Link any related issues
   - Explain testing performed

## Development Setup

### Local Development

```bash
# Clone your fork
git clone https://github.com/YOUR_USERNAME/aws-marimo-sagemaker.git
cd aws-marimo-sagemaker

# Create virtual environment
uv venv
uv pip install marimo pandas numpy boto3 plotly scikit-learn

# Run the demo
uv run --with marimo marimo edit sagemaker_ml_demo.py
```

### Testing on SageMaker Studio

1. Open a JupyterLab space in SageMaker Studio.
2. Run `bash start-marimo.sh` and open the bridge port `2719` — confirm cells execute.

## Project Structure

```
aws-marimo-sagemaker/
├── start-marimo.sh                 # Launch marimo + the bridge
├── sagemaker_marimo_bridge.py      # The WebSocket bridge (single file)
├── lifecycle-config/
│   └── install.sh                  # Persistent install via JupyterLab LCC
├── docs/
│   └── why-the-bridge.md           # Root cause + how the bridge fixes it
├── sagemaker_ml_demo.py            # ML workflow demo
├── marimo-demo.py                  # Simple reactive demo
├── README.md                       # Main documentation
├── CHANGELOG.md                    # Version history
├── CONTRIBUTING.md                 # This file
├── LICENSE                         # MIT License
└── VERSION                         # Semver version
```

## Documentation

When adding features:
- Update README.md with usage examples
- Add entry to CHANGELOG.md under [Unreleased]
- Update docs/why-the-bridge.md if it changes the transport behavior

## Versioning

This project follows [Semantic Versioning](https://semver.org/):
- **MAJOR**: Breaking changes
- **MINOR**: New features (backward compatible)
- **PATCH**: Bug fixes

Update VERSION file and CHANGELOG.md when releasing.

## Style Guidelines

### Python
- Follow PEP 8
- Use type hints where helpful
- Write clear docstrings for functions
- Keep marimo cells focused and single-purpose

### Shell Scripts
- Use `#!/bin/bash` shebang
- Add comments for complex sections
- Test on both macOS and Linux if possible
- Use `set -e` to exit on errors

### Markdown
- Use clear headings
- Include code blocks with language tags
- Add tables for comparisons
- Keep line length reasonable

## Testing Checklist

Before submitting a PR:
- [ ] Code runs without errors
- [ ] Demo notebook works on SageMaker Studio (via `start-marimo.sh`)
- [ ] `start-marimo.sh` launches marimo + the bridge cleanly
- [ ] Documentation is updated
- [ ] CHANGELOG.md is updated
- [ ] Commit messages are clear
- [ ] No sensitive information in commits

## Questions?

Feel free to open an issue for questions or discussion!

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
