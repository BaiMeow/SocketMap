#!/bin/bash

# SocketMap 安装脚本
# 从 GitHub Releases 下载并安装 SocketMap

set -e

# 配置
REPO="BaiMeow/socketmap"
INSTALL_DIR="/usr/bin"
SERVICE_DIR="/etc/systemd/system"
CONFIG_DIR="/etc"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 打印函数
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# 检查是否为 root 用户
check_root() {
    if [ "$EUID" -ne 0 ]; then
        print_error "请使用 root 权限运行此脚本"
        echo "使用命令: sudo $0"
        exit 1
    fi
}

# 检测系统架构
detect_arch() {
    local arch=$(uname -m)
    case $arch in
        x86_64)
            ARCH="x86_64"
            ;;
        aarch64|arm64)
            ARCH="arm64"
            ;;
        armv7l)
            ARCH="armv7"
            ;;
        i386|i686)
            ARCH="i386"
            ;;
        *)
            print_error "不支持的系统架构: $arch"
            exit 1
            ;;
    esac
    print_info "检测到系统架构: $arch -> $ARCH"
}

# 检测操作系统
detect_os() {
    local os=$(uname -s)
    case $os in
        Linux)
            OS="Linux"
            ;;
        Darwin)
            OS="Darwin"
            ;;
        *)
            print_error "不支持的操作系统: $os"
            exit 1
            ;;
    esac
    print_info "检测到操作系统: $OS"
}

# 检查依赖
check_dependencies() {
    local missing_deps=()
    
    if ! command -v curl &> /dev/null && ! command -v wget &> /dev/null; then
        missing_deps+=("curl 或 wget")
    fi
    
    if ! command -v tar &> /dev/null; then
        missing_deps+=("tar")
    fi
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        print_error "缺少必要的依赖: ${missing_deps[*]}"
        echo "请先安装这些依赖"
        exit 1
    fi
}

# 检查 iptables
check_iptables() {
    if ! command -v iptables &> /dev/null; then
        print_warning "未检测到 iptables，SocketMap 需要 iptables 才能正常工作"
        print_warning "请安装 iptables: apt install iptables 或 yum install iptables"
    else
        print_info "检测到 iptables"
    fi
}

# 获取最新版本号
get_latest_version() {
    print_step "获取最新版本信息..."
    
    if command -v curl &> /dev/null; then
        VERSION=$(curl -s "https://api.github.com/repos/$REPO/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
    else
        VERSION=$(wget -qO- "https://api.github.com/repos/$REPO/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
    fi
    
    if [ -z "$VERSION" ]; then
        print_error "无法获取最新版本信息"
        print_info "请检查网络连接或手动指定版本"
        exit 1
    fi
    
    print_info "最新版本: $VERSION"
}

# 下载二进制文件
download_binary() {
    print_step "下载 SocketMap 二进制文件..."
    
    local filename="SocketMap_${OS}_${ARCH}.tar.gz"
    local download_url="https://github.com/$REPO/releases/download/$VERSION/$filename"
    
    print_info "下载地址: $download_url"
    
    local tmp_dir=$(mktemp -d)
    cd "$tmp_dir"
    
    if command -v curl &> /dev/null; then
        if curl -L -f "$download_url" -o "$filename"; then
            print_info "下载成功"
        else
            print_error "下载失败"
            rm -rf "$tmp_dir"
            exit 1
        fi
    else
        if wget -q "$download_url" -O "$filename"; then
            print_info "下载成功"
        else
            print_error "下载失败"
            rm -rf "$tmp_dir"
            exit 1
        fi
    fi
    
    print_info "解压文件..."
    tar -xzf "$filename"
    
    if [ ! -f "socketmap" ]; then
        print_error "解压后未找到 socketmap 二进制文件"
        rm -rf "$tmp_dir"
        exit 1
    fi
    
    BINARY_PATH="$tmp_dir/socketmap"
}

# 安装二进制文件
install_binary() {
    print_step "安装二进制文件..."
    
    if [ -f "$INSTALL_DIR/socketmap" ]; then
        print_warning "检测到已安装的版本，将进行覆盖"
        # 如果服务正在运行，先停止
        if systemctl is-active --quiet socketmap 2>/dev/null; then
            print_info "停止正在运行的服务..."
            systemctl stop socketmap
        fi
    fi
    
    chmod +x "$BINARY_PATH"
    cp "$BINARY_PATH" "$INSTALL_DIR/socketmap"
    
    print_info "二进制文件已安装到: $INSTALL_DIR/socketmap"
    
    # 清理临时文件
    rm -rf "$(dirname $BINARY_PATH)"
}

# 安装 systemd 服务
install_service() {
    print_step "安装 systemd 服务..."
    
    # 创建服务文件
    cat > "$SERVICE_DIR/socketmap.service" << 'EOF'
[Unit]
Description=SocketMap - Port Mapping Tool
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/socketmap -c /etc/socketmap.yaml
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF
    
    systemctl daemon-reload
    print_info "systemd 服务已安装"
}

# 创建配置文件
create_config() {
    print_step "创建配置文件..."
    
    if [ -f "$CONFIG_DIR/socketmap.yaml" ]; then
        print_info "配置文件 $CONFIG_DIR/socketmap.yaml 已存在，跳过创建"
        return
    fi
    
    cat > "$CONFIG_DIR/socketmap.yaml" << 'EOF'
# SocketMap 配置文件
# 格式：
#   映射名称:
#     protocol: tcp 或 udp
#     local_port: 本地端口
#     remote: 目标地址:端口

# web:
#   protocol: tcp
#   local_port: 8080
#   remote: 192.168.1.100:80
EOF
    
    print_warning "请编辑配置文件 $CONFIG_DIR/socketmap.yaml 后启动服务"
}

# 打印使用说明
print_usage() {
    echo ""
    echo "=========================================="
    print_info "✅ SocketMap 安装完成！"
    echo "=========================================="
    echo ""
    echo "📝 快速开始："
    echo "  1. 编辑配置文件:"
    echo "     vim $CONFIG_DIR/socketmap.yaml"
    echo ""
    echo "  2. 启动服务:"
    echo "     systemctl start socketmap"
    echo ""
    echo "  3. 设置开机自启:"
    echo "     systemctl enable socketmap"
    echo ""
    echo "  4. 查看服务状态:"
    echo "     systemctl status socketmap"
    echo ""
    echo "  5. 查看日志:"
    echo "     journalctl -u socketmap -f"
    echo ""
    echo "📖 命令行参数："
    echo "  socketmap -c /path/to/config.yaml    # 指定配置文件路径"
    echo "  socketmap -s 192.168.1.1             # 指定 SNAT 源地址"
    echo ""
    echo "🔧 管理命令："
    echo "  systemctl start socketmap            # 启动服务"
    echo "  systemctl stop socketmap             # 停止服务"
    echo "  systemctl restart socketmap          # 重启服务"
    echo "  systemctl enable socketmap           # 开机自启"
    echo "  systemctl disable socketmap          # 取消自启"
    echo ""
    echo "📦 已安装版本: $VERSION"
    echo "=========================================="
    echo ""
}

# 主函数
main() {
    echo ""
    echo "=========================================="
    echo "  SocketMap 自动安装脚本"
    echo "  GitHub: https://github.com/$REPO"
    echo "=========================================="
    echo ""
    
    check_root
    check_dependencies
    check_iptables
    
    detect_os
    detect_arch
    
    get_latest_version
    download_binary
    install_binary
    install_service
    create_config
    
    print_usage
}

# 执行主函数
main
