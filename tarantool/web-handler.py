import http.server

class MyHandler(http.server.BaseHTTPRequestHandler):
    def do_POST(self:
        self.send_response(200)
        self.end_headers()
        self.wfile.write(b"call my service")
        content_len = int(self.headers.get('Content-Length'))
        post_body = self.rfile.read(content_len)
        print(post_body)



if __name__ == "__main__":
    start_http_server(8000)
    server = http.server.HTTPServer(('0.0.0.0', 8001), MyHandler)
    server.serve_forever()