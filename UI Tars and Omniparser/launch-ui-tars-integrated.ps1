#Requires -Version 5.0
<#
.SYNOPSIS
    Launches UI-TARS with Omniparser integration and all necessary components.
.DESCRIPTION
    This script starts the mock API server, Omniparser Gradio demo, and the UI-TARS Electron application.
    It ensures all services are running before starting the UI application.
.NOTES
    Author: GitHub Copilot
    Date: May 24, 2025
#>

# Script configuration
$ErrorActionPreference = "Stop" 
$VerbosePreference = "Continue"

# Define paths
$baseDir = $PSScriptRoot
$uiTarsDir = Join-Path $baseDir "apps\agent-tars"
$serverDir = Join-Path $baseDir "simple-openai-server"
$logDir = Join-Path $baseDir "logs"
$dateStamp = Get-Date -Format "yyyyMMdd_HHmmss"
$configFile = Join-Path $baseDir "apps\agent-tars\examples\presets\local-development.yaml"

# Create log directory if it doesn't exist
if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    Write-Verbose "Created log directory: $logDir"
}

# Display banner
Write-Host "=================================================" -ForegroundColor Cyan
Write-Host "    UI-TARS + Omniparser Application Launcher    " -ForegroundColor Cyan
Write-Host "=================================================" -ForegroundColor Cyan
Write-Host ""

function Test-ServerRunning {
    param([int]$Port = 8000)
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:$Port/" -UseBasicParsing -TimeoutSec 3
        if ($response.StatusCode -eq 200) {
            return $true
        }
    }
    catch {
        # If that fails, try checking if the port is listening
        try {
            $tcpClient = New-Object System.Net.Sockets.TcpClient
            $tcpClient.ReceiveTimeout = 1000
            $tcpClient.SendTimeout = 1000
            $tcpClient.Connect("localhost", $Port)
            $tcpClient.Close()
            return $true
        }
        catch {
            return $false
        }
    }
    return $false
}

function Stop-ProcessOnPort {
    param([int]$Port)
    
    Write-Host "Checking for processes using port $Port..." -ForegroundColor Yellow
    
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
                            Write-Host "Killing process $($process.ProcessName) (PID: $processId) using port $Port" -ForegroundColor Red
                            Stop-Process -Id $processId -Force
                            Start-Sleep -Seconds 2
                        }
                    }
                    catch {
                        Write-Host "Could not kill process with PID $processId" -ForegroundColor Yellow
                    }
                }
            }
        }
        else {
            Write-Host "No processes found using port $Port" -ForegroundColor Green
        }
    }
    catch {
        Write-Host "Error checking port $Port`: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

function Start-MockServer {
    Write-Host "Starting mock OpenAI API server..." -ForegroundColor Yellow
    
    # Kill any processes using port 8000
    Stop-ProcessOnPort -Port 8000
    
    # Check if Python is available
    try {
        $pythonVersion = python --version
        Write-Host "Using $pythonVersion" -ForegroundColor Green
    }
    catch {
        Write-Host "Python is not installed or not in PATH." -ForegroundColor Red
        Write-Host "Please install Python and try again." -ForegroundColor Red
        exit 1
    }
    
    # Double-check if server is still running after cleanup
    if (Test-ServerRunning -Port 8000) {
        Write-Host "Mock API server is still running on http://localhost:8000 (cleanup may have failed)" -ForegroundColor Yellow
        Write-Host "Proceeding with launch anyway..." -ForegroundColor Yellow
        return
    }
    
    # Start the server
    $serverScriptPath = Join-Path $serverDir "simple.py"
    $serverProcess = Start-Process -FilePath "python" -ArgumentList "`"$serverScriptPath`"" -NoNewWindow -PassThru
    
    # Wait for server to start
    $maxWaitTime = 8
    $waited = 0
    $serverStarted = $false
    
    Write-Host "Waiting for mock server to start..." -ForegroundColor Yellow
    Start-Sleep -Seconds 3
    
    $healthCheckAttempts = 0
    $maxHealthCheckAttempts = 3
    
    while (-not $serverStarted -and $waited -lt $maxWaitTime -and $healthCheckAttempts -lt $maxHealthCheckAttempts) {
        $healthCheckAttempts++
        if (Test-ServerRunning -Port 8000) {
            $serverStarted = $true
            Write-Host " Mock server detected!" -ForegroundColor Green
        }
        else {
            Start-Sleep -Seconds 2
            $waited += 2
            Write-Host "." -NoNewline -ForegroundColor Yellow
        }
    }
    
    Write-Host ""
    
    if ($serverStarted) {
        Write-Host "Mock API server started successfully on http://localhost:8000" -ForegroundColor Green
    }
    else {
        if ($serverProcess -and -not $serverProcess.HasExited) {
            Write-Host "Server process is running but health check failed. Continuing anyway..." -ForegroundColor Yellow
        }
        else {
            Write-Host "Failed to start mock API server." -ForegroundColor Red
            exit 1
        }
    }
}

function Start-Omniparser {
    Write-Host "Starting Omniparser Gradio demo..." -ForegroundColor Yellow
    
    # Kill any processes using port 7860
    Stop-ProcessOnPort -Port 7860
    
    # Check if weights directory exists
    if (-not (Test-Path "$baseDir\weights")) {
        Write-Host "Weights directory not found. You may need to run setup_weights.ps1 first." -ForegroundColor Yellow
        Write-Host "Continuing without Omniparser..." -ForegroundColor Yellow
        return
    }
    
    # Configure Python environment
    try {
        $env:PYTHONPATH = $baseDir
        
        # Start Omniparser Gradio demo
        $omniparserProcess = Start-Process -FilePath "python" -ArgumentList "`"$baseDir\gradio_demo.py`"" -NoNewWindow -PassThru -WorkingDirectory $baseDir
        
        # Wait for Omniparser to start
        $maxWaitTime = 15
        $waited = 0
        $omniparserStarted = $false
        
        Write-Host "Waiting for Omniparser to start..." -ForegroundColor Yellow
        Start-Sleep -Seconds 5
        
        while (-not $omniparserStarted -and $waited -lt $maxWaitTime) {
            if (Test-ServerRunning -Port 7860) {
                $omniparserStarted = $true
                Write-Host " Omniparser detected!" -ForegroundColor Green
            }
            else {
                Start-Sleep -Seconds 2
                $waited += 2
                Write-Host "." -NoNewline -ForegroundColor Yellow
            }
        }
        
        Write-Host ""
        
        if ($omniparserStarted) {
            Write-Host "Omniparser started successfully on http://localhost:7860" -ForegroundColor Green
        }
        else {
            if ($omniparserProcess -and -not $omniparserProcess.HasExited) {
                Write-Host "Omniparser process is running but health check failed. Continuing anyway..." -ForegroundColor Yellow
            }
            else {
                Write-Host "Failed to start Omniparser. Continuing without it..." -ForegroundColor Yellow
            }
        }
    }
    catch {
        Write-Host "Error starting Omniparser: $($_.Exception.Message)" -ForegroundColor Yellow
        Write-Host "Continuing without Omniparser..." -ForegroundColor Yellow
    }
}

