#!/usr/bin/env bash
set -e

# ╔══════════════════════════════════════════════╗
# ║    瀚海未来 · 一键安装脚本                   ║
# ║    Hanhai Future - One-click Installer       ║
# ╚══════════════════════════════════════════════╝

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

log_info()  { echo -e "${CYAN}[INFO]${NC}  $1"; }
log_ok()    { echo -e "${GREEN}[OK]${NC}    $1"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC}  $1"; }
log_err()   { echo -e "${RED}[ERR]${NC}   $1"; }

REPO_URL="https://github.com/VastFuture/hanhai-future-landing.git"
INSTALL_DIR="$HOME/hanhai-future-landing"
NODE_VERSION="20"

# ─── 检测系统 ─────────────────────────────────
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
        OS_VERSION=$VERSION_ID
    else
        OS=$(uname -s)
    fi
    echo "$OS"
}

# ─── 安装 Node.js ──────────────────────────────
install_node() {
    log_info "正在安装 Node.js ${NODE_VERSION}..."
    case $(detect_os) in
        ubuntu|debian)
            curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | bash - 2>/dev/null
            apt-get install -y nodejs
            ;;
        centos|rhel|fedora|almalinux|rocky)
            curl -fsSL https://rpm.nodesource.com/setup_${NODE_VERSION}.x | bash - 2>/dev/null
            yum install -y nodejs
            ;;
        alpine)
            apk add nodejs npm
            ;;
        darwin|macos)
            if command -v brew &>/dev/null; then
                brew install node@${NODE_VERSION}
            else
                log_err "请先安装 Homebrew: https://brew.sh"
                exit 1
            fi
            ;;
        *)
            log_warn "未知系统: $(detect_os)，尝试使用 nvm 安装..."
            curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.0/install.sh | bash
            [ -f "$HOME/.nvm/nvm.sh" ] && . "$HOME/.nvm/nvm.sh"
            nvm install ${NODE_VERSION}
            nvm use ${NODE_VERSION}
            ;;
    esac
    log_ok "Node.js $(node -v) 安装完成"
}

# ─── 安装 Python ────────────────────────────────
install_python() {
    log_info "正在安装 Python 3..."
    case $(detect_os) in
        ubuntu|debian)
            apt-get install -y python3 python3-pip
            ;;
        centos|rhel|fedora|almalinux|rocky)
            yum install -y python3 python3-pip
            ;;
        alpine)
            apk add python3 py3-pip
            ;;
        darwin|macos)
            if command -v brew &>/dev/null; then
                brew install python3
            else
                log_err "请先安装 Homebrew: https://brew.sh"
                exit 1
            fi
            ;;
        *)
            log_err "不支持的系统: $(detect_os)，请手动安装 Python 3"
            exit 1
            ;;
    esac
    log_ok "Python $(python3 --version 2>&1 | awk '{print $2}') 安装完成"
}

# ─── 安装 SSHX ──────────────────────────────────
install_sshx() {
    log_info "正在安装 SSHX..."
    case $(detect_os) in
        linux|ubuntu|debian|centos|rhel|fedora|almalinux|rocky)
            # SSHX 官方推荐安装方式
            curl -sSf https://sshx.io/get | sh 2>/dev/null || {
                # 备选：直接下载二进制
                ARCH=$(uname -m)
                [ "$ARCH" = "x86_64" ] && ARCH="amd64"
                [ "$ARCH" = "aarch64" ] && ARCH="arm64"
                log_info "正在下载 sshx (${ARCH})..."
                curl -sL "https://github.com/sshx/sshx/releases/latest/download/sshx-${ARCH}-linux.tar.gz" -o /tmp/sshx.tar.gz 2>/dev/null || {
                    log_err "SSHX 下载失败，请访问 https://sshx.io 手动安装"
                    return 1
                }
                tar -xzf /tmp/sshx.tar.gz -C /tmp 2>/dev/null
                cp /tmp/sshx /usr/local/bin/sshx 2>/dev/null || cp /tmp/sshx ~/.local/bin/sshx 2>/dev/null
                chmod +x /usr/local/bin/sshx 2>/dev/null || chmod +x ~/.local/bin/sshx 2>/dev/null
                rm -f /tmp/sshx.tar.gz /tmp/sshx
            }
            ;;
        darwin|macos)
            curl -sSf https://sshx.io/get | sh
            ;;
        *)
            log_err "不支持的系统，请访问 https://sshx.io 手动安装"
            return 1
            ;;
    esac
    log_ok "SSHX $(sshx --version 2>&1 | head -1) 安装完成"
}

