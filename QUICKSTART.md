# Quick Start Guide

Get Agent DarBot up and running in minutes!

## Prerequisites

Before you begin, ensure you have:

- ✅ **Python 3.12+** ([Download](https://www.python.org/downloads/))
- ✅ **Git** ([Download](https://git-scm.com/downloads))
- ✅ **8GB+ RAM** (16GB recommended)
- ✅ **10GB+ free disk space**
- ⚡ **GPU with CUDA** (optional but recommended for performance)

## Quick Setup (5 minutes)

### 1. Clone the Repository

```bash
git clone https://github.com/darbotlabs/agent-darbot.git
cd agent-darbot
cd "UI Tars and Omniparser"
```

### 2. Run Automated Setup

#### On Linux/Mac:
```bash
./setup.sh
```

#### On Windows:
```powershell
python production_setup.py
```

This will:
- ✅ Check your Python version
- ✅ Verify dependencies
- ✅ Check available ports
- ✅ Guide you through any missing requirements

### 3. Install Dependencies

#### Using Conda (Recommended):
```bash
conda create -n omni python==3.12
conda activate omni
pip install -r requirements.txt
```

#### Using pip:
```bash
pip install -r requirements.txt
```

### 4. Download Model Weights

You'll need the OmniParser V2 models (~2GB):

```bash
# Install huggingface-cli if needed
pip install -U huggingface-hub

# Download models
mkdir -p weights
for f in icon_detect/train_args.yaml icon_detect/model.pt icon_detect/model.yaml icon_caption/config.json icon_caption/generation_config.json icon_caption/model.safetensors; do
    huggingface-cli download microsoft/OmniParser-v2.0 "$f" --local-dir weights
done
mv weights/icon_caption weights/icon_caption_florence
```

### 5. Set Up API Keys

Choose one or more AI providers:

```bash
# OpenAI (recommended)
export OPENAI_API_KEY="sk-..."

# Anthropic Claude
export ANTHROPIC_API_KEY="sk-ant-..."

# Groq
export GROQ_API_KEY="gsk_..."

# Alibaba Qwen
export DASHSCOPE_API_KEY="..."
```

Or configure them later in the web interface.

### 6. Launch! 🚀

```bash
python omnitool/gradio/app_new.py
```

Open your browser to: **http://localhost:7860**

## First Use

### Using OmniTool (Web Interface)

1. **Enter your API key** in the Settings section
2. **Click "Test Connectivity"** to verify everything works
3. **Choose a model** from the dropdown (e.g., "omniparser + gpt-4o-orchestrated")
4. **Type a task**: "Take a screenshot" or "Open notepad"
5. **Click Send** or press Enter

### Example Tasks to Try

```
"Take a screenshot and save it"
"Open a browser and search for weather"
"Create a new folder called 'test' on the desktop"
"Open calculator"
"List files in the current directory"
```

## Alternative Launches

### OmniParser Demo Only
```bash
python gradio_demo.py
```
Access at: http://localhost:7860

### Windows PowerShell (All Components)
```powershell
.\launch-ui-tars-fixed.ps1
```
This launches:
- Mock API server
- OmniParser server
- UI-TARS desktop app

## Troubleshooting

### "Module not found" errors
```bash
pip install -r requirements.txt
# Ensure you're in the correct virtual environment
```

### "Port already in use"
```bash
# Check what's using the port
lsof -i :7860  # Linux/Mac
netstat -ano | findstr :7860  # Windows

# Kill the process or use a different port:
python omnitool/gradio/app_new.py --server_port 7861
```

### "Model weights not found"
```bash
# Verify weights directory structure:
ls -la weights/
# Should contain: icon_detect/ and icon_caption_florence/

# Re-download if needed (see step 4)
```

### "CUDA out of memory"
```bash
# Force CPU mode by setting:
export CUDA_VISIBLE_DEVICES=""
```

### "OmniParser server not responding"
```bash
# Check if the OmniParser server is running separately:
python omnitool/omniparserserver/omniparserserver.py

# Or use the integrated launcher:
python omnitool/gradio/app_new.py --omniparser_server_url localhost:8000
```

## Performance Tips

### Use GPU Acceleration
- Install CUDA toolkit for your GPU
- Verify GPU support: `python -c "import torch; print(torch.cuda.is_available())"`
- Expected: Much faster processing (2-5x speedup)

### Reduce Memory Usage
- Close unnecessary applications
- Use smaller models when available
- Reduce image resolution in settings

### Optimize for Speed
- Use local models instead of API calls when possible
- Enable caching in the settings
- Use SSD for model storage

## Architecture Overview

```
┌─────────────────────────────────────────┐
│         OmniTool Web Interface          │
│         (Gradio on port 7860)           │
└─────────────────┬───────────────────────┘
                  │
        ┌─────────┴─────────┐
        │                   │
┌───────▼────────┐  ┌──────▼──────────┐
│  OmniParser    │  │  LLM Provider   │
│  (Vision AI)   │  │  (OpenAI, etc)  │
└───────┬────────┘  └─────────────────┘
        │
┌───────▼────────┐
│  Windows Host  │
│  (Optional)    │
└────────────────┘
```

## What's Working vs What's Not

### ✅ Fully Functional
- **OmniParser Core**: Screen parsing and element detection
- **OmniTool**: Web interface with multi-provider support
- **API Integration**: OpenAI, Anthropic, Groq, DeepSeek, Qwen
- **Python Components**: All working as expected

### ⚠️ Requires Additional Setup
- **UI-TARS Desktop**: Electron app (has missing workspace dependencies)
- **Agent-TARS**: Advanced features (requires TypeScript source)

### 💡 Recommendation
Focus on Python components (OmniParser + OmniTool) which are production-ready and fully functional.

## Next Steps

1. 📖 Read the [Full README](README.md) for detailed information
2. 🔧 Check [TROUBLESHOOTING.md](UI%20Tars%20and%20Omniparser/TROUBLESHOOTING.md) for common issues
3. 📋 Review [KNOWN_ISSUES.md](UI%20Tars%20and%20Omniparser/KNOWN_ISSUES.md) for current limitations
4. 🔐 Read [SECURITY.md](UI%20Tars%20and%20Omniparser/SECURITY.md) for production deployment
5. 🤝 Check [CONTRIBUTING.md](UI%20Tars%20and%20Omniparser/CONTRIBUTING.md) to contribute

## Getting Help

- 📖 **Documentation**: Check the `/docs` directory
- 🐛 **Issues**: [GitHub Issues](https://github.com/darbotlabs/agent-darbot/issues)
- 💬 **Discord**: [UI-TARS Discord](https://discord.gg/pTXwYVjfcs)
- 📧 **Email**: Support through GitHub issues

## Success Checklist

Before you start using Agent DarBot in production:

- [ ] Python dependencies installed successfully
- [ ] Model weights downloaded and verified
- [ ] API key configured and tested
- [ ] OmniTool launches without errors
- [ ] Test connectivity passes
- [ ] At least one test task completes successfully
- [ ] Logs directory created and writable
- [ ] Security best practices reviewed

---

**Ready to go?** Start with a simple task like "Take a screenshot" to verify everything works! 🎉
