# OmniParser Windows Automation & Setup Guide (Darbot Edition)

## Overview
This guide documents the complete, automated setup and usage process for running OmniParser locally on Windows, with all fixes and improvements made for reliability and user-friendliness. It covers:
- Automated environment and dependency setup
- Model weight management
- Gradio demo launch (localhost only)
- Troubleshooting common issues
- All PowerShell scripts and manual steps

## Prerequisites
- **Windows OS**
- **Miniconda/Anaconda** (for Python environment management)
- **Python 3.12** (installed via conda)
- **PowerShell** (pwsh.exe)
- **Internet access** (for downloading dependencies and model weights)

## Folder Structure
```
OmniParser-master(workinglocally)/
  |-- gradio_demo.py
  |-- requirements.txt
  |-- setup_omniparser.ps1
  |-- run_omniparser_local.ps1
  |-- setup_weights.ps1
  |-- weights/
  |-- ... (other source and doc files)
```

## Automated Setup (Recommended)
All setup and launch steps are automated with PowerShell scripts. Run these from the `OmniParser-master(workinglocally)` directory.

### 1. Full Setup (Conda env, dependencies, weights)
```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File setup_omniparser.ps1
```
- Creates the `omni` conda environment (if missing)
- Pins and installs all required Python dependencies (see below for Gradio fix)
- Downloads all model weights (calls `setup_weights.ps1`)

### 2. Run the Gradio Demo (localhost only)
```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File run_omniparser_local.ps1
```
- Activates the `omni` environment
- Launches the Gradio demo on `127.0.0.1:7861` (no public sharing)

### 3. (Re)Download Model Weights Only
```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File setup_weights.ps1
```
- Downloads all required model files to the `weights/` directory

## Manual Steps (if needed)
- If PaddleOCR model files fail to download, download and extract them manually as described in `QUICKSTART_WINDOWS.md`.
- If you want to run the demo manually:
  ```powershell
  conda activate omni
  python gradio_demo.py
  ```

## Dependency Fixes & Best Practices
- **Gradio Version Pinning:**
  - Fixed runtime errors by pinning `gradio==3.50.2` and `gradio_client==0.6.1` in `requirements.txt` and setup scripts.
  - Automated uninstall of incompatible versions before install.
- **All dependencies are installed via `requirements.txt` in the `omni` conda environment.**
- **Model weights are managed in the `weights/` directory.**

## Troubleshooting
- **Gradio TypeError/ValueError:**
  - Ensure you are using the provided scripts, which pin compatible Gradio versions.
- **Missing model files:**
  - Rerun `setup_weights.ps1` or download manually as per documentation.
- **Conda environment issues:**
  - Delete and recreate the `omni` environment if you encounter persistent errors.
- **Firewall/localhost issues:**
  - The demo is configured to run only on `127.0.0.1` for security.

## References & Further Documentation
- `AUTOMATION_README.md`, `QUICKSTART_WINDOWS.md`, `README_LOCAL.md`, `SETUP_GUIDE.md`
- For programmatic API usage, see `util/omniparser.py`.
- For troubleshooting, see `README.md` and `LICENSE`.

---
**Maintained and automated by Darbot. For questions, see the main documentation or contact the maintainer.**
