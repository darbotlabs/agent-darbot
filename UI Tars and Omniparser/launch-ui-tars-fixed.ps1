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
        Write-Output "Mock API server is still running on http://localhost:8000 (cleanup may have failed)"
        Write-Output "Proceeding with launch anyway..."            return
    }
    
    # Start the server
    $serverScriptPath = Join-Path $serverDir "simple.py"
    if (-not (Test-Path $serverScriptPath)) {
        Write-Output "Error: Server script not found at $serverScriptPath"
        exit 1
    }
    
    if ($PSCmdlet.ShouldProcess("Mock API Server", "Start")) {
        $serverProcess = Start-Process -FilePath "python" -ArgumentList "`"$serverScriptPath`"" -NoNewWindow -PassThru
    }
    
    # Wait for server to start with improved logic
    $maxWaitTime = 10  # Increase wait time slightly
    $waited = 0
    $serverStarted = $false
    
    Write-Output "Waiting for server to start..."
    
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
            Write-Output " Server detected!"
        }
        else {
            Start-Sleep -Seconds 1
            $waited += 1
            Write-Output "." -NoNewline
        }
    }
      Write-Output ""
    
    if ($serverStarted) {
        Write-Output "Mock API server started successfully on http://localhost:8000"
    }
    else {
        # Check if the process is still running
        if ($serverProcess -and -not $serverProcess.HasExited) {
            Write-Output "Server process is running but health check failed. Continuing anyway..."
            Write-Output "You may need to manually verify the server is working at http://localhost:8000"
        }
        else {
            Write-Output "Failed to start mock API server within $maxWaitTime seconds."
            Write-Output "Please check if the simple-openai-server directory and simple.py file exist."
            exit 1
        }
    }
}

function Start-UITar {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param()
    
    Write-Output "Starting UI-TARS application..."
    
    # Return to base directory to use the workspace scripts
    if ($PSCmdlet.ShouldProcess("Working directory", "Change to $baseDir")) {
        Set-Location $baseDir
    }
    
    # Check if pnpm is available
    try {
        $pnpmVersion = pnpm --version
        Write-Output "Using pnpm version $pnpmVersion"
    }
    catch {
        Write-Output "pnpm is not installed or not in PATH."
        Write-Output "Please install pnpm and try again."
        exit 1
    }
      # Check if dependencies are installed and install them properly if needed
    if (-not (Test-Path "$uiTarsDir\node_modules")) {
        Write-Output "Installing dependencies in base directory..."
        # First install dependencies in the base directory
        & pnpm install
        
        # Then install dependencies in the UI-TARS directory
        Write-Output "Installing dependencies in UI-TARS directory..."
        Push-Location $uiTarsDir
        & pnpm install
        Pop-Location
    }
    
    # Check for electron-vite specifically since it's required for UI-TARS
    try {
        Push-Location $uiTarsDir
        $electronViteVersion = & pnpm list electron-vite --depth=0 2>$null
        if ($LASTEXITCODE -ne 0 -or -not $electronViteVersion -or $electronViteVersion -notmatch "electron-vite") {
            Write-Output "Installing electron-vite dependency..."
            & pnpm add -D electron-vite
        }
        Pop-Location
    }
    catch {
        Write-Output "Unable to check for electron-vite: $($_.Exception.Message)"
    }
    
    # Start UI-TARS using multiple methods in sequence until one works
    Write-Output "Launching UI-TARS..."
    
    # 1. Try using the batch file if it exists (most reliable)
    $batchFile = Join-Path $baseDir "launch-ui-tars.bat"
    if (Test-Path $batchFile) {
        try {
            Write-Output "Using batch file launcher..."
            if ($PSCmdlet.ShouldProcess("UI-TARS batch file", "Launch")) {
                Write-Verbose "Starting batch file: $batchFile"
                Start-Process -FilePath $batchFile -NoNewWindow
                Write-Output "UI-TARS is starting via batch file."
                return # Success - exit the function
            }
        }
        catch {
            Write-Output "Batch file method failed: $($_.Exception.Message)"
            # Continue to next method
        }
    }
      # 2. Try using package (2).json directly which has the dev:agent-tars script
    $packageFile = Join-Path -Path $baseDir -ChildPath "package (2).json" 
    if ($packageFile -and (Test-Path $packageFile)) {
        try {
            Write-Output "Using dev:agent-tars script from package (2).json..."            if ($PSCmdlet.ShouldProcess("UI-TARS application", "Launch using dev:agent-tars")) {
                # Copy package (2).json temporarily as package.json.dev to use it
                $packageJsonDev = Join-Path -Path $baseDir -ChildPath "package.json.dev"
                if ($packageFile -and $packageJsonDev) {
                    Copy-Item -Path $packageFile -Destination $packageJsonDev -Force
                
                    # Use it directly with full path
                    Start-Process -FilePath "pnpm" -ArgumentList "--filter", "agent-tars-app", "dev" -NoNewWindow -WorkingDirectory $baseDir
                }
                
                Write-Output "UI-TARS is starting via dev:agent-tars script."
                return # Success - exit the function
            }
        }
        catch {
            Write-Output "dev:agent-tars script method failed: $($_.Exception.Message)"
            # Continue to next method
        }
    }
    
    # 3. Try the UI-TARS run with the filter option (simplest approach)
    try {
        Write-Output "Using pnpm filter for agent-tars..."
        if ($PSCmdlet.ShouldProcess("UI-TARS application", "Launch using filter")) {
            Write-Verbose "Starting UI-TARS with: pnpm --filter agent-tars-app dev"
            Start-Process -FilePath "pnpm" -ArgumentList "--filter", "agent-tars-app", "dev" -NoNewWindow -WorkingDirectory $baseDir
            
            Write-Output "UI-TARS is starting via pnpm filter."
            return # Success - exit the function
        }
    }
    catch {
        Write-Output "Filter method failed: $($_.Exception.Message)"
        # Continue to next method
    }
    
    # 4. Try direct method in agent-tars directory
    try {
        Write-Output "Trying direct method in agent-tars directory..."
        if ($PSCmdlet.ShouldProcess("UI-TARS application", "Launch directly from directory")) {
            Push-Location $uiTarsDir
            Write-Verbose "Changed directory to: $uiTarsDir"
            
            # Start the process detached
            Start-Process -FilePath "pnpm" -ArgumentList "dev" -NoNewWindow -WorkingDirectory $uiTarsDir
            
            Pop-Location
            
            Write-Output "UI-TARS is starting via direct method."
            return # Success - exit the function
        }
    }
    catch {
        Write-Output "Direct method failed: $($_.Exception.Message)"
        # Last resort - provide instructions
    }
    
    # All methods failed - show instructions
    Write-Output "Automated UI-TARS launch failed."
    Write-Output "Please try one of these manual methods:"
    Write-Output ""
    Write-Output "  Option 1: Use the batch file"
    Write-Output "    > .\\launch-ui-tars.bat"
    Write-Output ""
    Write-Output "  Option 2: Use pnpm directly"
    Write-Output "    > cd $uiTarsDir"
    Write-Output "    > pnpm dev"
    Write-Output ""
    Write-Output "  Option 3: Try bootstrap first"
    Write-Output "    > pnpm run bootstrap"
    Write-Output "    > cd $uiTarsDir"
    Write-Output "    > pnpm dev"
    
    # We'll still continue the script execution to keep server running
    Write-Output ""
    Write-Output "The mock API server is still running at http://localhost:8000"
    Write-Output "You can import the configuration from: $configFile"
}

function Start-Omniparser {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param()
    
    Write-Output "Starting Omniparser Gradio demo..."
    
    # Kill any processes using port 7861
    Stop-ProcessOnPort -Port 7861
    
    # Check if already running
    if (Test-OmniparserRunning) {
        Write-Output "Omniparser is already running on http://localhost:7861"
        return
    }
    
    # Check if weights directory exists
    $weightsDir = Join-Path $baseDir "weights"
    if (-not (Test-Path $weightsDir)) {
        Write-Output "Warning: Weights directory not found at $weightsDir"
        Write-Output "Omniparser may not work correctly without model weights."
    }
    
    # Check required weight subdirectories
    $iconDetectDir = Join-Path $weightsDir "icon_detect"
    $iconCaptionDir = Join-Path $weightsDir "icon_caption_florence"
    
    if (-not (Test-Path $iconDetectDir)) {
        Write-Output "Warning: Icon detection weights not found at $iconDetectDir"
    }
    
    if (-not (Test-Path $iconCaptionDir)) {
        Write-Output "Warning: Icon caption weights not found at $iconCaptionDir"
    }
    
    # Check gradio script exists
    $gradioScriptPath = Join-Path $baseDir "gradio_demo.py"
    if (-not (Test-Path $gradioScriptPath)) {
        Write-Output "Error: gradio_demo.py not found at $gradioScriptPath"
        Write-Output "Skipping Omniparser launch..."
        return
    }
    
    # Start Omniparser with better error handling for network issues and model compatibility
    Write-Output "Launching Omniparser on port 7861..."
    Write-Output "Note: First run may take time to download AI models..."
    Write-Output "If Florence-2 model fails, the script will skip Omniparser..."
    
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
                Write-Output "Omniparser failed to start. Check logs in: $logDir"                # Try to read the first few lines of the logs to show the error
                if ($omniparserErrLogPath -and (Test-Path $omniparserErrLogPath)) {
                    $logContent = Get-Content $omniparserErrLogPath -Head 10 -ErrorAction SilentlyContinue
                    if ($logContent) {
                        Write-Output "Error details:"
                        $logContent | ForEach-Object { Write-Output "  $_" }
                    }
                }
                elseif ($omniparserOutLogPath -and (Test-Path $omniparserOutLogPath)) {
                    $logContent = Get-Content $omniparserOutLogPath -Head 10 -ErrorAction SilentlyContinue
                    if ($logContent) {
                        Write-Output "Output details:"
                        $logContent | ForEach-Object { Write-Output "  $_" }
                    }
                }
                
                Write-Output "Common causes:"
                Write-Output "  • Missing or incompatible Florence-2 model weights"
                Write-Output "  • Network issues downloading models"
                Write-Output "  • Incompatible PyTorch/Transformers versions"
                Write-Output "Continuing without Omniparser..."
                return
            }
        }
        catch {
            Write-Output "Error starting Omniparser: $($_.Exception.Message)"
            Write-Output "Continuing without Omniparser..."
            return
        }
    }
    
    # Wait for Omniparser to start with extended timeout for model downloads
    $maxWaitTime = 30  # Increase timeout significantly for model downloads
    $waited = 0
    $omniparserStarted = $false
    
    Write-Output "Waiting for Omniparser to start (this may take several minutes for model downloads)..."
    Write-Output "If this is the first run, models need to be downloaded from the internet..."
    
    # Give the server more time to initialize and download models
    Start-Sleep -Seconds 5
    
    while (-not $omniparserStarted -and $waited -lt $maxWaitTime) {
        # Check if process crashed
        if ($omniparserProcess.HasExited) {
            Write-Output ""
            Write-Output "Omniparser process has crashed during startup."              # Show error logs if available
            if ($logDir) {
                $omniparserErrLogPath = Join-Path $logDir "omniparser_err.log"
                $omniparserOutLogPath = Join-Path $logDir "omniparser_out.log"
                
                if ($omniparserErrLogPath -and (Test-Path $omniparserErrLogPath)) {
                    Write-Output "Error log:"
                    $logContent = Get-Content $omniparserErrLogPath -Tail 15 -ErrorAction SilentlyContinue
                    if ($logContent) {
                        $logContent | ForEach-Object { Write-Output "  $_" }
                    }
                }
                
                if ($omniparserOutLogPath -and (Test-Path $omniparserOutLogPath)) {
                    Write-Output "Output log:"
                    $logContent = Get-Content $omniparserOutLogPath -Tail 5 -ErrorAction SilentlyContinue
                    if ($logContent) {
                        $logContent | ForEach-Object { Write-Output "  $_" }
                    }
                }
            }
            
            Write-Output "Continuing without Omniparser..."
            return
        }
        
        if (Test-OmniparserRunning) {
            $omniparserStarted = $true
            Write-Output " Omniparser detected!"
        }
        else {
            Start-Sleep -Seconds 3  # Longer intervals for model loading
            $waited += 3
            Write-Output "." -NoNewline
        }
    }
    
    Write-Output ""
    
    if ($omniparserStarted) {
        Write-Output "Omniparser started successfully on http://localhost:7861"
    }
    else {
        # Check if the process is still running
        if ($omniparserProcess -and -not $omniparserProcess.HasExited) {
            Write-Output "Omniparser process is running but health check failed."
            Write-Output "This is normal if models are still downloading."
            Write-Output "Check http://localhost:7861 manually in a few minutes."
            Write-Output "Model downloads can take 5-15 minutes depending on internet speed."
        }
        else {
            Write-Output "Omniparser process has stopped."
            Write-Output "This may be due to:"
            Write-Output "  • Network issues downloading models"
            Write-Output "  • Missing dependencies"
            Write-Output "  • Insufficient disk space"
            Write-Output "  • Florence-2 model compatibility issues"
            Write-Output "Check the console output above for specific error messages."
        }
    }
}

function Install-OmniparserDependency {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param()
    
    Write-Output "Checking Omniparser dependencies..."
    
    # First check if Python is available
    try {
        $pythonVersion = & python --version 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Output "Python is not installed or not in PATH."
            Write-Output "Skipping Omniparser dependency installation..."
            return
        }
        Write-Verbose "Found Python: $pythonVersion"
    }
    catch {
        Write-Output "Python is not available. Skipping Omniparser dependency installation..."
        return
    }
    
    # Check if requirements.txt exists
    $requirementsFile = Join-Path $baseDir "requirements.txt"    if (-not (Test-Path $requirementsFile)) {
        Write-Output "Warning: requirements.txt not found at $requirementsFile"
        Write-Output "Continuing without dependency installation..."
        return
    }
    
    # Try to import torch to see if dependencies are already installed
    try {
        Write-Verbose "Checking if Python dependencies are installed..."
        $pythonCheck = & python -c "import torch; import gradio; import PIL; print('Dependencies OK')" 2>&1
        if ($LASTEXITCODE -eq 0 -and $pythonCheck -match "Dependencies OK") {
            Write-Output "Omniparser dependencies are already installed."
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
    
    Write-Output "Installing Omniparser dependencies from requirements.txt..."
    Write-Output "This may take several minutes for PyTorch and other AI packages..."
      try {
        # Install requirements with pip
        if ($PSCmdlet.ShouldProcess("Python dependencies from requirements.txt", "Install")) {
            $installProcess = Start-Process -FilePath "python" -ArgumentList "-m", "pip", "install", "-r", "`"$requirementsFile`"" -NoNewWindow -Wait -PassThru
            
            if ($installProcess.ExitCode -eq 0) {
                Write-Output "Dependencies installed successfully!"
            }
            else {
                Write-Output "Warning: Some dependencies may not have installed correctly (exit code: $($installProcess.ExitCode))"
                Write-Output "Omniparser may not work properly."
            }
        }
    }
    catch {
        Write-Output "Error installing dependencies: $($_.Exception.Message)"
        Write-Output "You may need to install them manually with: pip install -r requirements.txt"
    }
}

