#!/usr/bin/env python3
"""
瀚海未来落地页 - Python 服务器
使用标准库，无需额外依赖
"""

import subprocess
import json
import os
import time
import re
import http.server
import socketserver

# 配置
SSHX_BIN = '/root/sshx'
LOG_FILE = '/root/log.log'
PORT = 3210

def check_sshx_running():
    """检查 sshx 是否正在运行"""
    try:
        result = subprocess.run(['pgrep', '-x', 'sshx'], capture_output=True, timeout=5)
        return result.returncode == 0
    except Exception:
        return False

def get_sshx_url():
    """从日志中提取 sshx 访问链接"""
    try:
        if not os.path.exists(LOG_FILE):
            return None
        with open(LOG_FILE, 'r') as f:
            content = f.read()
        matches = re.findall(r'https://sshx\.io/s/[A-Za-z0-9#]+', content)
        return matches[-1] if matches else None
    except Exception:
        return None

def start_sshx():
    """启动 sshx 服务"""
    # 停止旧的
    subprocess.run(['pkill', '-f', 'sshx'], capture_output=True, timeout=2)
    time.sleep(0.5)
    
    # 清理日志
    try:
        open(LOG_FILE, 'w').close()
    except:
        pass
    
    # 启动新的 sshx
    try:
        proc = subprocess.Popen([SSHX_BIN], stdout=open(LOG_FILE, 'w'), stderr=subprocess.STDOUT)
        time.sleep(3)
        if check_sshx_running():
            return proc
    except Exception as e:
        print(f"Error starting sshx: {e}")
    return None

def stop_sshx():
    """停止 sshx 服务"""
    subprocess.run(['pkill', 'sshx'], capture_output=True, timeout=2)

class HanhaiRequestHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        # 重定义来处理目录索引
        self.directory = os.path.join(os.getcwd(), 'public')
        super().__init__(*args, directory=self.directory, **kwargs)
    
    def do_GET(self):
        # API 端点
        if self.path.startswith('/api/'):
            self.handle_api()
            return
        
        # 首页和静态文件
        if self.path in ('/', '/index.html'):
            self.send_file('index.html')
            return
        
        # 其他静态文件
        self.send_file(self.path.lstrip('/'))
    
    def do_POST(self):
        if self.path == '/api/sshx/start':
            self.handle_start()
        elif self.path == '/api/sshx/stop':
            self.handle_stop()
        else:
            self.send_error(405)
    
    def handle_api(self):
        if self.path == '/api/sshx/status':
            running = check_sshx_running()
            url = get_sshx_url() if running else None
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()
            self.wfile.write(json.dumps({'running': running, 'url': url}).encode())
        else:
            self.send_error(404)
    
    def handle_start(self):
        if check_sshx_running():
            url = get_sshx_url()
            response = {'success': True, 'message': 'sshx 已在运行', 'running': True, 'url': url}
        else:
            proc = start_sshx()
            time.sleep(2)
            running = check_sshx_running()
            url = get_sshx_url() if running else None
            response = {'success': running, 'message': 'sshx 已启动' if running else '启动失败', 'running': running, 'url': url}
        self.send_json(response)
    
    def handle_stop(self):
        stop_sshx()
        self.send_json({'success': True, 'message': 'sshx 已停止', 'running': False})
    
    def send_file(self, filename):
        if filename == '':
            filename = 'index.html'
        
        # 检查文件是否存在
        filepath = os.path.join('public', filename)
        if not os.path.exists(filepath):
            # 尝试根目录
            filepath = filename
        
        if not os.path.exists(filepath) or not os.path.isfile(filepath):
            self.send_error(404, 'File not found')
            return
        
        # 设置正确的 Content-Type
        if filename.endswith('.css'):
            content_type = 'text/css'
        elif filename.endswith('.js'):
            content_type = 'application/javascript'
        elif filename.endswith('.html'):
            content_type = 'text/html'
        else:
            content_type = 'application/octet-stream'
        
        self.send_response(200)
        self.send_header('Content-Type', content_type)
        self.send_header('Access-Control-Allow-Origin', '*')
        self.end_headers()
        
        try:
            with open(filepath, 'rb') as f:
                self.wfile.write(f.read())
        except Exception as e:
            self.send_error(500, str(e))
    
    def send_json(self, data):
        self.send_response(200)
        self.send_header('Content-Type', 'application/json')
        self.send_header('Access-Control-Allow-Origin', '*')
        self.end_headers()
        self.wfile.write(json.dumps(data).encode())
    
    def log_message(self, format, *args):
        # 静默日志
        pass

def main():
    print("🌊 瀚海未来服务启动中...")
    print(f"📍 地址: http://0.0.0.0:{PORT}")
    print(f"🔗 SSHX 状态: /api/sshx/status")
    print(f"🚀 启动 SSHX: POST /api/sshx/start")
    print(f"🛑 停止 SSHX: POST /api/sshx/stop")
    print("=" * 50)
    
    # 创建一个 TCPServer 实例
    with socketserver.TCPServer(('0.0.0.0', PORT), HanhaiRequestHandler) as httpd:
        # 设置允许快速重用地址
        httpd.allow_address_reuse = True
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("\n👋 服务已停止")

if __name__ == '__main__':
    main()
