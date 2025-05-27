# PowerShell script to automate full OmniParser setup
# 1. Create conda env, 2. Install dependencies, 3. Download weights

$ErrorActionPreference = 'Stop'
$envName = "omni"
$pyVersion = "3.12"
$root = "g:/CypherDyne/OmniParser/OmniParser-master"
$weightsDir = "$root/weights"

# Step 1: Create conda env if not exists
if (-not (conda env list | Select-String $envName)) {
    conda create -n $envName python=$pyVersion -y
}

# Step 2: Install dependencies
# Uninstall current gradio and gradio_client, then install compatible versions
conda run -n $envName pip uninstall -y gradio gradio_client
conda run -n $envName pip install gradio==3.50.2 gradio_client==0.6.1
conda run -n $envName pip install -r "$root/requirements.txt"

# Step 3: Download model weights
pwsh -NoProfile -ExecutionPolicy Bypass -File "$root/setup_weights.ps1"

Write-Host "OmniParser setup complete. Activate with: conda activate omni"