# ─── 检查依赖 ───────────────────────────────────
check_deps() {
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════${NC}"
    echo -e "${CYAN}   🔍 正在检查系统依赖...${NC}"
    echo -e "${CYAN}═══════════════════════════════════════${NC}"
    echo ""

    MISSING=""

    # Node.js
    if command -v node &>/dev/null; then
        log_ok "Node.js $(node -v) 已安装"
    else
        log_warn "Node.js 未安装"
        MISSING="$MISSING node"
    fi

    # npm
    if command -v npm &>/dev/null; then
        log_ok "npm $(npm -v) 已安装"
    else
        log_warn "npm 未安装"
        MISSING="$MISSING npm"
    fi

    # Python 3
    if command -v python3 &>/dev/null; then
        log_ok "Python $(python3 --version 2>&1 | awk '{print $2}') 已安装"
    else
        log_warn "Python 3 未安装"
        MISSING="$MISSING python"
    fi

    # SSHX
    if command -v sshx &>/dev/null; then
        log_ok "SSHX $(sshx --version 2>&1 | head -1) 已安装"
    else
        log_warn "SSHX 未安装"
        MISSING="$MISSING sshx"
    fi

    # Git
    if command -v git &>/dev/null; then
        log_ok "Git $(git --version 2>&1 | awk '{print $3}') 已安装"
    else
        log_warn "Git 未安装"
        MISSING="$MISSING git"
    fi

    echo ""
    echo -e "${CYAN}────────────────────────────────────────${NC}"
    echo ""

    if [ -z "$MISSING" ]; then
        log_ok "所有依赖已就绪！"
        return 0
    else
        echo -e "${YELLOW}以下组件需要安装:${NC} $MISSING"
        echo ""
        read -rp "是否自动安装缺失的依赖？(Y/n): " AUTO_INSTALL
        AUTO_INSTALL=${AUTO_INSTALL:-Y}
        if [[ "$AUTO_INSTALL" =~ ^[Yy]$ ]]; then
            install_missing "$MISSING"
        else
            log_err "请手动安装缺失的依赖后重试"
            exit 1
        fi
    fi
}

# ─── 安装缺失组件 ────────────────────────────────
install_missing() {
    NEED_SYS_DEPS=false

    # 需要 root 权限的系统级安装
    if echo "$1" | grep -q "node\|npm\|python\|git"; then
        NEED_SYS_DEPS=true
    fi

    if [ "$NEED_SYS_DEPS" = true ]; then
        if [ "$(id -u)" -ne 0 ]; then
            log_warn "部分依赖需要 root 权限来安装"
            echo -e "${YELLOW}请选择:${NC}"
            echo "  1) 使用 sudo 自动安装（推荐）"
            echo "  2) 跳过系统级依赖，仅安装 SSHX 和项目"
            read -rp "请输入选项 (1/2): " PRIV_CHOICE
            if [ "$PRIV_CHOICE" = "2" ]; then
                log_info "跳过系统级依赖安装..."
                NEED_SYS_DEPS=false
            fi
        fi
    fi

    # 安装缺失的组件
    for dep in $1; do
        case $dep in
            node|npm)
                [ "$NEED_SYS_DEPS" = true ] && install_node
                ;;
            python)
                [ "$NEED_SYS_DEPS" = true ] && install_python
                ;;
            sshx)
                install_sshx
                ;;
            git)
                [ "$NEED_SYS_DEPS" = true ] && install_git
                ;;
        esac
    done
}

# ─── 安装 Git ────────────────────────────────────
install_git() {
    log_info "正在安装 Git..."
    case $(detect_os) in
        ubuntu|debian)
            apt-get install -y git
            ;;
        centos|rhel|fedora|almalinux|rocky)
            yum install -y git
            ;;
        alpine)
            apk add git
            ;;
        darwin|macos)
            if command -v brew &>/dev/null; then
                brew install git
            fi
            ;;
    esac
    log_ok "Git $(git --version 2>&1 | awk '{print $3}') 安装完成"
}

