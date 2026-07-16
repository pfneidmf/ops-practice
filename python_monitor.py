from http.server import BaseHTTPRequestHandler, HTTPServer
import json
import os
import time

DISK_THRESHOLD = 80

def get_cpu_usage():
    with open('/proc/stat', 'r') as f:
        line = f.readline()
    fields = line.split()
    idle = int(fields[4])
    total = sum(int(x) for x in fields[1:])
    return round(100 * (1 - idle / total), 2)

def get_mem_usage():
    with open('/proc/meminfo', 'r') as f:
        lines = f.readlines()
    total = int(lines[0].split()[1])
    free = int(lines[1].split()[1])
    return round(100 * (1 - free / total), 2)

def get_disk_usage():
    stat = os.statvfs('/')
    return round(100 * (1 - stat.f_bavail / stat.f_blocks), 2)

class StatusHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == '/status':
            cpu = get_cpu_usage()
            mem = get_mem_usage()
            disk = get_disk_usage()
            data = {
                'cpu_percent': cpu,
                'mem_percent': mem,
                'disk_percent': disk,
                'timestamp': time.strftime('%Y-%m-%d %H:%M:%S')
            }
            if disk > DISK_THRESHOLD:
                data['alert'] = f'DISK usage {disk}% exceeds threshold {DISK_THRESHOLD}%!'
                data['alert_level'] = 'warning'
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
