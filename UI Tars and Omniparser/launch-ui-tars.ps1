#Requires -Version 5.0
<#
.SYNOPSIS
    Launches UI-TARS with all necessary components.
.DESCRIPTION
    This script starts both the local Hugging Face inference server
    and the UI-TARS Desktop application. It ensures the mock API 
    server is running before starting the UI application.
.NOTES
    Author: GitHub Copilot
    Date: April 27, 2025
#>

# Script configuration
$ErrorActionPreference = "Stop" 
$VerbosePreference = "Continue"
$InformationPreference = "Continue"  # Added to ensure Write-Information messages are visible

# Define a central function for message handling
function Write-Message {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet('Normal', 'Success', 'Warning', 'Error', 'Yellow', 'Cyan', 'Green', 'Red', 'White', 'Gray')]
        [string]$Type = 'Normal',
        
        [Parameter(Mandatory = $false)]
        [switch]$NoNewline
    )
    
    # Mapping for output methods
    switch ($Type) {
        'Normal' { 
            # Default, normal information output
            Write-Output $Message
        }
        'Success' {
            # Success messages - output as information with green color tag
            Write-Information "`e[32m$Message`e[0m"
        }
        'Warning' {
            # Warning messages - output as warning
            Write-Warning $Message
        }
        'Error' {
            # Error messages - output as error
            Write-Error $Message
        }
        'Yellow' {
            # Yellow highlighted messages
            Write-Information "`e[33m$Message`e[0m"
        }
        'Cyan' {
            # Cyan highlighted messages
            Write-Information "`e[36m$Message`e[0m"
        }
        'Green' {
            # Green highlighted messages 
            Write-Information "`e[32m$Message`e[0m"
        }
        'Red' {
            # Red highlighted messages
            Write-Information "`e[31m$Message`e[0m" 
        }
        'White' { 
            # White highlighted messages
            Write-Information "`e[37m$Message`e[0m"
        }
        'Gray' {
            # Gray highlighted messages
            Write-Information "`e[90m$Message`e[0m"
        }
    }
}
    }
}

# Define paths
$baseDir = $PSScriptRoot
$uiTarsDir = Join-Path $baseDir "apps\agent-tars"
$serverDir = Join-Path $baseDir "simple-openai-server"
$logDir = Join-Path $baseDir "logs"
$configFile = Join-Path $baseDir "apps\agent-tars\examples\presets\local-development.yaml"

# Create log directory if it doesn't exist
if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    Write-Verbose "Created log directory: $logDir"
}

# Display banner
Write-Output "================================================="
Write-Output "    UI-TARS + Omniparser Application Launcher    "
Write-Output "================================================="
Write-Output ""

function Test-ServerRunning {
    try {
        # First try: Simple TCP connection test (quick and reliable)
        $tcpClient = New-Object System.Net.Sockets.TcpClient
        $tcpClient.ReceiveTimeout = 2000  # Increase timeout
        $tcpClient.SendTimeout = 2000     # Increase timeout
        $connect = $tcpClient.BeginConnect("localhost", 8000, $null, $null)
        $wait = $connect.AsyncWaitHandle.WaitOne(2000, $false)  # Increase wait time
        if ($wait) {
            $tcpClient.EndConnect($connect)
            $tcpClient.Close()
            Write-Verbose "TCP connection successful to port 8000"
            return $true
        }
        else {
            $tcpClient.Close()
            Write-Verbose "TCP connection timeout to port 8000"
            
            # Second try: Test with netstat to see if the port is actually listening
            $netstatResult = netstat -ano | Select-String ":8000 " | Select-String "LISTENING"
            if ($netstatResult) {
                Write-Verbose "Port 8000 is listening according to netstat, but TCP connection failed"
                # If netstat shows it's listening, we'll consider it running
                return $true
            }
            
            return $false
        }
    }
    catch {
        Write-Verbose "TCP connection failed: $($_.Exception.Message)"
        return $false
    }
}