# ─── 克隆项目 ──────────────────────────────────
clone_project() {
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════${NC}"
    echo -e "${CYAN}   📦 正在拉取瀚海未来项目...${NC}"
    echo -e "${CYAN}═══════════════════════════════════════${NC}"
    echo ""

    if [ -d "$INSTALL_DIR" ]; then
        log_warn "目标目录已存在: $INSTALL_DIR"
        read -rp "是否覆盖？(y/N): " OVERWRITE
        if [[ "$OVERWRITE" =~ ^[Yy]$ ]]; then
            rm -rf "$INSTALL_DIR"
        else
            log_info "跳过克隆，使用现有目录"
            return 0
        fi
    fi

    git clone --depth=1 "$REPO_URL" "$INSTALL_DIR"
    log_ok "项目已克隆到 $INSTALL_DIR"
}

# ─── 安装项目依赖 ──────────────────────────────
install_project_deps() {
    echo ""
    log_info "正在安装项目依赖..."
    cd "$INSTALL_DIR"
    npm install --production 2>/dev/null || npm install
    log_ok "项目依赖安装完成"
}

# ─── 启动项目 ──────────────────────────────────
start_project() {
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════${NC}"
    echo -e "${GREEN}   🚀 所有安装已完成！${NC}"
    echo -e "${CYAN}═══════════════════════════════════════${NC}"
    echo ""
    read -rp "是否立即启动瀚海未来项目？(Y/n): " START_NOW
    START_NOW=${START_NOW:-Y}
    if [[ "$START_NOW" =~ ^[Yy]$ ]]; then
        echo ""
        cd "$INSTALL_DIR"
        log_info "使用 Node.js 启动服务..."
        node server.js &
        SERVER_PID=$!
        sleep 2
        echo ""
        echo -e "${GREEN}╔══════════════════════════════════════╗${NC}"
        echo -e "${GREEN}║   🌊 瀚海未来已启动！                ║${NC}"
        echo -e "${GREEN}║                                      ║${NC}"
        echo -e "${GREEN}║   📍 本地访问:                       ║${NC}"
        echo -e "${GREEN}║   http://localhost:3211               ║${NC}"
        echo -e "${GREEN}║                                      ║${NC}"
        echo -e "${GREEN}║   📝 项目目录:                       ║${NC}"
        echo -e "${GREEN}║   $INSTALL_DIR        ║${NC}"
        echo -e "${GREEN}║                                      ║${NC}"
        echo -e "${GREEN}║   🛑 停止服务:                       ║${NC}"
        echo -e "${GREEN}║   node -e \"process.kill($SERVER_PID)\"${NC}"
        echo -e "${GREEN}╚══════════════════════════════════════╝${NC}"
        echo ""
        log_info "服务运行在 http://localhost:3211"
        log_info "按 Ctrl+C 停止服务"
        wait $SERVER_PID
    else
        echo ""
        echo -e "${GREEN}╔══════════════════════════════════════╗${NC}"
        echo -e "${GREEN}║   安装完成！                        ║${NC}"
        echo -e "${GREEN}║   手动启动:                         ║${NC}"
        echo -e "${GREEN}║   cd $INSTALL_DIR    ║${NC}"
        echo -e "${GREEN}║   node server.js                    ║${NC}"
        echo -e "${GREEN}╚══════════════════════════════════════╝${NC}"
    fi
}

# ─── 主流程 ────────────────────────────────────
main() {
    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                                      ║${NC}"
    echo -e "${CYAN}║   🌊 瀚海未来 · 一键安装脚本          ║${NC}"
    echo -e "${CYAN}║   Hanhai Future Installer             ║${NC}"
    echo -e "${CYAN}║                                      ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════╝${NC}"
    echo ""

    # 检查系统包管理器
    if command -v apt-get &>/dev/null; then
        PKG_MGR="apt-get"
    elif command -v yum &>/dev/null; then
        PKG_MGR="yum"
    elif command -v apk &>/dev/null; then
        PKG_MGR="apk"
    elif command -v brew &>/dev/null; then
        PKG_MGR="brew"
    else
        log_warn "未检测到包管理器，部分依赖可能需要手动安装"
    fi

    check_deps
    clone_project
    install_project_deps
    start_project
}

main "$@"