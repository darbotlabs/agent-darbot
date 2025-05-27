---
## Local Hugging Face Inference Server (On-Device)

Run a Hugging Face inference server locally—just like Omniparse—so UI‑TARS can call it on-device.

### Option A: Python-based Server

```powershell
# 1. Create & activate venv
python -m venv hf-env
.\hf-env\Scripts\Activate.ps1

# 2. Install inference server & deps
pip install text-generation-inference[torch] transformers accelerate huggingface_hub

# 3. (Optional) Download model weights locally
python - << 'EOF'
from huggingface_hub import snapshot_download
snapshot_download("mistralai/pygmalion-6b")
EOF

# 4. Launch server on port 8001 (CPU device)
tgi \
  --model-id mistralai/pygmalion-6b \
  --port 8001 \
  --device cpu
```

### Option B: Docker-based Server

```powershell
# Pull official HF inference image
docker pull ghcr.io/huggingface/text-generation-inference:latest

# Run container with mounted cache and model env
docker run -d --name hf-inference -p 8001:80 \
  -v ${PWD}\\model_cache:C:/mnt/model_cache \
  -e MODEL_ID=mistralai/pygmalion-6b \
  ghcr.io/huggingface/text-generation-inference:latest
```

### 5. Verify & Configure
```powershell
# Check endpoint
Invoke-WebRequest http://localhost:8001/v1/models -UseBasicParsing
```
In UI‑TARS settings, set:
- **vlmBaseUrl**: `http://localhost:8001/v1`
- **vlmModelName**: `mistralai/pygmalion-6b`
---