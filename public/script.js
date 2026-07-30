/* ============================================
   瀚海未来 - SSHX 控制面板交互逻辑
   ============================================ */

// DOM 元素
const startBtn = document.getElementById('startBtn');
const stopBtn = document.getElementById('stopBtn');
const copyBtn = document.getElementById('copyBtn');
const goBtn = document.getElementById('goBtn');
const sshxUrlInput = document.getElementById('sshxUrl');
const linkContainer = document.getElementById('linkContainer');
const loadingIndicator = document.getElementById('loadingIndicator');
const statusBadge = document.getElementById('statusBadge');
const statusText = document.getElementById('statusText');
const copyMessage = document.getElementById('copyMessage');

// API 基础 URL
const API_BASE = '/api/sshx';

// 初始化
document.addEventListener('DOMContentLoaded', () => {
    checkStatus();
    initParticles();
    
    // 事件监听
    startBtn.addEventListener('click', startSshx);
    stopBtn.addEventListener('click', stopSshx);
    copyBtn.addEventListener('click', copyLink);
    goBtn.addEventListener('click', goToLink);
});

// 检查 SSHX 状态
async function checkStatus() {
    try {
        const response = await fetch(`${API_BASE}/status`);
        const data = await response.json();
        
        if (data.running) {
            updateUI(true, data.url);
        } else {
            updateUI(false, null);
        }
    } catch (error) {
        console.error('检查状态失败:', error);
        updateUI(false, null);
    }
}

// 启动 SSHX
async function startSshx() {
    if (startBtn.disabled) return;
    
    setLoading(true);
    
    try {
        const response = await fetch(`${API_BASE}/start`, {
            method: 'POST'
        });
        
        const data = await response.json();
        
        if (data.success && data.running) {
            updateUI(true, data.url);
            showCopyMessage('SSHX 已成功启动！', 'success');
        } else {
            updateUI(false, null);
            showCopyMessage(data.message || '启动失败，请重试', 'error');
        }
    } catch (error) {
        console.error('启动失败:', error);
        showCopyMessage('网络错误，请重试', 'error');
        updateUI(false, null);
    } finally {
        setLoading(false);
    }
}

// 停止 SSHX
async function stopSshx() {
    if (stopBtn.disabled) return;
    
    setLoading(true);
    
    try {
        const response = await fetch(`${API_BASE}/stop`, {
            method: 'POST'
        });
        
        const data = await response.json();
        
        if (data.success) {
            updateUI(false, null);
            showCopyMessage('SSHX 已关闭', 'info');
        } else {
            showCopyMessage(data.message || '关闭失败', 'error');
        }
    } catch (error) {
        console.error('停止失败:', error);
        showCopyMessage('网络错误，请重试', 'error');
    } finally {
        setLoading(false);
    }
}

// 直达链接
function goToLink() {
    const url = sshxUrlInput.value;
    if (url) {
        window.open(url, '_blank');
    }
}

// 复制链接
async function copyLink() {
    const url = sshxUrlInput.value;
    
    if (!url) return;
    
    try {
        await navigator.clipboard.writeText(url);
        showCopyMessage('链接已复制到剪贴板！', 'success');
        
        // 临时改变按钮文本
        const originalText = copyBtn.textContent;
        copyBtn.textContent = '✓';
        setTimeout(() => {
            copyBtn.textContent = originalText;
        }, 1500);
    } catch (error) {
        console.error('复制失败:', error);
        
        // 备用方案：选中并尝试复制
        sshxUrlInput.select();
        document.execCommand('copy');
        showCopyMessage('请手动复制链接', 'warning');
    }
}

// 更新 UI 状态
function updateUI(running, url) {
    if (running) {
        statusBadge.className = 'status-badge online';
        statusBadge.querySelector('.status-dot').style.background = 'var(--success)';
        statusText.textContent = '运行中';
        
        startBtn.disabled = true;
        stopBtn.disabled = false;
        
        if (url) {
            sshxUrlInput.value = url;
            linkContainer.classList.remove('hidden');
        }
    } else {
        statusBadge.className = 'status-badge offline';
        statusBadge.querySelector('.status-dot').style.background = 'var(--text-muted)';
        statusText.textContent = '未运行';
        
        startBtn.disabled = false;
        stopBtn.disabled = true;
        
        sshxUrlInput.value = '';
        linkContainer.classList.add('hidden');
    }
}