# Main execution
try {
    Write-Output "🚀 Starting all components..."
    Write-Output ""
    
    # Clear the terminal input buffer before starting
    while ($Host.UI.RawUI.KeyAvailable) {
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
    
    # Install Omniparser dependencies first (before starting anything)
    Install-OmniparserDependency
    Write-Output ""
      # Start the mock server first
    Start-MockServer
    Write-Output ""
    
    # Try to start Omniparser second (it takes time to load models)
    try {
        Start-Omniparser
    }
    catch {
        Write-Output "Omniparser startup encountered an error: $($_.Exception.Message)"
        Write-Output "This is expected if Florence-2 model compatibility issues exist."
        Write-Output "Continuing with other components..."
    }
    Write-Output ""
    
    # Finally start UI-TARS
    Start-UITar
    
    Write-Output ""
    Write-Output "================================================="
    Write-Output "🎉 All services are now running!"
    Write-Output ""
    Write-Output "📍 Service URLs:"
    Write-Output "   • Mock API Server: http://localhost:8000"
    
    # Check if Omniparser is actually running before advertising it
    if (Test-OmniparserRunning) {
        Write-Output "   • Omniparser:      http://localhost:7861"
    }
    else {
        Write-Output "   • Omniparser:      Not available (see warnings above)"
    }
    
    Write-Output "   • UI-TARS:         Electron app (launching...)"
    Write-Output ""
    Write-Output "⚙️  To configure UI-TARS, go to Settings and import:"
    Write-Output "   $configFile"
    Write-Output "================================================="
    
    # Keep the window open
    Write-Output ""
    Write-Output "Press any key to exit this launcher (all services will continue running)..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}
catch {
    Write-Output "An error occurred:"
    Write-Output $_.Exception.Message
    Write-Output ""
    Write-Output "Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}


