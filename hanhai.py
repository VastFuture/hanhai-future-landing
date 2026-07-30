#!/usr/bin/env python3
import http.server, json, subprocess, os, time, re

SSHX_BIN = '/root/sshx'
LOG_FILE = '/root/log.log'

class HanhaiHandler(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        if self.path.startswith('/api/'):
            self.handle_api()
            return
        super().do_GET()
    
    def do_POST(self):
        if self.path == '/api/sshx/start':
            self.handle_start()
        elif self.path == '/api/sshx/stop':
            self.handle_stop()
        else:
            self.send_response(405)
            self.end_headers()
    
    def handle_api(self):
        if self.path == '/api/sshx/status':
            running = subprocess.call(['pgrep', '-x', 'sshx']) == 0
            url = None
            if running:
                try:
                    if os.path.exists(LOG_FILE):
                        with open(LOG_FILE) as f:
                            content = f.read()
                        m = re.search(r'https://sshx\\.io/s/[A-Za-z0-9#]+', content)
                        url = m.group(0) if m else None
                except: pass
            self.send_json({'running': running, 'url': url})
        else:
            self.send_response(404)
            self.end_headers()
    
    def handle_start(self):
        if subprocess.call(['pgrep', '-x', 'sshx']) == 0:
            url = get_url()
        else:
            subprocess.run(['pkill', '-f', 'sshx'], timeout=2)
            time.sleep(0.5)
            try: open(LOG_FILE, 'w').close()
            except: pass
            proc = subprocess.Popen([SSHX_BIN], stdout=open(LOG_FILE,'w'), stderr=subprocess.STDOUT)
            time.sleep(3)
            running = subprocess.call(['pgrep', '-x', 'sshx']) == 0
            url = get_url() if running else None
        self.send_json({'success': True, 'message': '已启动', 'running': True, 'url': url})
    
    def handle_stop(self):
        subprocess.run(['pkill', 'sshx'], timeout=2)
        self.send_json({'success': True, 'message': '已停止', 'running': False})
    
    def send_json(self, data):
        self.send_response(200)
        self.send_header('Content-Type', 'application/json')
        self.send_header('Access-Control-Allow-Origin', '*')
        self.end_headers()
        self.wfile.write(json.dumps(data).encode())

def get_url():
    try:
        if not os.path.exists(LOG_FILE): return None
        with open(LOG_FILE) as f:
            content = f.read()
        m = re.search(r'https://sshx\\.io/s/[A-Za-z0-9#]+', content)
        return m.group(0) if m else None
    except: return None

print('Starting server on 3000...')
httpd = http.server.HTTPServer(('0.0.0.0', 3000), HanhaiHandler)
httpd.serve_forever()