function Test-OmniparserRunning {
    try {
        # Use TCP connection for more reliable testing
        $tcpClient = New-Object System.Net.Sockets.TcpClient
        $tcpClient.ReceiveTimeout = 1000
        $tcpClient.SendTimeout = 1000
        $connect = $tcpClient.BeginConnect("localhost", 7861, $null, $null)
        $wait = $connect.AsyncWaitHandle.WaitOne(2000, $false)
        if ($wait) {
            $tcpClient.EndConnect($connect)
            $tcpClient.Close()
            Write-Verbose "TCP connection successful to port 7861"
            return $true
        }
        else {
            $tcpClient.Close()
            Write-Verbose "TCP connection timeout to port 7861"
            return $false
        }
    }
    catch {
        Write-Verbose "TCP connection failed: $($_.Exception.Message)"
        return $false
    }
}

function Stop-ProcessOnPort {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param([int]$Port)
    
    Write-Verbose "Checking for processes using port $Port..."
    
    try {
        # Find processes using the specified port
        $connections = netstat -ano | Select-String ":$Port "
        if ($connections) {
            foreach ($connection in $connections) {
                # Extract PID from netstat output
                $parts = $connection.ToString().Split(' ', [System.StringSplitOptions]::RemoveEmptyEntries)
                $processId = $parts[-1]
                
                if ($processId -match '^\d+$') {
                    try {
                        $process = Get-Process -Id $processId -ErrorAction SilentlyContinue
                        if ($process) {
                            Write-Verbose "Killing process $($process.ProcessName) (PID: $processId) using port $Port"
                            if ($PSCmdlet.ShouldProcess("Process $($process.ProcessName) (PID: $processId)", "Kill")) {
                                Stop-Process -Id $processId -Force
                                Start-Sleep -Seconds 2                            }
                        }
                    }
                    catch {
                        Write-Verbose "Could not kill process with PID $processId"
                    }
                }
            }
        }
        else {
            Write-Verbose "No processes found using port $Port"
        }
    }
    catch {
        Write-Verbose "Error checking port $Port`: $($_.Exception.Message)"
    }
}

