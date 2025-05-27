from fastapi import FastAPI, Request
import uvicorn
import json
from typing import Dict, List, Any, Optional

app = FastAPI()

@app.get("/v1/models")
async def list_models():
    """Return a list of available models"""
    return {
        "object": "list",
        "data": [
            {
                "id": "mistralai/Mixtral-8x7B-Instruct-v0.1",
                "object": "model",
                "created": 1677610602,
                "owned_by": "organization-owner"
            }
        ]
    }

@app.post("/v1/chat/completions")
async def chat_completion(request: Request):
    """Handle chat completion requests"""
    try:
        data = await request.json()
        
        # Simple mock response for UI-TARS
        response = {
            "id": "chatcmpl-123456789",
            "object": "chat.completion",
            "created": 1677610602,
            "model": data.get("model", "mistralai/Mixtral-8x7B-Instruct-v0.1"),
            "choices": [
                {
                    "index": 0,
                    "message": {
                        "role": "assistant",
                        "content": """```
Thought: I need to look at the UI and identify what action to take to complete the task.
Action: click(start_box='<|box_start|>(500,300)<|box_end|>')
```"""
                    },
                    "finish_reason": "stop"
                }
            ],
            "usage": {
                "prompt_tokens": 100,
                "completion_tokens": 100,
                "total_tokens": 200
            }
        }
        return response
    except Exception as e:
        return {"error": str(e)}

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)
