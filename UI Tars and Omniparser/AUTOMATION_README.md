# OmniParser Local Automation Scripts

This folder contains scripts to automate setup and running of the OmniParser Gradio demo locally (localhost only).

## Quick Start

### 1. Install Python & Conda
- Make sure you have [Miniconda](https://docs.conda.io/en/latest/miniconda.html) or [Anaconda](https://www.anaconda.com/products/distribution) installed.
- Python 3.12 is recommended (the scripts will set this up for you).

### 2. Automated Setup
Open a PowerShell terminal in this folder and run:

```pwsh
pwsh -NoProfile -ExecutionPolicy Bypass -File .\setup_omniparser.ps1
```

This will:
- Create a conda environment `omni` with Python 3.12
- Install all required Python dependencies
- Download all model weights from HuggingFace
- Prepare the folder structure

### 3. Run the Gradio Demo (Localhost Only)
After setup, start the demo with:

```pwsh
pwsh -NoProfile -ExecutionPolicy Bypass -File .\run_omniparser_local.ps1
```

This will:
- Activate the `omni` environment
- Start the Gradio demo on [http://127.0.0.1:7861](http://127.0.0.1:7861)

### 4. Usage
- Open [http://127.0.0.1:7861](http://127.0.0.1:7861) in your browser.
- Upload a screenshot or GUI image.
- Adjust thresholds and options as needed.
- Click **Submit** to parse the screen and view structured elements.

### 5. Example
- Try uploading an image from the `imgs/` folder (e.g., `imgs/google_page.png`).
- The output will show detected GUI elements and their descriptions.

---

## Troubleshooting
- If you see errors about missing model files, re-run the setup script.
- If you see dependency errors, ensure you are in the `omni` conda environment.
- For GPU acceleration, ensure you have a compatible CUDA setup and PyTorch installed with CUDA support.

---

## File List
- `setup_omniparser.ps1` — Full environment and model setup
- `run_omniparser_local.ps1` — Run the Gradio demo on localhost
- `setup_weights.ps1` — (Advanced) Only download model weights

---

For more details, see the main README.md or SETUP_GUIDE.md.