function Start-MockServer {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param()
    
    Write-Output "Starting mock OpenAI API server..."
    
    # Kill any processes using port 8000
    Stop-ProcessOnPort -Port 8000
    
    # Check if Python is available
    try {
        $pythonVersion = python --version
        Write-Output "Using $pythonVersion"    }
    catch {
        Write-Output "Python is not installed or not in PATH."
        Write-Output "Please install Python and try again."
        exit 1
    }
    
    # Double-check if server is still running after cleanup
    if (Test-ServerRunning) {
        Write-Host "Mock API server is still running on http://localhost:8000 (cleanup may have failed)" -ForegroundColor Yellow
        Write-Host "Proceeding with launch anyway..." -ForegroundColor Yellow            return
    }
    
    # Start the server
    $serverScriptPath = Join-Path $serverDir "simple.py"
    if (-not (Test-Path $serverScriptPath)) {
        Write-Host "Error: Server script not found at $serverScriptPath" -ForegroundColor Red
        exit 1
    }
    
    if ($PSCmdlet.ShouldProcess("Mock API Server", "Start")) {
        $serverProcess = Start-Process -FilePath "python" -ArgumentList "`"$serverScriptPath`"" -NoNewWindow -PassThru
    }
    
    # Wait for server to start with improved logic
    $maxWaitTime = 10  # Increase wait time slightly
    $waited = 0
    $serverStarted = $false
    
    Write-Host "Waiting for server to start..." -ForegroundColor Yellow
    
    # Give the server more time to initialize properly
    Start-Sleep -Seconds 4
    
    # Try the health check with better retry logic
    $healthCheckAttempts = 0
    $maxHealthCheckAttempts = 5  # Increase attempts
    
    while (-not $serverStarted -and $waited -lt $maxWaitTime -and $healthCheckAttempts -lt $maxHealthCheckAttempts) {
        $healthCheckAttempts++
        Write-Verbose "Health check attempt $healthCheckAttempts of $maxHealthCheckAttempts"
        
        if (Test-ServerRunning) {
            $serverStarted = $true
            Write-Host " Server detected!" -ForegroundColor Green
        }
        else {
            Start-Sleep -Seconds 1
            $waited += 1
            Write-Host "." -NoNewline -ForegroundColor Yellow
        }
    }
      Write-Host ""
    
    if ($serverStarted) {
        Write-Host "Mock API server started successfully on http://localhost:8000" -ForegroundColor Green
    }
    else {
        # Check if the process is still running
        if ($serverProcess -and -not $serverProcess.HasExited) {
            Write-Host "Server process is running but health check failed. Continuing anyway..." -ForegroundColor Yellow
            Write-Host "You may need to manually verify the server is working at http://localhost:8000" -ForegroundColor Yellow
        }
        else {
            Write-Host "Failed to start mock API server within $maxWaitTime seconds." -ForegroundColor Red
            Write-Host "Please check if the simple-openai-server directory and simple.py file exist." -ForegroundColor Red
            exit 1
        }
    }
}

function Start-UITar {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param()
    
    Write-Host "Starting UI-TARS application..." -ForegroundColor Yellow
    
    # Return to base directory to use the workspace scripts
    if ($PSCmdlet.ShouldProcess("Working directory", "Change to $baseDir")) {
        Set-Location $baseDir
    }
    
    # Check if pnpm is available
    try {
        $pnpmVersion = pnpm --version
        Write-Host "Using pnpm version $pnpmVersion" -ForegroundColor Green
    }
    catch {
        Write-Host "pnpm is not installed or not in PATH." -ForegroundColor Red
        Write-Host "Please install pnpm and try again." -ForegroundColor Red
        exit 1
    }
      # Check if dependencies are installed and install them properly if needed
    if (-not (Test-Path "$uiTarsDir\node_modules")) {
        Write-Host "Installing dependencies in base directory..." -ForegroundColor Yellow
        # First install dependencies in the base directory
        & pnpm install
        
        # Then install dependencies in the UI-TARS directory
        Write-Host "Installing dependencies in UI-TARS directory..." -ForegroundColor Yellow
        Push-Location $uiTarsDir
        & pnpm install
        Pop-Location
    }
    
    # Check for electron-vite specifically since it's required for UI-TARS
    try {
        Push-Location $uiTarsDir
        $electronViteVersion = & pnpm list electron-vite --depth=0 2>$null
        if ($LASTEXITCODE -ne 0 -or -not $electronViteVersion -or $electronViteVersion -notmatch "electron-vite") {
            Write-Host "Installing electron-vite dependency..." -ForegroundColor Yellow
            & pnpm add -D electron-vite
        }
        Pop-Location
    }
    catch {
        Write-Host "Unable to check for electron-vite: $($_.Exception.Message)" -ForegroundColor Yellow
    }
    
    # Start UI-TARS using multiple methods in sequence until one works
    Write-Host "Launching UI-TARS..." -ForegroundColor Yellow
    
    # 1. Try using the batch file if it exists (most reliable)
    $batchFile = Join-Path $baseDir "launch-ui-tars.bat"
    if (Test-Path $batchFile) {
        try {
            Write-Host "Using batch file launcher..." -ForegroundColor Yellow
            if ($PSCmdlet.ShouldProcess("UI-TARS batch file", "Launch")) {
                Write-Verbose "Starting batch file: $batchFile"
                Start-Process -FilePath $batchFile -NoNewWindow
                Write-Host "UI-TARS is starting via batch file." -ForegroundColor Green
                return # Success - exit the function
            }
        }
        catch {
            Write-Host "Batch file method failed: $($_.Exception.Message)" -ForegroundColor Yellow
            # Continue to next method
        }
    }
      # 2. Try using package (2).json directly which has the dev:agent-tars script
    $packageFile = Join-Path -Path $baseDir -ChildPath "package (2).json" 
    if ($packageFile -and (Test-Path $packageFile)) {
        try {
            Write-Host "Using dev:agent-tars script from package (2).json..." -ForegroundColor Yellow            if ($PSCmdlet.ShouldProcess("UI-TARS application", "Launch using dev:agent-tars")) {
                # Copy package (2).json temporarily as package.json.dev to use it
                $packageJsonDev = Join-Path -Path $baseDir -ChildPath "package.json.dev"
                if ($packageFile -and $packageJsonDev) {
                    Copy-Item -Path $packageFile -Destination $packageJsonDev -Force
                
                    # Use it directly with full path
                    Start-Process -FilePath "pnpm" -ArgumentList "--filter", "agent-tars-app", "dev" -NoNewWindow -WorkingDirectory $baseDir
                }
                
                Write-Host "UI-TARS is starting via dev:agent-tars script." -ForegroundColor Green
                return # Success - exit the function
            }
        }
        catch {
            Write-Host "dev:agent-tars script method failed: $($_.Exception.Message)" -ForegroundColor Yellow
            # Continue to next method
        }
    }
    
    # 3. Try the UI-TARS run with the filter option (simplest approach)
    try {
        Write-Host "Using pnpm filter for agent-tars..." -ForegroundColor Yellow
        if ($PSCmdlet.ShouldProcess("UI-TARS application", "Launch using filter")) {
            Write-Verbose "Starting UI-TARS with: pnpm --filter agent-tars-app dev"
            Start-Process -FilePath "pnpm" -ArgumentList "--filter", "agent-tars-app", "dev" -NoNewWindow -WorkingDirectory $baseDir
            
            Write-Host "UI-TARS is starting via pnpm filter." -ForegroundColor Green
            return # Success - exit the function
        }
    }
    catch {
        Write-Host "Filter method failed: $($_.Exception.Message)" -ForegroundColor Yellow
        # Continue to next method
    }
    
    # 4. Try direct method in agent-tars directory
    try {
        Write-Host "Trying direct method in agent-tars directory..." -ForegroundColor Yellow
        if ($PSCmdlet.ShouldProcess("UI-TARS application", "Launch directly from directory")) {
            Push-Location $uiTarsDir
            Write-Verbose "Changed directory to: $uiTarsDir"
            
            # Start the process detached
            Start-Process -FilePath "pnpm" -ArgumentList "dev" -NoNewWindow -WorkingDirectory $uiTarsDir
            
            Pop-Location
            
            Write-Host "UI-TARS is starting via direct method." -ForegroundColor Green
            return # Success - exit the function
        }
    }
    catch {
        Write-Host "Direct method failed: $($_.Exception.Message)" -ForegroundColor Yellow
        # Last resort - provide instructions
    }
    
    # All methods failed - show instructions
    Write-Host "Automated UI-TARS launch failed." -ForegroundColor Red
    Write-Host "Please try one of these manual methods:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Option 1: Use the batch file" -ForegroundColor White
    Write-Host "    > .\\launch-ui-tars.bat" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Option 2: Use pnpm directly" -ForegroundColor White
    Write-Host "    > cd $uiTarsDir" -ForegroundColor Cyan
    Write-Host "    > pnpm dev" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Option 3: Try bootstrap first" -ForegroundColor White
    Write-Host "    > pnpm run bootstrap" -ForegroundColor Cyan
    Write-Host "    > cd $uiTarsDir" -ForegroundColor Cyan
    Write-Host "    > pnpm dev" -ForegroundColor Cyan
    
    # We'll still continue the script execution to keep server running
    Write-Host ""
    Write-Host "The mock API server is still running at http://localhost:8000" -ForegroundColor Green
    Write-Host "You can import the configuration from: $configFile" -ForegroundColor Cyan
}

function Start-Omniparser {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param()
    
    Write-Host "Starting Omniparser Gradio demo..." -ForegroundColor Yellow
    
    # Kill any processes using port 7861
    Stop-ProcessOnPort -Port 7861
    
    # Check if already running
    if (Test-OmniparserRunning) {
        Write-Host "Omniparser is already running on http://localhost:7861" -ForegroundColor Yellow
        return
    }
    
    # Check if weights directory exists
    $weightsDir = Join-Path $baseDir "weights"
    if (-not (Test-Path $weightsDir)) {
        Write-Host "Warning: Weights directory not found at $weightsDir" -ForegroundColor Yellow
        Write-Host "Omniparser may not work correctly without model weights." -ForegroundColor Yellow
    }
    
    # Check required weight subdirectories
    $iconDetectDir = Join-Path $weightsDir "icon_detect"
    $iconCaptionDir = Join-Path $weightsDir "icon_caption_florence"
    
    if (-not (Test-Path $iconDetectDir)) {
        Write-Host "Warning: Icon detection weights not found at $iconDetectDir" -ForegroundColor Yellow
    }
    
    if (-not (Test-Path $iconCaptionDir)) {
        Write-Host "Warning: Icon caption weights not found at $iconCaptionDir" -ForegroundColor Yellow
    }
    
    # Check gradio script exists
    $gradioScriptPath = Join-Path $baseDir "gradio_demo.py"
    if (-not (Test-Path $gradioScriptPath)) {
        Write-Host "Error: gradio_demo.py not found at $gradioScriptPath" -ForegroundColor Red
        Write-Host "Skipping Omniparser launch..." -ForegroundColor Yellow
        return
    }
    
    # Start Omniparser with better error handling for network issues and model compatibility
    Write-Host "Launching Omniparser on port 7861..." -ForegroundColor Yellow
    Write-Host "Note: First run may take time to download AI models..." -ForegroundColor Cyan
    Write-Host "If Florence-2 model fails, the script will skip Omniparser..." -ForegroundColor Cyan
    
    if ($PSCmdlet.ShouldProcess("Omniparser Gradio application", "Launch")) {
        try {
            # Create log files for Omniparser output to capture errors
            $omniparserOutLogPath = Join-Path $logDir "omniparser_out.log"
            $omniparserErrLogPath = Join-Path $logDir "omniparser_err.log"
            
            # Start Omniparser and redirect output to separate log files
            $omniparserProcess = Start-Process -FilePath "python" -ArgumentList "`"$gradioScriptPath`"" -NoNewWindow -PassThru -RedirectStandardError $omniparserErrLogPath -RedirectStandardOutput $omniparserOutLogPath
            
            # Give it a moment to start and check if it fails immediately
            Start-Sleep -Seconds 3
              if ($omniparserProcess.HasExited) {
                Write-Host "Omniparser failed to start. Check logs in: $logDir" -ForegroundColor Red                # Try to read the first few lines of the logs to show the error
                if ($omniparserErrLogPath -and (Test-Path $omniparserErrLogPath)) {
                    $logContent = Get-Content $omniparserErrLogPath -Head 10 -ErrorAction SilentlyContinue
                    if ($logContent) {
                        Write-Host "Error details:" -ForegroundColor Yellow
                        $logContent | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }
                    }
                }
                elseif ($omniparserOutLogPath -and (Test-Path $omniparserOutLogPath)) {
                    $logContent = Get-Content $omniparserOutLogPath -Head 10 -ErrorAction SilentlyContinue
                    if ($logContent) {
                        Write-Host "Output details:" -ForegroundColor Yellow
                        $logContent | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }
                    }
                }
                
                Write-Host "Common causes:" -ForegroundColor Yellow
                Write-Host "  • Missing or incompatible Florence-2 model weights" -ForegroundColor Yellow
                Write-Host "  • Network issues downloading models" -ForegroundColor Yellow
                Write-Host "  • Incompatible PyTorch/Transformers versions" -ForegroundColor Yellow
                Write-Host "Continuing without Omniparser..." -ForegroundColor Yellow
                return
            }
        }
        catch {
            Write-Host "Error starting Omniparser: $($_.Exception.Message)" -ForegroundColor Red
            Write-Host "Continuing without Omniparser..." -ForegroundColor Yellow
            return
        }
    }
    
    # Wait for Omniparser to start with extended timeout for model downloads
    $maxWaitTime = 30  # Increase timeout significantly for model downloads
    $waited = 0
    $omniparserStarted = $false
    
    Write-Host "Waiting for Omniparser to start (this may take several minutes for model downloads)..." -ForegroundColor Yellow
    Write-Host "If this is the first run, models need to be downloaded from the internet..." -ForegroundColor Cyan
    
    # Give the server more time to initialize and download models
    Start-Sleep -Seconds 5
    
    while (-not $omniparserStarted -and $waited -lt $maxWaitTime) {
        # Check if process crashed
        if ($omniparserProcess.HasExited) {
            Write-Host ""
            Write-Host "Omniparser process has crashed during startup." -ForegroundColor Red              # Show error logs if available
            if ($logDir) {
                $omniparserErrLogPath = Join-Path $logDir "omniparser_err.log"
                $omniparserOutLogPath = Join-Path $logDir "omniparser_out.log"
                
                if ($omniparserErrLogPath -and (Test-Path $omniparserErrLogPath)) {
                    Write-Host "Error log:" -ForegroundColor Yellow
                    $logContent = Get-Content $omniparserErrLogPath -Tail 15 -ErrorAction SilentlyContinue
                    if ($logContent) {
                        $logContent | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }
                    }
                }
                
                if ($omniparserOutLogPath -and (Test-Path $omniparserOutLogPath)) {
                    Write-Host "Output log:" -ForegroundColor Yellow
                    $logContent = Get-Content $omniparserOutLogPath -Tail 5 -ErrorAction SilentlyContinue
                    if ($logContent) {
                        $logContent | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }
                    }
                }
            }
            
            Write-Host "Continuing without Omniparser..." -ForegroundColor Yellow
            return
        }
        
        if (Test-OmniparserRunning) {
            $omniparserStarted = $true
            Write-Host " Omniparser detected!" -ForegroundColor Green
        }
        else {
            Start-Sleep -Seconds 3  # Longer intervals for model loading
            $waited += 3
            Write-Host "." -NoNewline -ForegroundColor Yellow
        }
    }
    
    Write-Host ""
    
    if ($omniparserStarted) {
        Write-Host "Omniparser started successfully on http://localhost:7861" -ForegroundColor Green
    }
    else {
        # Check if the process is still running
        if ($omniparserProcess -and -not $omniparserProcess.HasExited) {
            Write-Host "Omniparser process is running but health check failed." -ForegroundColor Yellow
            Write-Host "This is normal if models are still downloading." -ForegroundColor Yellow
            Write-Host "Check http://localhost:7861 manually in a few minutes." -ForegroundColor Cyan
            Write-Host "Model downloads can take 5-15 minutes depending on internet speed." -ForegroundColor Cyan
        }
        else {
            Write-Host "Omniparser process has stopped." -ForegroundColor Red
            Write-Host "This may be due to:" -ForegroundColor Yellow
            Write-Host "  • Network issues downloading models" -ForegroundColor Yellow
            Write-Host "  • Missing dependencies" -ForegroundColor Yellow
            Write-Host "  • Insufficient disk space" -ForegroundColor Yellow
            Write-Host "  • Florence-2 model compatibility issues" -ForegroundColor Yellow
            Write-Host "Check the console output above for specific error messages." -ForegroundColor Yellow
        }
    }
}

