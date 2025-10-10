#!/bin/bash
set -e

# Agent DarBot Setup Script
# This script automates the setup of Python components for OmniParser and OmniTool

echo "================================================="
echo "    Agent DarBot Setup Script (Python)"
echo "================================================="
echo ""

# Check Python version
echo "📋 Checking Python version..."
PYTHON_VERSION=$(python3 --version | cut -d' ' -f2)
REQUIRED_VERSION="3.12.0"

if [ "$(printf '%s\n' "$REQUIRED_VERSION" "$PYTHON_VERSION" | sort -V | head -n1)" != "$REQUIRED_VERSION" ]; then
    echo "❌ Python 3.12+ required. Found: $PYTHON_VERSION"
    echo "   Please install Python 3.12 or higher"
    exit 1
fi
echo "✅ Python $PYTHON_VERSION detected"
echo ""

# Check if we're in a virtual environment (recommended)
if [ -z "$VIRTUAL_ENV" ]; then
    echo "⚠️  Not in a virtual environment"
    echo "   Recommended: Create and activate a virtual environment:"
    echo "   conda create -n omni python==3.12"
    echo "   conda activate omni"
    echo ""
    read -p "Continue without virtual environment? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
else
    echo "✅ Virtual environment: $VIRTUAL_ENV"
    echo ""
fi

# Install Python dependencies
echo "📦 Installing Python dependencies..."
echo "   This may take several minutes..."
if pip install -r requirements.txt; then
    echo "✅ Python dependencies installed successfully"
else
    echo "❌ Failed to install Python dependencies"
    echo "   Try: pip install --upgrade pip"
    echo "   Then run this script again"
    exit 1
fi
echo ""

# Check for CUDA
echo "📋 Checking for CUDA (GPU support)..."
if python3 -c "import torch; print('✅ PyTorch installed'); print('✅ CUDA available' if torch.cuda.is_available() else '⚠️  CUDA not available (CPU mode)')"; then
    :
else
    echo "⚠️  PyTorch import failed"
fi
echo ""

# Create necessary directories
echo "📁 Creating required directories..."
mkdir -p weights tmp/outputs logs .anthropic
echo "✅ Directories created"
echo ""

# Check for model weights
echo "📋 Checking for model weights..."
WEIGHTS_NEEDED=false

if [ ! -f "weights/icon_detect/model.pt" ]; then
    echo "❌ Icon detection model not found"
    WEIGHTS_NEEDED=true
fi

if [ ! -f "weights/icon_caption_florence/model.safetensors" ]; then
    echo "❌ Florence caption model not found"
    WEIGHTS_NEEDED=true
fi

if [ "$WEIGHTS_NEEDED" = true ]; then
    echo ""
    echo "⚠️  Model weights are missing!"
    echo ""
    echo "To download model weights (requires huggingface-cli):"
    echo ""
    echo "# Install huggingface-cli if needed:"
    echo "pip install -U huggingface-hub"
    echo ""
    echo "# Download OmniParser V2 weights:"
    echo "mkdir -p weights"
    echo "for f in icon_detect/train_args.yaml icon_detect/model.pt icon_detect/model.yaml icon_caption/config.json icon_caption/generation_config.json icon_caption/model.safetensors; do"
    echo "    huggingface-cli download microsoft/OmniParser-v2.0 \"\$f\" --local-dir weights"
    echo "done"
    echo "mv weights/icon_caption weights/icon_caption_florence"
    echo ""
else
    echo "✅ Model weights found"
fi
echo ""

# Check for API keys
echo "📋 Checking for API keys..."
API_KEY_FOUND=false

if [ ! -z "$OPENAI_API_KEY" ]; then
    echo "✅ OPENAI_API_KEY is set"
    API_KEY_FOUND=true
fi

if [ ! -z "$ANTHROPIC_API_KEY" ]; then
    echo "✅ ANTHROPIC_API_KEY is set"
    API_KEY_FOUND=true
fi

if [ ! -z "$GROQ_API_KEY" ]; then
    echo "✅ GROQ_API_KEY is set"
    API_KEY_FOUND=true
fi

if [ ! -z "$DASHSCOPE_API_KEY" ]; then
    echo "✅ DASHSCOPE_API_KEY is set"
    API_KEY_FOUND=true
fi

if [ "$API_KEY_FOUND" = false ]; then
    echo "⚠️  No API keys found in environment variables"
    echo ""
    echo "Set at least one API key to use OmniTool:"
    echo "  export OPENAI_API_KEY='your-key-here'"
    echo "  export ANTHROPIC_API_KEY='your-key-here'"
    echo "  export GROQ_API_KEY='your-key-here'"
    echo "  export DASHSCOPE_API_KEY='your-key-here'"
    echo ""
    echo "Or configure them in the OmniTool web interface"
fi
echo ""

# Check ports
echo "📋 Checking required ports..."
check_port() {
    if lsof -Pi :$1 -sTCP:LISTEN -t >/dev/null 2>&1; then
        echo "⚠️  Port $1 is in use"
        return 1
    else
        echo "✅ Port $1 available"
        return 0
    fi
}

check_port 7860 || true  # OmniTool default port
check_port 8000 || true  # OmniParser server default port
check_port 5000 || true  # Windows host default port
echo ""

# Summary
echo "================================================="
echo "    Setup Summary"
echo "================================================="
echo ""
echo "✅ Python dependencies installed"
echo ""

if [ "$WEIGHTS_NEEDED" = false ]; then
    echo "✅ Model weights present"
else
    echo "⚠️  Model weights need to be downloaded (see instructions above)"
fi
echo ""

if [ "$API_KEY_FOUND" = true ]; then
    echo "✅ API key(s) configured"
else
    echo "⚠️  API keys need to be configured"
fi
echo ""

echo "================================================="
echo "    Next Steps"
echo "================================================="
echo ""

if [ "$WEIGHTS_NEEDED" = true ]; then
    echo "1. Download model weights (see commands above)"
    echo "2. Launch OmniTool:"
else
    echo "1. Launch OmniTool:"
fi

echo "   python omnitool/gradio/app_new.py"
echo ""
echo "2. Or run the OmniParser demo:"
echo "   python gradio_demo.py"
echo ""
echo "3. Or run the setup validation:"
echo "   python production_setup.py"
echo ""
echo "📖 For more information, see README.md and TROUBLESHOOTING.md"
echo ""