function Start-UITars {
    Write-Host "Starting UI-TARS Electron application..." -ForegroundColor Yellow
    
    # Return to base directory to use the workspace scripts
    Set-Location $baseDir
    
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
    
    # Check if dependencies are installed
    if (-not (Test-Path "$uiTarsDir\node_modules")) {
        Write-Host "Installing dependencies..." -ForegroundColor Yellow
        pnpm install
    }
    
    # Start UI-TARS using the workspace script
    Write-Host "Launching UI-TARS Electron app..." -ForegroundColor Yellow
    Start-Process -FilePath "pnpm" -ArgumentList "run", "dev:ui-tars" -NoNewWindow
    
    Write-Host "UI-TARS is starting. Please wait for the Electron application window to appear." -ForegroundColor Green
    Write-Host ""
    Write-Host "Available services:" -ForegroundColor Cyan
    Write-Host "  - Mock API Server: http://localhost:8000" -ForegroundColor White
    Write-Host "  - Omniparser Demo: http://localhost:7860" -ForegroundColor White
    Write-Host "  - UI-TARS Electron App: Starting..." -ForegroundColor White
}

# Main execution
try {
    # Start services in order
    Start-MockServer
    Start-Omniparser
    Start-UITars
    
    Write-Host ""
    Write-Host "=================================================" -ForegroundColor Cyan
    Write-Host "UI-TARS + Omniparser environment is now running!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Configuration for UI-TARS:" -ForegroundColor Cyan
    Write-Host "  - LLM API URL: http://localhost:8000/v1" -ForegroundColor White
    Write-Host "  - Model Name: mistralai/Mixtral-8x7B-Instruct-v0.1" -ForegroundColor White
    Write-Host "  - Omniparser: http://localhost:7860" -ForegroundColor White
    Write-Host "=================================================" -ForegroundColor Cyan
    
    # Keep the window open
    Write-Host "Press any key to exit this launcher (services will continue running)..." -ForegroundColor Yellow
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
