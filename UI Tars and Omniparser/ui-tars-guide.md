# UI-TARS Setup and Launch Guide

## Overview

This guide explains how to set up and run UI-TARS with a mock LLM server for development and testing purposes.

## Components

1. **Mock API Server**: A simple Python server that mimics an OpenAI-compatible API endpoint for UI-TARS to communicate with.
2. **UI-TARS Desktop Application**: The main application that provides the UI agent interface.
3. **Launcher Scripts**: PowerShell and batch scripts that automate the startup process.

## Setup Instructions

1. Make sure you have Python 3.8+ and Node.js/npm installed.

2. Navigate to the CypherDyne directory and run the launcher batch file:
   ```
   cd G:\CypherDyne
   .\launch-ui-tars.bat
   ```

3. The launcher will:
   - Start the mock API server on port 8000
   - Launch the UI-TARS desktop application
   - Provide instructions for configuring UI-TARS

4. Once UI-TARS is running, go to the Settings page and import the local development configuration from:
   ```
   G:\CypherDyne\UI-Tars\Desktop\examples\presets\local-development.yaml
   ```

## Troubleshooting

If you encounter issues:

1. **Server not starting**: 
   - Check if port 8000 is already in use
   - Try running the server manually: `python G:\CypherDyne\simple-openai-server\simple.py`

2. **UI-TARS not launching**:
   - Navigate to the UI-TARS directory and run: `cd G:\CypherDyne\UI-Tars\Desktop && npm start`
   - Check for any npm or Node.js errors

3. **Configuration issues**:
   - Verify the configuration file has the correct URL: `http://localhost:8000/v1`
   - Ensure the model name is set to: `mistralai/Mixtral-8x7B-Instruct-v0.1`

## Next Steps

- For real-world usage, replace the mock server with a proper Hugging Face inference server
- Customize the configuration file to match your actual LLM provider settings
- Update the launcher scripts if you change the server implementation

## Files Reference

- `G:\CypherDyne\launch-ui-tars.bat` - Batch launcher (run this)
- `G:\CypherDyne\launch-ui-tars.ps1` - PowerShell script that handles the startup process
- `G:\CypherDyne\simple-openai-server\simple.py` - Mock API server
- `G:\CypherDyne\UI-Tars\Desktop\examples\presets\local-development.yaml` - Configuration file
