# OmniParser: Local Screen Parsing Tool

OmniParser is a tool for parsing GUI screenshots into structured elements, running fully on your local machine.

## Features
- **No cloud or public sharing**: Runs only on `localhost` (127.0.0.1)
- **Automated setup**: PowerShell scripts for environment, dependencies, and model weights
- **Modern Gradio UI**: Easy drag-and-drop interface
- **Sample images**: Try with images in the `imgs/` folder

---

## Quick Start

### 1. Automated Setup
Open PowerShell in this folder and run:

```pwsh
pwsh -NoProfile -ExecutionPolicy Bypass -File .\setup_omniparser.ps1
```

### 2. Run the Demo
```pwsh
pwsh -NoProfile -ExecutionPolicy Bypass -File .\run_omniparser_local.ps1
```

- The app will be available at: [http://127.0.0.1:7861](http://127.0.0.1:7861)

### 3. Usage
- Upload a screenshot or GUI image
- Adjust thresholds as needed
- Click **Submit** to parse
- View detected elements and their descriptions

### 4. Example
- Try: `imgs/google_page.png` or `imgs/windows_home.png`

---

## Troubleshooting
- If you see missing model or dependency errors, re-run the setup script
- Ensure you are in the `omni` conda environment for manual runs

---

## Scripts
- `setup_omniparser.ps1` — Full setup (env, dependencies, weights)
- `run_omniparser_local.ps1` — Run the Gradio demo (localhost only)
- `setup_weights.ps1` — Download model weights only

---

## License
MIT

---

## Credits
- [OmniParser Paper](https://arxiv.org/abs/2408.00203)
- [HuggingFace Model](https://huggingface.co/microsoft/OmniParser-v2.0)
