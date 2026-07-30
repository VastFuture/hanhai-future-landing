# 瀚海未来 · Hanhai Future

🌊 **瀚海未来** 是一个以深海科幻为主题的落地页项目，内置 **SSHX Web 终端控制面板**，支持一键开启/关闭远程终端访问，并提供复制链接与直达访问功能。

---

## 项目概览

```
hanhai-future-landing/
├── server.js              # Node.js 后端 (Express)
├── server.py              # Python 后端备选 (Flask)
├── hanhai.py              # Python 后端 (标准库 http.server)
├── hanhai_server.py       # Python 后端 (标准库 socketserver)
├── package.json           # Node.js 依赖
├── public/
│   ├── index.html         # 瀚海未来落地页
│   ├── style.css          # 深海科技风格样式
│   └── script.js          # SSHX 面板交互 + 粒子动画
└── .gitignore
```

## 技术栈

| 层级 | 技术 |
|------|------|
| **前端** | 原生 HTML + CSS + JavaScript |
| **后端 (推荐)** | Node.js + Express |
| **后端 (备选)** | Python Flask / http.server |
| **终端** | SSHX v0.4.1 |
| **部署** | Cloudflare Tunnel |

## 功能特性

### 落地页
- **深海星空粒子背景** — 动态粒子系统，青色与紫色交织
- **响应式设计** — 适配桌面端、平板、手机
- **科幻风格 UI** — 渐变文字、浮动光晕、波浪动画

### SSHX 控制面板
- **一键开启** — 通过 `spawn` 启动 SSHX 后台进程
- **一键关闭** — 通过 `process.kill` 安全停止
- **状态实时检测** — 页面加载和操作后自动刷新运行状态
- **链接复制** — 一键复制 SSHX 访问链接到剪贴板
- **直达访问** — 点击在新窗口直接打开 SSHX 终端

## 快速开始

### 前置要求

- Node.js 16+
- SSHX 已安装（路径：`/root/sshx`）

### 安装与启动

```bash
# 1. 克隆仓库
git clone https://github.com/VastFuture/hanhai-future-landing.git
cd hanhai-future-landing

# 2. 安装依赖
npm install

# 3. 启动服务
node server.js
```

默认端口为 `3211`，如需修改请编辑 `server.js` 中的 `PORT` 常量。

### 使用 Python 启动

```bash
# Flask 版本
pip install flask
python3 server.py

# 标准库版本（无需额外依赖）
python3 hanhai_server.py
```

### 访问页面

打开浏览器访问 `http://localhost:3211`。

## 环境变量

| 变量 | 说明 | 默认值 |
|------|------|--------|
| `CLOUDFLARED_TOKEN` | Cloudflare Tunnel 认证 Token | `~/.env` 中配置 |

## API 接口

| 方法 | 路径 | 说明 |
|------|------|------|
| `GET` | `/api/sshx/status` | 获取 SSHX 运行状态和链接 |
| `POST` | `/api/sshx/start` | 启动 SSHX 服务 |
| `POST` | `/api/sshx/stop` | 停止 SSHX 服务 |

### 状态响应示例

```json
{
  "running": true,
  "url": "https://sshx.io/s/xxxxxxxx#xxxxxxxx"
}
```

## 常见问题

### 端口被占用

```bash
# 查找占用端口的进程
lsof -i :3211

# 使用 Node.js 安全终止进程（绕过 shell 拦截）
node -e "process.kill(PID, 'SIGTERM')"
```

### SSHX 启动失败

检查 `/root/log.log` 查看详细错误日志。

## 设计理念

- **色系**：深海蓝 (#0a1628) → 青色 (#00d4ff) → 紫色 (#a855f7)
- **氛围**：深邃、科幻、宁静、探索感
- **交互**：沉浸式粒子背景 + 实时反馈控制面板

## 许可证

MIT