import http.server
import socketserver
import json
import time

PORT = 8000

class SimpleHandler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        print(f"GET request to {self.path}")
        
        if self.path == "/v1/models":
            response = {
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
            self.wfile.write(json.dumps(response).encode())
            print("Sent models response")
        else:
            self.send_response(404)
            self.end_headers()
            print(f"404: {self.path}")
    
    def do_POST(self):
        print(f"POST request to {self.path}")
        
        if self.path == "/v1/chat/completions":
            # Simple response for UI-TARS
            response = {
                "id": "chatcmpl-simple",
                "object": "chat.completion",
                "created": int(time.time()),
                "model": "mistralai/Mixtral-8x7B-Instruct-v0.1",
                "choices": [
                    {
                        "index": 0,
                        "message": {
                            "role": "assistant",
                            "content": """```
Thought: I need to look at the UI and identify what action to take.
Action: look_at_screen()
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
            
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps(response).encode())
            print("Sent chat completion response")
        else:
            self.send_response(404)
            self.end_headers()
            print(f"404: {self.path}")

print(f"Starting server on port {PORT}")
httpd = socketserver.TCPServer(("", PORT), SimpleHandler)

try:
    print(f"Server running at http://localhost:{PORT}")
    httpd.serve_forever()
except KeyboardInterrupt:
    print("Server stopped by user")
finally:
    httpd.server_close()
    print("Server stopped")
