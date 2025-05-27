# UI-TARS Desktop Setup Script for Windows (PowerShell)
# This script checks for Node.js and pnpm, installs dependencies, and starts the dev server.

# Fail fast on any errors
$ErrorActionPreference = "Stop"

# Guard: ensure we're inside UI-Tars\Desktop
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$expectedPath = "UI-Tars\Desktop"
if (-not ($scriptDir -like "*$expectedPath")) {
    Write-Host "[UI-TARS] ERROR: This script must be run from the UI-Tars\Desktop directory." -ForegroundColor Red
    Write-Host "[UI-TARS] Current location: $scriptDir" -ForegroundColor Red
    Write-Host "[UI-TARS] Please change to the UI-Tars\Desktop directory and try again." -ForegroundColor Red
    exit 1
}

Write-Host "[UI-TARS] Checking prerequisites..."

# Check Node.js
if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
    Write-Host "Node.js is not installed. Please install Node.js v20.x or higher from https://nodejs.org/ and re-run this script."
    exit 1
}

# Check pnpm
if (-not (Get-Command pnpm -ErrorAction SilentlyContinue)) {
    Write-Host "pnpm is not installed. Installing pnpm globally..."
    npm install -g pnpm
}

# Move to UI-Tars/Desktop directory
Set-Location $scriptDir

Write-Host "[UI-TARS] Installing dependencies with pnpm..."
pnpm install
if ($LASTEXITCODE -ne 0) {
    Write-Host "[UI-TARS] ERROR: Failed to install dependencies." -ForegroundColor Red
    exit $LASTEXITCODE
}

Write-Host "[UI-TARS] Bootstrapping workspace..."
pnpm run bootstrap
if ($LASTEXITCODE -ne 0) {
    Write-Host "[UI-TARS] ERROR: Failed to bootstrap workspace." -ForegroundColor Red
    exit $LASTEXITCODE
}

Write-Host "[UI-TARS] Starting UI-TARS Desktop in development mode..."
pnpm run dev:ui-tars