// 设置加载状态
function setLoading(loading) {
    if (loading) {
        startBtn.disabled = true;
        stopBtn.disabled = true;
        loadingIndicator.classList.remove('hidden');
        statusBadge.className = 'status-badge loading';
        statusText.textContent = '连接中...';
    } else {
        // 重新检查状态
        setTimeout(checkStatus, 500);
    }
}

// 显示复制消息
function showCopyMessage(message, type) {
    copyMessage.textContent = message;
    copyMessage.style.color = getVar(`--${type === 'success' ? 'success' : type === 'error' ? 'danger' : 'warning'}`);
    
    clearTimeout(copyMessage._timeout);
    copyMessage._timeout = setTimeout(() => {
        copyMessage.textContent = '';
    }, 3000);
}

// 获取 CSS 变量
function getVar(name) {
    return getComputedStyle(document.documentElement).getPropertyValue(name);
}

// ============================================
// 粒子背景动画
// ============================================
function initParticles() {
    const canvas = document.getElementById('particleCanvas');
    const ctx = canvas.getContext('2d');
    
    let particles = [];
    let animationId;
    
    // 调整画布大小
    function resizeCanvas() {
        canvas.width = window.innerWidth;
        canvas.height = window.innerHeight;
    }
    
    // 创建粒子
    function createParticle() {
        return {
            x: Math.random() * canvas.width,
            y: Math.random() * canvas.height,
            size: Math.random() * 2 + 0.5,
            speedX: (Math.random() - 0.5) * 0.5,
            speedY: (Math.random() - 0.5) * 0.5,
            alpha: Math.random() * 0.5 + 0.2,
            hue: Math.random() > 0.5 ? 190 : 260 // 青色或紫色
        };
    }
    
    // 初始化粒子
    function init() {
        resizeCanvas();
        particles = [];
        const particleCount = Math.floor((canvas.width * canvas.height) / 8000);
        
        for (let i = 0; i < Math.min(particleCount, 150); i++) {
            particles.push(createParticle());
        }
    }
    
    // 绘制粒子
    function drawParticles() {
        ctx.clearRect(0, 0, canvas.width, canvas.height);
        
        particles.forEach((particle, index) => {
            // 更新位置
            particle.x += particle.speedX;
            particle.y += particle.speedY;
            
            // 边界检测
            if (particle.x < 0 || particle.x > canvas.width) {
                particle.speedX *= -1;
            }
            if (particle.y < 0 || particle.y > canvas.height) {
                particle.speedY *= -1;
            }
            
            // 绘制粒子
            ctx.beginPath();
            ctx.arc(
                particle.x,
                particle.y,
                particle.size,
                0,
                Math.PI * 2
            );
            ctx.fillStyle = `hsla(${particle.hue}, 80%, 70%, ${particle.alpha})`;
            ctx.fill();
            
            // 绘制连线（粒子之间距离较近时）
            for (let j = index + 1; j < particles.length; j++) {
                const other = particles[j];
                const dx = particle.x - other.x;
                const dy = particle.y - other.y;
                const distance = Math.sqrt(dx * dx + dy * dy);
                
                if (distance < 100) {
                    ctx.beginPath();
                    ctx.moveTo(particle.x, particle.y);
                    ctx.lineTo(other.x, other.y);
                    ctx.strokeStyle = `rgba(0, 212, 255, ${0.15 * (1 - distance / 100)})`;
                    ctx.lineWidth = 0.5;
                    ctx.stroke();
                }
            }
        });
        
        animationId = requestAnimationFrame(drawParticles);
    }
    
    // 窗口大小变化时重新初始化
    window.addEventListener('resize', init);
    
    // 启动动画
    init();
    drawParticles();
    
    // 清理
    return () => {
        cancelAnimationFrame(animationId);
        window.removeEventListener('resize', init);
    };
}
