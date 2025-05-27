# PowerShell script to download required OmniParser model weights from HuggingFace
# and place them in the correct folders for the Gradio demo to work.

$ErrorActionPreference = 'Stop'
$weightsDir = "g:/CypherDyne/OmniParser/OmniParser-master/weights"

# Ensure weights directory exists
if (!(Test-Path $weightsDir)) { New-Item -ItemType Directory -Path $weightsDir -Force | Out-Null }

# List of files to download
$files = @(
  "icon_detect/train_args.yaml",
  "icon_detect/model.pt",
  "icon_detect/model.yaml",
  "icon_caption/config.json",
  "icon_caption/generation_config.json",
  "icon_caption/model.safetensors"
)

# Download each file using huggingface-cli
foreach ($f in $files) {
  huggingface-cli download microsoft/OmniParser-v2.0 $f --local-dir $weightsDir
}

# Move icon_caption to icon_caption_florence if needed
$captionSrc = Join-Path $weightsDir "icon_caption"
$captionDst = Join-Path $weightsDir "icon_caption_florence"
if (Test-Path $captionSrc) {
  if (Test-Path $captionDst) { Remove-Item $captionDst -Recurse -Force }
  Move-Item $captionSrc $captionDst
}

Write-Host "Model weights download and setup complete. You can now run the Gradio demo."
