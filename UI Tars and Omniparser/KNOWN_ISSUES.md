# Known Issues

This document tracks known issues and their workarounds for the Agent DarBot project.

## TypeScript/Node.js Issues

### Missing Workspace Packages

**Issue**: The `apps/agent-tars/package.json` references several workspace packages that are not present in this repository:

```json
"@agent-infra/mcp-shared": "workspace:*"
"@agent-infra/shared": "^1.0.0"
"@agent-infra/logger": "^1.0.0"
"@agent-infra/mcp-client": "^1.0.0"
"@agent-infra/search": "^1.0.0"
"@ui-tars/electron-ipc": "^1.0.0"
"@common/electron-build": "^1.0.0"
```

**Explanation**: According to the project documentation, "the agent-tars TypeScript application structure is defined but source may be in separate repository."

**Impact**: 
- `pnpm install` will fail with workspace package not found errors
- Building the Electron app will not work until these dependencies are resolved

**Workarounds**:
1. Focus on Python components (OmniParser, OmniTool) which are fully functional
2. If TypeScript source is needed, it may need to be obtained from the original UI-TARS repository
3. For development, these packages could be temporarily commented out, but this will break TypeScript compilation

**Resolution Status**: 🔴 Requires separate TypeScript source repository or package removal

---

## Python Issues

### ✅ FIXED: Torch/TorchVision Version Mismatch

**Issue**: `requirements.txt` specified incompatible versions:
- `torch==2.4.1`
- `torchvision==0.22.1`

**Fix Applied**: Updated `torchvision` to `0.19.1` which is compatible with torch 2.4.1

**Status**: ✅ Fixed in latest commit

---

## Model Weights

### Model Weights Not Included

**Issue**: ML model weights are not included in the repository (intentional, due to size)

**Impact**: OmniParser will not work until weights are downloaded

**Resolution**: 
1. Run the automated setup script:
   ```bash
   python3 production_setup.py
   ```

2. Or manually download:
   ```bash
   mkdir -p weights
   for f in icon_detect/{train_args.yaml,model.pt,model.yaml} icon_caption/{config.json,generation_config.json,model.safetensors}; do 
     huggingface-cli download microsoft/OmniParser-v2.0 "$f" --local-dir weights
   done
   mv weights/icon_caption weights/icon_caption_florence
   ```

**Status**: ⚠️ Expected - documented in README and setup scripts

---

## Recommended Focus

Given the current state of the repository:

### ✅ Fully Functional Components
1. **OmniParser Core** - Python-based screen parsing
2. **OmniTool** - Gradio web interface for agent control
3. **OmniParser Server** - Standalone parsing service

### 🚧 Requires Additional Setup
1. **UI-TARS Desktop** - Electron app (missing workspace dependencies)
2. **Agent-TARS** - Advanced multimodal agent (missing workspace dependencies)

### Immediate Action Items
1. ✅ Use Python components which are fully functional
2. ⚠️ For TypeScript components, source may need to be obtained from upstream repositories
3. ✅ Focus development on OmniParser and OmniTool which have complete implementations

---

## Getting Help

If you encounter additional issues:

1. Check [`TROUBLESHOOTING.md`](./TROUBLESHOOTING.md) for common solutions
2. Run `python3 production_setup.py` for automated diagnostics
3. Review logs in `omnitool.log` for detailed error messages
4. Ensure all dependencies are installed: `pip install -r requirements.txt`
5. For TypeScript issues, check if source is available in upstream repositories:
   - https://github.com/bytedance/UI-TARS
   - https://github.com/microsoft/OmniParser

---

Last Updated: 2025-01-05