function Install-OmniparserDependency {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param()
    
    Write-Host "Checking Omniparser dependencies..." -ForegroundColor Yellow
    
    # First check if Python is available
    try {
        $pythonVersion = & python --version 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Python is not installed or not in PATH." -ForegroundColor Yellow
            Write-Host "Skipping Omniparser dependency installation..." -ForegroundColor Yellow
            return
        }
        Write-Verbose "Found Python: $pythonVersion"
    }
    catch {
        Write-Host "Python is not available. Skipping Omniparser dependency installation..." -ForegroundColor Yellow
        return
    }
    
    # Check if requirements.txt exists
    $requirementsFile = Join-Path $baseDir "requirements.txt"    if (-not (Test-Path $requirementsFile)) {
        Write-Host "Warning: requirements.txt not found at $requirementsFile" -ForegroundColor Yellow
        Write-Host "Continuing without dependency installation..." -ForegroundColor Yellow
        return
    }
    
    # Try to import torch to see if dependencies are already installed
    try {
        Write-Verbose "Checking if Python dependencies are installed..."
        $pythonCheck = & python -c "import torch; import gradio; import PIL; print('Dependencies OK')" 2>&1
        if ($LASTEXITCODE -eq 0 -and $pythonCheck -match "Dependencies OK") {
            Write-Host "Omniparser dependencies are already installed." -ForegroundColor Green
            return
        }
        else {
            Write-Verbose "Dependencies check failed with exit code $LASTEXITCODE, will attempt installation..."
            Write-Verbose "Output: $pythonCheck"
        }
    }
    catch {
        Write-Verbose "Dependencies check failed with exception: $($_.Exception.Message)"
        # Dependencies not installed, continue with installation
    }
    
    Write-Host "Installing Omniparser dependencies from requirements.txt..." -ForegroundColor Yellow
    Write-Host "This may take several minutes for PyTorch and other AI packages..." -ForegroundColor Cyan
      try {
        # Install requirements with pip
        if ($PSCmdlet.ShouldProcess("Python dependencies from requirements.txt", "Install")) {
            $installProcess = Start-Process -FilePath "python" -ArgumentList "-m", "pip", "install", "-r", "`"$requirementsFile`"" -NoNewWindow -Wait -PassThru
            
            if ($installProcess.ExitCode -eq 0) {
                Write-Host "Dependencies installed successfully!" -ForegroundColor Green
            }
            else {
                Write-Host "Warning: Some dependencies may not have installed correctly (exit code: $($installProcess.ExitCode))" -ForegroundColor Yellow
                Write-Host "Omniparser may not work properly." -ForegroundColor Yellow
            }
        }
    }
    catch {
        Write-Host "Error installing dependencies: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "You may need to install them manually with: pip install -r requirements.txt" -ForegroundColor Yellow
    }
}

# Main execution
try {
    Write-Host "🚀 Starting all components..." -ForegroundColor Cyan
    Write-Host ""
    
    # Clear the terminal input buffer before starting
    while ($Host.UI.RawUI.KeyAvailable) {
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
    
    # Install Omniparser dependencies first (before starting anything)
    Install-OmniparserDependency
    Write-Host ""
      # Start the mock server first
    Start-MockServer
    Write-Host ""
    
    # Try to start Omniparser second (it takes time to load models)
    try {
        Start-Omniparser
    }
    catch {
        Write-Host "Omniparser startup encountered an error: $($_.Exception.Message)" -ForegroundColor Yellow
        Write-Host "This is expected if Florence-2 model compatibility issues exist." -ForegroundColor Yellow
        Write-Host "Continuing with other components..." -ForegroundColor Yellow
    }
    Write-Host ""
    
    # Finally start UI-TARS
    Start-UITar
    
    Write-Host ""
    Write-Host "=================================================" -ForegroundColor Cyan
    Write-Host "🎉 All services are now running!" -ForegroundColor Green
    Write-Host ""
    Write-Host "📍 Service URLs:" -ForegroundColor Yellow
    Write-Host "   • Mock API Server: http://localhost:8000" -ForegroundColor White
    
    # Check if Omniparser is actually running before advertising it
    if (Test-OmniparserRunning) {
        Write-Host "   • Omniparser:      http://localhost:7861" -ForegroundColor White
    }
    else {
        Write-Host "   • Omniparser:      Not available (see warnings above)" -ForegroundColor Gray
    }
    
    Write-Host "   • UI-TARS:         Electron app (launching...)" -ForegroundColor White
    Write-Host ""
    Write-Host "⚙️  To configure UI-TARS, go to Settings and import:" -ForegroundColor Cyan
    Write-Host "   $configFile" -ForegroundColor White
    Write-Host "=================================================" -ForegroundColor Cyan
    
    # Keep the window open
    Write-Host ""
    Write-Host "Press any key to exit this launcher (all services will continue running)..." -ForegroundColor Yellow
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}
catch {
    Write-Host "An error occurred:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host ""
    Write-Host "Press any key to exit..." -ForegroundColor Yellow
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}
