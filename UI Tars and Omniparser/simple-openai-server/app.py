import http.server
import socketserver
import json
import random
import time
import re

PORT = 8000

# UI-TARS specific response templates
UI_TARS_RESPONSES = {
    "click": """```
Thought: I can see a button that needs to be clicked.
Action: click(button="{element}")
```""",
    
    "type": """```
Thought: I need to enter text in this input field.
Action: type("{text}")
```""",
    
    "observe": """```
Thought: I need to analyze what's on the screen.
Action: observe()
```""",
    
    "look": """```
Thought: I need to look for specific elements on the screen.
Action: look_at_screen()
```""",
    
    "default": """```
Thought: I need to analyze what's on the screen and identify the element to interact with.
Action: look_at_screen()
```"""
}

class OpenAIHandler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        print(f"GET request received at {self.path}")
        
        if self.path == "/v1/models":
            models_response = {
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
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps(models_response).encode())
            print(f"Sent models list response")
        else:
            self.send_response(404)
            self.end_headers()
    
    def do_POST(self):
        print(f"POST request received at {self.path}")
        
        if self.path == "/v1/chat/completions":
            content_length = int(self.headers.get('Content-Length', 0))
            post_data = self.rfile.read(content_length) if content_length > 0 else b''
            
            chosen_response = UI_TARS_RESPONSES["default"]
            
            try:
                request_json = json.loads(post_data.decode('utf-8'))
                # Try to extract the user's message to customize the response
                if "messages" in request_json and len(request_json["messages"]) > 0:
                    last_message = request_json["messages"][-1]
                    if "content" in last_message:
                        content = last_message["content"].lower()
                        
                        # Pattern matching for common UI-TARS commands
                        if re.search(r'click|button|press|select', content):
                            # Try to extract an element name
                            element_match = re.search(r'(click|press|select)\s+(?:on|the)?\s*(?:button|link)?\s*["\']?([a-zA-Z0-9 ]+)["\']?', content)
                            element = element_match.group(2) if element_match else "Button"
                            chosen_response = UI_TARS_RESPONSES["click"].format(element=element)
                        
                        elif re.search(r'type|enter|input|write', content):
                            # Try to extract text
                            text_match = re.search(r'(type|enter|input|write)\s+["\']?([^"\']+)["\']?', content)
                            text = text_match.group(2) if text_match else "Sample text"
                            chosen_response = UI_TARS_RESPONSES["type"].format(text=text)
                        
                        elif re.search(r'look|scan|find|search', content):
                            chosen_response = UI_TARS_RESPONSES["look"]
                        
                        elif re.search(r'observe|analyze|check', content):
                            chosen_response = UI_TARS_RESPONSES["observe"]
                
                print(f"User input: {content if 'content' in locals() else 'No content'}")
                print(f"Selected response: {chosen_response[:50]}...")
            except Exception as e:
                print(f"Error processing request: {e}")
            
            # Simulate processing time
            time.sleep(0.2)
            
            # Create response object
            response = {
                "id": f"chatcmpl-{random.randint(10000000, 99999999)}",
                "object": "chat.completion",
                "created": int(time.time()),
                "model": "mistralai/Mixtral-8x7B-Instruct-v0.1",
                "choices": [
                    {
                        "index": 0,
                        "message": {
                            "role": "assistant",
                            "content": chosen_response
                        },
                        "finish_reason": "stop"
                    }
                ],
                "usage": {
                    "prompt_tokens": random.randint(50, 150),
                    "completion_tokens": random.randint(50, 150),
                    "total_tokens": random.randint(100, 300)
                }
            }
            
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps(response).encode())
            print(f"Sent chat completion response")
        else:
            self.send_response(404)
            self.end_headers()

print(f"Starting mock OpenAI server on port {PORT}")
httpd = socketserver.TCPServer(("", PORT), OpenAIHandler)
print(f"Server running at http://localhost:{PORT}")
print(f"GET /v1/models - List available models")
print(f"POST /v1/chat/completions - Chat completion endpoint")
print("Press Ctrl+C to stop the server")

try:
    httpd.serve_forever()
except KeyboardInterrupt:
    print("\nServer stopped by user")
finally:
    httpd.server_close()
    print("Server stopped")
