from http.server import BaseHTTPRequestHandler, HTTPServer
import json
import os
import time

def get_cpu_usage():
    with open('/proc/stat', 'r') as f:
        line = f.readline()
    fields = line.split()
    idle = int(fields[4])
    total = sum(int(x) for x in fields[1:])
    return 100 * (1 - idle / total)

def get_mem_usage():
    with open('/proc/meminfo', 'r') as f:
        lines = f.readlines()
    total = int(lines[0].split()[1])
    free = int(lines[1].split()[1])
    return 100 * (1 - free / total)

class StatusHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == '/status':
            data = {
                'cpu_percent': round(get_cpu_usage(), 2),
                'mem_percent': round(get_mem_usage(), 2),
                'timestamp': time.strftime('%Y-%m-%d %H:%M:%S')
            }
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps(data).encode())
        else:
            self.send_response(404)
            self.end_headers()

if __name__ == '__main__':
    server = HTTPServer(('0.0.0.0', 8080), StatusHandler)
    print('Server running on port 8080...')
    server.serve_forever()
