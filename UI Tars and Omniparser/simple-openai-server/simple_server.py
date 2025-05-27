import http.server
import socketserver
import json
import random
import time
import sys
from urllib.parse import urlparse, parse_qs

# Configuration
PORT = 8000
VERBOSE = True

def log(message):
    """Print a timestamped log message"""
    timestamp = time.strftime("%Y-%m-%d %H:%M:%S", time.localtime())
    print(f"[{timestamp}] {message}", flush=True)

class OpenAIHandler(http.server.BaseHTTPRequestHandler):
    def log_message(self, format, *args):
        if VERBOSE:
            log(format % args)
    
    def do_GET(self):
        parsed_url = urlparse(self.path)
        path = parsed_url.path
        
        if path == "/v1/models":
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            
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
            self.wfile.write(json.dumps(models_response).encode())
            log(f"Served models list: {json.dumps(models_response)}")
        else:
            self.send_response(404)
            self.end_headers()
            log(f"404 Not Found: {self.path}")
    
    def do_POST(self):
        content_length = int(self.headers.get('Content-Length', 0))
        post_data = self.rfile.read(content_length) if content_length > 0 else b''
        parsed_url = urlparse(self.path)
        path = parsed_url.path
        
        try:
            request_json = json.loads(post_data.decode('utf-8')) if post_data else {}
            log(f"Received POST to {path} with data: {json.dumps(request_json)[:200]}...")
        except json.JSONDecodeError:
            log(f"Failed to parse JSON from request to {path}")
            request_json = {}
        
        if path == "/v1/chat/completions":
            # Create a response that simulates UI-TARS responses
            ui_tars_responses = [
                """```
Thought: I need to analyze what's on the screen and identify the element to interact with.
Action: look_at_screen()
```""",
                """```
Thought: I can see a button that says "Next" in the bottom right corner of the screen.
Action: click(button="Next")
```""",
                """```
Thought: I need to find and click on the search box.
Action: click(search_box='<|box_start|>(250,100)<|box_end|>')
```""",
                """```
Thought: I need to enter text in the input field.
Action: type("Hello, UI-TARS")
```""",
                """```
Thought: I need to analyze the current state of the application.
Action: observe()
```"""
            ]
            
            # Select a random response or handle specific message content
            chosen_response = random.choice(ui_tars_responses)
            
            if "messages" in request_json:
                # Check the last message content to potentially customize the response
                if len(request_json["messages"]) > 0:
                    last_message = request_json["messages"][-1]
                    if "content" in last_message:
                        content = last_message["content"].lower()
                        if "click" in content or "button" in content:
                            chosen_response = ui_tars_responses[1]  # Click button response
                        elif "search" in content or "find" in content:
                            chosen_response = ui_tars_responses[2]  # Search box response
                        elif "type" in content or "enter" in content or "input" in content:
                            chosen_response = ui_tars_responses[3]  # Type text response
                        elif "look" in content or "screen" in content or "observe" in content:
                            chosen_response = ui_tars_responses[4]  # Observe response
            
            # Simulate processing time
            time.sleep(0.5)
            
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
            log(f"Sent chat completion response: {chosen_response[:50]}...")
        else:
            self.send_response(404)
            self.end_headers()
            log(f"404 Not Found: {self.path}")

def main():
    """Main function to start the server"""
    try:
        log(f"Starting mock OpenAI server on port {PORT}")
        server = socketserver.TCPServer(("", PORT), OpenAIHandler)
        log(f"Server running at http://localhost:{PORT}")
        log(f"Available endpoints:")
        log(f"  GET /v1/models - List available models")
        log(f"  POST /v1/chat/completions - Chat completion endpoint")
        log("Press Ctrl+C to stop the server")
        server.serve_forever()
    except KeyboardInterrupt:
        log("\nServer stopped by user")
    except Exception as e:
        log(f"Error starting server: {e}")
        import traceback
        traceback.print_exc()
    finally:
        if 'server' in locals():
            server.server_close()
            log("Server stopped")

if __name__ == "__main__":
    main()
