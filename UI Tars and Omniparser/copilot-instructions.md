# Copilot Instructions for Agent DarBot

## Project Overview

This repository contains **Agent DarBot**, a comprehensive GUI automation and screen parsing system that combines:

- **OmniParser**: A pure vision-based screen parsing tool for GUI agents that converts UI screenshots into structured elements
- **UI-Tars**: Desktop application components for GUI automation
- **OmniTool**: Control system for Windows 11 VMs with multi-modal LLM integration

## Project Structure

This is a **hybrid Python/TypeScript monorepo** with the following key components:

```
├── apps/agent-tars/          # Main Electron-based agent application
├── omnitool/                 # Python-based control system
│   ├── gradio/              # Web interface components  
│   ├── omniparserserver/    # Parser server implementation
│   └── omnibox/             # Container orchestration
├── weights/                 # ML model checkpoints
├── docs/                    # Documentation
└── simple-openai-server/    # OpenAI API compatible server
```

## Technologies & Dependencies

### Python Components
- **Python 3.12** - Primary Python version
- **PyTorch 2.4.1** - Deep learning framework
- **Gradio 3.50.2** - Web UI framework
- **OpenCV** - Computer vision
- **Transformers** - HuggingFace models
- **EasyOCR** - Text recognition
- **Ultralytics** - YOLO object detection

### TypeScript/Node.js Components
- **Node.js 20** - JavaScript runtime
- **pnpm 9** - Package manager (required)
- **Electron** - Desktop application framework
- **TypeScript** - Primary language for frontend
- **Turbo** - Monorepo build system

## Development Setup

### Quick Start
1. Python components: `pip install -r requirements.txt`
2. Node.js components: `pnpm install`
3. Model weights: Run `setup_weights.ps1` or download from HuggingFace

### Package Manager
- **Always use `pnpm`** instead of npm or yarn
- This is a pnpm workspace with packages in `apps/*`
- Root package.json redirects to agent-tars application
- Install with: `pnpm install` (lockfile may need updating)

## Build & Test Commands

### Python Components
```bash
# Run Python components
python omnitool/gradio/app.py
python gradio_demo.py

# Install dependencies
pip install -r requirements.txt
```

### TypeScript Components
```bash
# Install dependencies (from root)
pnpm install

# Development (agent-tars app - if source available)
cd apps/agent-tars && pnpm run dev

# Build & Test (from root with Turbo)
npm exec turbo run typecheck
npm exec turbo run coverage
npm exec turbo run build

# Linting (from agent-tars directory)
cd apps/agent-tars && npm run lint
```

**Note**: The TypeScript source code may not be present in this repository. Configuration files are available in `apps/agent-tars/`.

## Code Style & Conventions

### Python
- **Ruff** for linting and formatting
- **Type hints** preferred for function signatures
- **Black-compatible** formatting (via Ruff)

### TypeScript
- **ESLint** + **Prettier** for linting/formatting
- **Strict TypeScript** configuration
- **camelCase** for variables and functions
- **PascalCase** for components and classes

## Architecture Patterns

### OmniParser Components
- **Vision models** for screen understanding
- **Detection pipelines** for UI element identification
- **OCR integration** for text extraction
- **Structured output** generation

### Agent Architecture
- **Multi-modal LLM integration** (OpenAI, Anthropic, DeepSeek)
- **Orchestration patterns** for agent coordination
- **Tool-based execution** model
- **Trajectory logging** for training data collection

### UI-Tars Desktop (Agent-Tars)
- **Electron-based** desktop application in `apps/agent-tars/`
- **React/TypeScript** frontend
- **IPC communication** between main and renderer processes
- **Multimodal AI agent** for GUI interaction

## Important Considerations

### Model Weights & Dependencies
- Model checkpoints are stored in `weights/` directory
- **Large files**: Use Git LFS or external storage
- **HuggingFace models**: Download programmatically via scripts

### Cross-platform Compatibility  
- **Windows focus**: Primary target for GUI automation
- **PowerShell scripts** for Windows setup
- **Bash scripts** available for Unix-like systems

### Performance
- **GPU acceleration** recommended for vision models
- **Memory management** important for large models
- **Async patterns** for UI responsiveness

## Testing Strategy

### Python Components
- **Unit tests** for core parsing logic
- **Integration tests** for model pipelines
- **Visual regression tests** for UI parsing accuracy

### TypeScript Components  
- **Vitest** for unit testing
- **E2E tests** for agent workflows
- **Coverage tracking** via Codecov

## Common Workflows

### Adding New Features
1. Consider impact on both Python and TypeScript components
2. Update requirements.txt or package.json as needed
3. Add appropriate tests
4. Update documentation

### Model Updates
1. Update model checkpoints in weights/
2. Update version references in configs
3. Test parsing accuracy
4. Update documentation

### UI Changes
1. Follow Electron best practices
2. Maintain IPC interface compatibility  
3. Test cross-platform rendering
4. Update E2E tests

## Debugging Tips

- **Python**: Use built-in debugger or IDE debugging
- **TypeScript**: Use Chrome DevTools for renderer, VS Code for main process
- **Agent behavior**: Check trajectory logs in `logs/` directory
- **Model performance**: Use gradio interfaces for interactive testing
- **Dependencies**: Install Python deps with `pip install -r requirements.txt`
- **Node.js**: Use `pnpm install` (may need `--no-frozen-lockfile` if lockfile is outdated)

## Repository Notes

- This repository contains **configuration and Python components** primarily
- The agent-tars TypeScript application structure is defined but source may be in separate repository
- Focus on Python ML components in `omnitool/` for most development work
- Model weights need to be downloaded separately using provided scripts

## Security Considerations

- **No secrets in code** - Use environment variables
- **Sandboxed execution** for agent operations
- **Input validation** for user-provided data
- **Safe model loading** practices

---

When contributing to this project, focus on maintaining compatibility between the Python ML components and TypeScript UI components, and always test both sides of any changes that might affect the integration points.