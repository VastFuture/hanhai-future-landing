#!/usr/bin/env python3
"""
瀚海未来落地页 - Python 后端服务器
包含 SSHX 控制 API
"""

import subprocess
import json
import os
import time
from flask import Flask, send_from_directory, request, jsonify
from functools import wraps

app = Flask(__name__)

# 路径配置
SSHX_BIN = '/root/sshx'
LOG_FILE = '/root/log.log'
PUBLIC_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'public')

def check_sshx_running():
    """检查 sshx 是否正在运行"""
    try:
        result = subprocess.run(['pgrep', '-x', 'sshx'], 
                               capture_output=True, text=True)
        return result.returncode == 0 and result.stdout.strip()
    except:
        return False

def get_sshx_url():
    """从日志中提取 sshx 访问链接"""
    try:
        if not os.path.exists(LOG_FILE):
            return None
        with open(LOG_FILE, 'r') as f:
            content = f.read()
        # 匹配 https://sshx.io/s/xxxx#xxxx 格式的链接
        import re
        matches = re.findall(r'https://sshx\.io/s/[A-Za-z0-9#]+', content)
        return matches[-1] if matches else None
    except Exception as e:
        print(f"Error reading log: {e}")
        return None

def start_sshx():
    """启动 sshx 服务"""
    # 清理旧日志
    try:
        open(LOG_FILE, 'w').close()
    except:
        pass
    
    # 停止旧的 sshx 实例
    subprocess.run(['pkill', '-f', 'sshx'], capture_output=True)
    time.sleep(0.5)
    
    # 启动新的 sshx 实例
    cmd = f'{SSHX_BIN} > {LOG_FILE} 2>&1 &'
    try:
        subprocess.Popen(cmd, shell=True)
        time.sleep(2)  # 等待生成链接
    except Exception as e:
        print(f"Failed to start sshx: {e}")
        return False
    return True

def stop_sshx():
    """停止 sshx 服务"""
    subprocess.run(['pkill', 'sshx'], capture_output=True)

@app.route('/api/sshx/status')
def status():
    """获取 sshx 状态"""
    running = check_sshx_running()
    url = get_sshx_url() if running else None
    return jsonify({'running': running, 'url': url})

@app.route('/api/sshx/start', methods=['POST'])
def start():
    """启动 sshx"""
    if check_sshx_running():
        url = get_sshx_url()
        return jsonify({
            'success': True,
            'message': 'sshx 已在运行',
            'running': True,
            'url': url
        })
    
    if start_sshx():
        time.sleep(3)  # 等待链接生成
        running = check_sshx_running()
        url = get_sshx_url() if running else None
        return jsonify({
            'success': running,
            'message': 'sshx 已启动' if running else 'sshx 启动可能失败',
            'running': running,
            'url': url
        })
    return jsonify({'success': False, 'message': '启动失败'}), 500

@app.route('/api/sshx/stop', methods=['POST'])
def stop():
    """停止 sshx"""
    if not check_sshx_running():
        return jsonify({
            'success': True,
            'message': 'sshx 未运行',
            'running': False
        })
    
    stop_sshx()
    return jsonify({
        'success': True,
        'message': 'sshx 已停止',
        'running': False
    })

@app.route('/')
def index():
    """首页"""
    return send_from_directory(PUBLIC_DIR, 'index.html')

@app.route('/<path:filename>')
def static_files(filename):
    """静态文件服务"""
    return send_from_directory(PUBLIC_DIR, filename)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=3000, debug=False)
