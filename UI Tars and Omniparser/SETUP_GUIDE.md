# Instructions to set up OmniParser for Production

## Quick Start

1. **Run production setup check**
   ```bash
   python3 production_setup.py
   ```

2. **Install dependencies with pinned versions**
   ```bash
   conda create -n "omni" python==3.12
   conda activate omni
   pip install -r requirements.txt
   ```

3. **Download model weights**
   ```bash
   mkdir weights
   # For OmniParser V2 (recommended):
   for f in icon_detect/{train_args.yaml,model.pt,model.yaml} icon_caption/{config.json,generation_config.json,model.safetensors}; do 
     huggingface-cli download microsoft/OmniParser-v2.0 "$f" --local-dir weights
   done
   mv weights/icon_caption weights/icon_caption_florence
   ```

4. **Set up environment variables** (recommended for production)
   ```bash
   export OPENAI_API_KEY="your_openai_key_here"
   export ANTHROPIC_API_KEY="your_anthropic_key_here"
   export GROQ_API_KEY="your_groq_key_here"
   export DASHSCOPE_API_KEY="your_dashscope_key_here"
   ```

5. **Launch the application**
   ```bash
   python omnitool/gradio/app_new.py
   ```

## Production Features

### Security Enhancements
- ✅ **Secure API key storage** with file permissions (0o600)
- ✅ **Input sanitization** to prevent injection attacks
- ✅ **Rate limiting** (10 requests per minute per user)
- ✅ **Atomic file operations** for configuration saves

### Stability Improvements
- ✅ **Comprehensive error handling** with specific error messages
- ✅ **Production logging** to `omnitool.log`
- ✅ **Port availability checking** with automatic fallbacks
- ✅ **Connection testing** for all external services
- ✅ **Pinned dependency versions** for reproducible builds

### Monitoring & Debugging
- ✅ **Structured logging** for production monitoring
- ✅ **Health check endpoints** validation
- ✅ **Detailed troubleshooting** output on failures
- ✅ **Pre-flight checks** via `production_setup.py`

## Folder Structure

```
weights/
├── icon_detect/          # YOLO detection model
│   ├── model.pt
│   ├── model.yaml
│   └── train_args.yaml
└── icon_caption_florence/ # Florence2 caption model
    ├── config.json
    ├── generation_config.json
    └── model.safetensors
```

## System Requirements

- **Python**: 3.8+ (3.12 recommended)
- **GPU**: CUDA-compatible GPU (recommended for performance)
- **Memory**: 8GB+ RAM
- **Storage**: 5GB+ for models and dependencies

## API Provider Support

| Provider | Models | Status |
|----------|--------|--------|
| **OpenAI** | GPT-4o, o1, o3-mini | ✅ Full support |
| **Anthropic** | Claude-3.5-Sonnet | ✅ Computer Use support |
| **DeepSeek** | R1 | ✅ Via Groq API |
| **Qwen** | 2.5VL | ✅ Via DashScope |

## Deployment Options

### Docker (Recommended for Production)
```dockerfile
FROM python:3.12-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY . .
EXPOSE 7888
CMD ["python", "omnitool/gradio/app_new.py"]
```

### Systemd Service
```ini
[Unit]
Description=OmniTool Service
After=network.target

[Service]
Type=simple
User=omnitool
WorkingDirectory=/opt/omnitool
ExecStart=/opt/omnitool/venv/bin/python omnitool/gradio/app_new.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

## Troubleshooting

Run the production setup script for automated diagnostics:
```bash
python3 production_setup.py
```

For common issues, see [TROUBLESHOOTING.md](TROUBLESHOOTING.md).

## Security Notes

- API keys are stored with secure file permissions (readable only by owner)
- Input is sanitized to prevent injection attacks
- Rate limiting prevents abuse
- No sensitive data is logged in production mode
- HTTPS is recommended for production deployments

---

**Note**: This version includes production hardening, security improvements, and stability enhancements over the base OmniParser setup.




