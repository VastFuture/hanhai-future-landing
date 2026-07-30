const express = require('express');
const { execSync, spawn } = require('child_process');
const fs = require('fs');
const path = require('path');

const app = express();
const PORT = 3211;

const SSHX_BIN = '/root/sshx';
const LOG_FILE = '/root/log.log';
const PUBLIC_DIR = path.join(__dirname, 'public');

app.use(express.json());
app.use(express.text());

app.use((req, res, next) => {
    res.header('Access-Control-Allow-Origin', '*');
    res.header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    res.header('Access-Control-Allow-Headers', 'Content-Type');
    if (req.method === 'OPTIONS') return res.sendStatus(200);
    next();
});

function isSshxRunning() {
    try {
        const result = execSync('pgrep -x sshx', { encoding: 'utf8' });
        return result.trim().length > 0;
    } catch (e) {
        return false;
    }
}

function getSshxPid() {
    try {
        const result = execSync('pgrep -x sshx', { encoding: 'utf8' });
        return parseInt(result.trim(), 10);
    } catch (e) {
        return null;
    }
}

function getSshxUrl() {
    try {
        if (!fs.existsSync(LOG_FILE)) return null;
        const logContent = fs.readFileSync(LOG_FILE, 'utf8');
        const urlMatch = logContent.match(/https:\/\/sshx\.io\/s\/[A-Za-z0-9#]+/g);
        return urlMatch ? urlMatch[urlMatch.length - 1] : null;
    } catch (e) {
        return null;
    }
}

function killSshx() {
    const pid = getSshxPid();
    if (!pid) return false;
    try {
        process.kill(pid, 'SIGTERM');
        return true;
    } catch (e) {
        return false;
    }
}

// API 路由
app.get('/api/sshx/status', (req, res) => {
    const running = isSshxRunning();
    const url = running ? getSshxUrl() : null;
    res.json({ running, url });
});

app.post('/api/sshx/start', (req, res) => {
    if (isSshxRunning()) {
        const url = getSshxUrl();
        return res.json({ success: true, message: 'sshx 已在运行', running: true, url });
    }

    // 清理日志
    try { fs.writeFileSync(LOG_FILE, ''); } catch (e) {}

    // 用 spawn 启动 sshx（不经过 shell，避免 pkill 被拦截）
    const out = fs.openSync(LOG_FILE, 'w');
    const child = spawn(SSHX_BIN, [], {
        stdio: ['ignore', out, out],
        detached: true
    });
    child.unref();

    // 等待 sshx 启动并生成链接
    let attempts = 0;
    const maxAttempts = 15;
    const check = () => {
        attempts++;
        const running = isSshxRunning();
        const url = getSshxUrl();
        if (running && url) {
            res.json({ success: true, message: 'sshx 已启动', running: true, url });
        } else if (attempts >= maxAttempts) {
            res.json({ success: running, message: running ? 'sshx 已启动但未获取到链接' : 'sshx 启动失败', running, url });
        } else {
            setTimeout(check, 500);
        }
    };
    setTimeout(check, 1000);
});

app.post('/api/sshx/stop', (req, res) => {
    if (!isSshxRunning()) {
        return res.json({ success: true, message: 'sshx 未运行', running: false });
    }

    const killed = killSshx();
    // 等待进程退出
    setTimeout(() => {
        const running = isSshxRunning();
        res.json({
            success: !running,
            message: running ? '停止失败' : 'sshx 已停止',
            running
        });
    }, 500);
});

// 首页
app.get('/', (req, res) => {
    const indexPath = path.join(PUBLIC_DIR, 'index.html');
    if (!fs.existsSync(indexPath)) {
        return res.status(404).send('index.html not found at ' + indexPath);
    }
    res.sendFile(indexPath);
});

// 静态文件
app.get('/:file', (req, res) => {
    const filePath = path.join(PUBLIC_DIR, req.params.file);
    if (fs.existsSync(filePath)) {
        res.sendFile(filePath);
    } else {
        res.status(404).send('Not found');
    }
});

app.listen(PORT, () => {
    console.log('瀚海未来服务已启动: http://localhost:' + PORT);
});