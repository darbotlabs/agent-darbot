# UI-TARS Local Development Setup

This document outlines how to set up and run UI-TARS with a local mock LLM server for development and testing purposes.

## Overview

UI-TARS is designed to work with Hugging Face inference servers, but for local development, we've created a mock OpenAI-compatible API server that simulates responses from a Mixtral-8x7B-Instruct model.

## Components

1. **UI-TARS Desktop Application**: The Electron-based UI application
2. **Mock LLM Server**: A simple Python server that provides OpenAI-compatible API endpoints
3. **Launcher Scripts**: PowerShell and batch scripts to easily start both components

## Prerequisites

- Windows 10/11
- Python 3.8+ (for the mock server)
- Node.js and npm (for UI-TARS)

## Quick Start

1. Run the batch file `launch-ui-tars.bat` in the CypherDyne directory
2. This will:
   - Start the mock LLM server on port 8000
   - Launch the UI-TARS desktop application
   - Configure the connection between them

## Configuration

UI-TARS is configured to use the mock server through a preset file located at:
```
G:\CypherDyne\UI-Tars\Desktop\examples\presets\local-development.yaml
```

This configuration uses the following settings:
- **Provider**: Hugging Face for UI-TARS-1.5
- **Base URL**: http://localhost:8000/v1
- **Model**: mistralai/Mixtral-8x7B-Instruct-v0.1
- **API Key**: dummy-key (not actually used by the mock server)

## Mock Server Details

The mock server (`G:\CypherDyne\simple-openai-server\app.py`) supports:

- `GET /v1/models`: Returns available models (Mixtral-8x7B-Instruct-v0.1)
- `POST /v1/chat/completions`: Returns predefined UI-TARS action responses

## Using with a Real LLM Server

When you're ready to use UI-TARS with a real language model:

1. Set up a Hugging Face inference server or compatible API
2. Update the configuration file with the correct URL, API key, and model name
3. Start UI-TARS and load the updated configuration

## Troubleshooting

If you encounter issues:

1. Ensure the mock server is running (check http://localhost:8000/v1/models in a browser)
2. Check the terminal output for any errors
3. Restart both the server and UI-TARS application

For more detailed logs, check the log files in the `G:\CypherDyne\logs` directory.
