# Agent DarBot

<p align="center">
  <img src="UI Tars and Omniparser/imgs/logo.png" alt="Agent DarBot Logo" width="200">
</p>

[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Python](https://img.shields.io/badge/Python-3.12-blue.svg)](https://www.python.org/)
[![Node.js](https://img.shields.io/badge/Node.js-20-green.svg)](https://nodejs.org/)
[![Status](https://img.shields.io/badge/Status-Production_Ready-success.svg)](./ONBOARDING_SUMMARY.md)

> **🎉 Repository Onboarded!** Python components are production-ready. See [ONBOARDING_SUMMARY.md](./ONBOARDING_SUMMARY.md) for details.

A comprehensive GUI automation and screen parsing system combining **OmniParser**, **UI-TARS**, and **OmniTool** for intelligent computer control using vision-language models.

## 🌟 Features

- **🤖 OmniParser**: Pure vision-based screen parsing tool that converts UI screenshots into structured, actionable elements
- **🖥️ UI-TARS Desktop**: Electron-based GUI automation application powered by vision-language models
- **🎯 OmniTool**: Control system for Windows 11 VMs with multi-modal LLM integration (OpenAI, Anthropic, Groq, DeepSeek, Qwen)
- **🔄 Agent-TARS**: Advanced multimodal AI agent with browser operations and file system integration
- **🌐 Multi-Provider Support**: Works with GPT-4o, Claude 3.5 Sonnet, o1/o3-mini, DeepSeek R1, and more

## 📚 Quick Links

- ⚡ **New Here?**: [`QUICKSTART.md`](./QUICKSTART.md) - Get started in 5 minutes!
- 📋 **Onboarding Summary**: [`ONBOARDING_SUMMARY.md`](./ONBOARDING_SUMMARY.md) - Repository status and recommendations
- 🔧 **Troubleshooting**: [`TROUBLESHOOTING.md`](./UI%20Tars%20and%20Omniparser/TROUBLESHOOTING.md)
- ⚠️ **Known Issues**: [`KNOWN_ISSUES.md`](./UI%20Tars%20and%20Omniparser/KNOWN_ISSUES.md)
- 📝 **OmniParser Details**: [`README.md`](./UI%20Tars%20and%20Omniparser/README.md)
- 💻 **UI-TARS Details**: [`README (2).md`](./UI%20Tars%20and%20Omniparser/README%20(2).md)
- 📖 **Full Documentation**: See [`UI Tars and Omniparser/`](./UI%20Tars%20and%20Omniparser/) directory

## 🚀 Quick Start

### Prerequisites

- **Python 3.12** or higher
- **Node.js 20** or higher
- **pnpm 9** (for TypeScript components)
- **CUDA** (recommended for GPU acceleration)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/darbotlabs/agent-darbot.git
   cd agent-darbot
   cd "UI Tars and Omniparser"
   ```

2. **Run production setup check**
   ```bash
   python3 production_setup.py
   ```
   This will check for dependencies, available ports, and provide guidance on what needs to be installed.

3. **Install Python dependencies**
   ```bash
   # Using conda (recommended)
   conda create -n "omni" python==3.12
   conda activate omni
   pip install -r requirements.txt
   
   # Or using pip directly
   pip install -r requirements.txt
   ```

4. **Install Node.js dependencies** (for UI-TARS Desktop)
   ```bash
   # Install pnpm if not already installed
   npm install -g pnpm@9
   
   # Install dependencies
   pnpm install
   ```

5. **Download model weights**
   ```bash
   # For OmniParser V2 (recommended)
   mkdir -p weights
   for f in icon_detect/{train_args.yaml,model.pt,model.yaml} icon_caption/{config.json,generation_config.json,model.safetensors}; do 
     huggingface-cli download microsoft/OmniParser-v2.0 "$f" --local-dir weights
   done
   mv weights/icon_caption weights/icon_caption_florence
   ```

6. **Set up API keys**
   ```bash
   # Set as environment variables (recommended for production)
   export OPENAI_API_KEY="your_openai_key_here"
   export ANTHROPIC_API_KEY="your_anthropic_key_here"
   
   # Or configure in the app UI
   ```

### Running the Applications

#### OmniTool (Gradio Interface)

```bash
cd "UI Tars and Omniparser"
python omnitool/gradio/app_new.py
```

Access at: `http://localhost:7860`

#### OmniParser Server (Standalone)

```bash
cd "UI Tars and Omniparser"
python gradio_demo.py
```

#### UI-TARS Desktop (Electron App)

```bash
cd "UI Tars and Omniparser"
pnpm run dev
```

#### Windows PowerShell Launch Script

For Windows users, there's an integrated launcher:

```powershell
cd "UI Tars and Omniparser"
.\launch-ui-tars-fixed.ps1
```

## 📖 Project Structure

```
agent-darbot/
└── UI Tars and Omniparser/
    ├── apps/
    │   └── agent-tars/          # Electron-based agent application
    ├── omnitool/
    │   ├── gradio/              # Web interface (OmniTool)
    │   ├── omniparserserver/    # Parser server implementation
    │   └── omnibox/             # Container orchestration
    ├── weights/                 # ML model checkpoints (download separately)
    ├── docs/                    # Additional documentation
    ├── simple-openai-server/    # OpenAI-compatible API server
    ├── requirements.txt         # Python dependencies
    ├── package.json            # Node.js dependencies
    └── production_setup.py     # Production setup and validation script
```

## 🔧 Components

### OmniParser

A state-of-the-art screen parsing tool that uses computer vision to:
- Detect interactive UI elements
- Identify icons and their functions
- Generate structured representations of GUIs
- Achieve 39.5% accuracy on ScreenSpot Pro benchmark

**Key Features:**
- Pure vision-based (no accessibility APIs required)
- V2 model with improved accuracy
- Supports multiple caption models (Florence, BLIP2)

### UI-TARS Desktop

Desktop application for GUI automation:
- Natural language control of your computer
- Vision-language model integration
- Real-time feedback and status display
- Cross-platform support (Windows/MacOS/Browser)
- Private and secure local processing

### OmniTool

Enhanced control system for Windows 11 VMs:
- Multi-AI provider support (OpenAI, Anthropic, Groq, DeepSeek, Qwen)
- Built-in connectivity testing
- Rate limiting and security features
- Comprehensive error handling
- Production-ready with logging and monitoring

## 🧪 Testing

### Python Components

```bash
cd "UI Tars and Omniparser"
pytest
```

### TypeScript Components

```bash
cd "UI Tars and Omniparser"
pnpm run test
```

### Linting

```bash
# Python
ruff check .

# TypeScript
pnpm run lint
```

## 📋 Requirements

### Python Dependencies (Key Packages)

- `torch==2.4.1` - Deep learning framework
- `transformers==4.52.4` - HuggingFace models
- `gradio==3.50.2` - Web UI framework
- `openai==1.57.0` - OpenAI API client
- `anthropic==0.42.0` - Anthropic API client
- `ultralytics==8.3.70` - YOLO object detection
- `opencv-python==4.11.0.86` - Computer vision

See [`requirements.txt`](./UI%20Tars%20and%20Omniparser/requirements.txt) for complete list.

### System Requirements

- **OS**: Windows 10/11, macOS 10.15+, or Linux
- **RAM**: 8GB minimum, 16GB+ recommended
- **GPU**: CUDA-compatible GPU recommended (4GB+ VRAM)
- **Disk**: 10GB+ free space (for models and dependencies)

## 🔒 Security

- **No secrets in code** - Use environment variables
- **Sandboxed execution** for agent operations
- **Input validation** for user-provided data
- **Rate limiting** (10 requests per minute)
- **Secure API key storage** with proper file permissions

See [`SECURITY.md`](./UI%20Tars%20and%20Omniparser/SECURITY.md) for more details.

## 🐛 Troubleshooting

### Common Issues

1. **"OmniParser Server is not responding"**
   - Ensure the OmniParser server is running
   - Check port 8000 is available
   - Verify model weights are downloaded

2. **"Module not found" errors**
   - Run `pip install -r requirements.txt`
   - Ensure you're in the correct virtual environment

3. **"Port already in use"**
   - Check for other running instances
   - Use alternative ports with command line arguments

4. **Model loading errors**
   - Verify model weights are in `weights/` directory
   - Check you have sufficient disk space and RAM

For detailed troubleshooting, see [`TROUBLESHOOTING.md`](./UI%20Tars%20and%20Omniparser/TROUBLESHOOTING.md).

## 📈 Performance

- **OmniParser V2**: 39.5% accuracy on ScreenSpot Pro benchmark
- **Response Time**: <2s for typical screen parsing
- **Model Size**: ~2GB for OmniParser models
- **Memory Usage**: 4-8GB RAM typical, 2-4GB VRAM with GPU

## 🤝 Contributing

Contributions are welcome! Please see [`CONTRIBUTING.md`](./UI%20Tars%20and%20Omniparser/CONTRIBUTING.md) for guidelines.

### Development Workflow

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Run tests and linting
5. Commit your changes (`git commit -m 'Add amazing feature'`)
6. Push to the branch (`git push origin feature/amazing-feature`)
7. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [`LICENSE`](./UI%20Tars%20and%20Omniparser/LICENSE) file for details.

**Note**: The icon_detect model uses YOLO and is under AGPL license. The caption models (Florence, BLIP2) are under MIT license. See [HuggingFace model hub](https://huggingface.co/microsoft/OmniParser) for details.

## 🙏 Acknowledgments

This project builds upon:
- **[OmniParser](https://github.com/microsoft/OmniParser)** by Microsoft Research
- **[UI-TARS](https://github.com/bytedance/UI-TARS)** by ByteDance
- **[Gradio](https://gradio.app/)** for web interfaces
- **[Electron](https://www.electronjs.org/)** for desktop applications

## 📞 Support

- 📖 **Documentation**: Check the docs in [`UI Tars and Omniparser/`](./UI%20Tars%20and%20Omniparser/)
- 🐛 **Issues**: [GitHub Issues](https://github.com/darbotlabs/agent-darbot/issues)
- 💬 **Discord**: Join the [UI-TARS Discord](https://discord.gg/pTXwYVjfcs)

## 📊 Project Status

- ✅ **OmniParser V2**: Stable and production-ready
- ✅ **OmniTool**: Production-ready with comprehensive features
- 🚧 **UI-TARS Desktop**: Active development
- 🚧 **Agent-TARS**: Technical preview (v1.0.0-alpha.8)

## 🔮 Roadmap

- [ ] Improved multi-agent orchestration
- [ ] Enhanced training data pipeline
- [ ] Better UI/UX for OmniTool
- [ ] Additional LLM provider support
- [ ] Performance optimizations
- [ ] Expanded documentation and examples

---

<p align="center">
  Made with ❤️ by the DarBot Labs team
</p>
