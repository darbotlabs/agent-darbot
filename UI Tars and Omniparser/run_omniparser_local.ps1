# PowerShell script to run OmniParser Gradio demo on localhost only
$ErrorActionPreference = 'Stop'
$envName = "omni"
$root = "g:/CypherDyne/OmniParser/OmniParser-master"

# Activate conda env and run the demo
conda run -n $envName pwsh -Command "cd $root; python gradio_demo.py"
