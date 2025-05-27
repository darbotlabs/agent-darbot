import http.server
import socketserver
import json
import time
import sys

PORT = 8000

class SimpleHandler(http.server.BaseHTTPRequestHandler):
    protocol_version = 'HTTP/1.1'  # Explicitly set protocol version
    
    def log_message(self, format, *args):
        # Override to better format log messages
        sys.stdout.write(f"{self.address_string()} - {format % args}\n")
        sys.stdout.flush()
    
    def log_request(self, code='-', size='-'):
        # Override to provide better request logging
        sys.stdout.write(f"{self.command} request to {self.path} - HTTP {self.request_version} - Response: {code}\n")
        sys.stdout.flush()
    
    def handle_one_request(self):
        # Override to handle malformed requests more gracefully
        try:
            return super().handle_one_request()
        except Exception as e:
            sys.stdout.write(f"Error handling request: {str(e)}\n")
            sys.stdout.flush()
            # Try to return a 400 Bad Request response
            try:
                self.send_response(400)
                self.send_header('Content-Type', 'text/html')
                self.end_headers()
                self.wfile.write(b"<html><body><h1>400 Bad Request</h1><p>Malformed request received.</p></body></html>")
            except:
                # If we can't even send an error response, just pass
                pass
    
    def do_GET(self):
        # Handle root path
        if self.path == "/" or self.path == "":
            html_content = """
<!DOCTYPE html>
<html>
<head>
    <title>Simple OpenAI API Server</title>
    <style>
        body { font-family: Arial, sans-serif; max-width: 800px; margin: 0 auto; padding: 20px; }
        h1 { color: #4a4a4a; }
        .endpoint { background: #f4f4f4; padding: 10px; border-radius: 5px; margin-bottom: 10px; }
        code { background: #e6e6e6; padding: 2px 4px; border-radius: 3px; }
    </style>
</head>
<body>
    <h1>Simple OpenAI API Server</h1>
    <p>This server provides a simple mock of the OpenAI API for local development.</p>
    
    <h2>Available Endpoints:</h2>
    <div class="endpoint">
        <h3>GET /v1/models</h3>
        <p>Returns available models</p>
        <p>Try it: <a href="/v1/models">/v1/models</a></p>
    </div>
    
    <div class="endpoint">
        <h3>POST /v1/chat/completions</h3>
        <p>Returns a simple chat completion</p>
    </div>
    
    <p>This server is designed to work with UI-TARS.</p>
</body>
</html>
"""
            self.send_response(200)
            self.send_header('Content-Type', 'text/html')
            self.end_headers()
            self.wfile.write(html_content.encode())
            return
        
        elif self.path == "/v1/models":
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
            sys.stdout.write("Sent models response\n")
            sys.stdout.flush()
        else:
            self.send_response(404)
            self.send_header('Content-Type', 'text/html')
            self.end_headers()
            
            # Send a nicer 404 page
            html_404 = f"""
<!DOCTYPE html>
<html>
<head>
    <title>404 - Not Found</title>
    <style>
        body {{ font-family: Arial, sans-serif; max-width: 800px; margin: 0 auto; padding: 20px; text-align: center; }}
        h1 {{ color: #e74c3c; }}
    </style>
</head>
<body>
    <h1>404 - Not Found</h1>
    <p>The requested path <code>{self.path}</code> was not found on this server.</p>
    <p><a href="/">Return to homepage</a></p>
</body>
</html>
"""
            self.wfile.write(html_404.encode())
            sys.stdout.write(f"404: {self.path}\n")
            sys.stdout.flush()

    def do_POST(self):
        content_length = int(self.headers.get('Content-Length', 0))
        request_body = self.rfile.read(content_length).decode('utf-8') if content_length > 0 else ""
        
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
            sys.stdout.write("Sent chat completion response\n")
            sys.stdout.flush()
        else:
            self.send_response(404)
            self.send_header('Content-Type', 'text/html')
            self.end_headers()
            
            # Send a nicer 404 page
            html_404 = f"""
<!DOCTYPE html>
<html>
<head>
    <title>404 - Not Found</title>
    <style>
        body {{ font-family: Arial, sans-serif; max-width: 800px; margin: 0 auto; padding: 20px; text-align: center; }}
        h1 {{ color: #e74c3c; }}
    </style>
</head>
<body>
    <h1>404 - Not Found</h1>
    <p>The requested path <code>{self.path}</code> was not found on this server.</p>
    <p><a href="/">Return to homepage</a></p>
</body>
</html>
"""
            self.wfile.write(html_404.encode())
            sys.stdout.write(f"404: {self.path}\n")
            sys.stdout.flush()

if __name__ == "__main__":
    print(f"Starting server on port {PORT}")
    sys.stdout.write(f"Starting server on port {PORT}\n")
    sys.stdout.flush()
    
    # Make the server more resilient to protocol errors
    socketserver.TCPServer.allow_reuse_address = True
    
    try:
        print("Creating HTTP server...")
        httpd = socketserver.TCPServer(("", PORT), SimpleHandler)
        print(f"Server running at http://localhost:{PORT}")
        sys.stdout.write(f"Server running at http://localhost:{PORT}\n")
        sys.stdout.write(f"Available endpoints:\n")
        sys.stdout.write(f"  - http://localhost:{PORT}/             (Home page)\n")
        sys.stdout.write(f"  - http://localhost:{PORT}/v1/models    (OpenAI compatible models API)\n")
        sys.stdout.write(f"  - http://localhost:{PORT}/v1/chat/completions (POST only - Chat completions)\n")
        sys.stdout.flush()
        print("Starting server, press Ctrl+C to stop...")
        httpd.serve_forever()
    except Exception as e:
        print(f"Error: {str(e)}")
        sys.stdout.write(f"Error: {str(e)}\n")
        sys.stdout.flush()
        sys.exit(1)
    except KeyboardInterrupt:
        print("Server stopped by user")
        sys.stdout.write("Server stopped by user\n")
        sys.stdout.flush()
    finally:
        if 'httpd' in locals():
            httpd.server_close()
            print("Server stopped")
            sys.stdout.write("Server stopped\n")
            sys.stdout.flush()
