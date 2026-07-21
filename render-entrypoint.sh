#!/bin/bash
set -e

# Render 特殊处理脚本
# 1. 处理 config.yaml
# 2. 设置持久化存储路径
# 3. 处理端口配置

echo "=== Render 部署启动脚本 ==="

# 检查是否存在 config.yaml,如果不存在则从示例创建
if [ ! -f "/CLIProxyAPI/config.yaml" ]; then
    echo "未找到 config.yaml,从 config.example.yaml 创建..."
    cp /CLIProxyAPI/config.example.yaml /CLIProxyAPI/config.yaml

    # 为 Render 环境调整配置
    echo "调整 Render 环境配置..."

    # 1. 启用远程管理(Render 从公网访问)
    sed -i 's/allow-remote: false/allow-remote: true/g' /CLIProxyAPI/config.yaml

    # 2. 启用插件(如果需要)
    sed -i 's/plugins:/plugins:\n  enabled: true/g' /CLIProxyAPI/config.yaml || true

    # 3. 设置生产模式
    sed -i 's/commercial-mode: false/commercial-mode: true/g' /CLIProxyAPI/config.yaml
    sed -i 's/logging-to-file: false/logging-to-file: true/g' /CLIProxyAPI/config.yaml

    echo "配置调整完成"
fi

# 确保持久化目录存在并设置正确的路径
mkdir -p /data/auths /data/logs

# 创建符号链接,将 auths 和 logs 指向持久化磁盘
if [ ! -L "/root/.cli-proxy-api" ]; then
    ln -sf /data/auths /root/.cli-proxy-api
    echo "已链接 auths 目录到持久化存储: /data/auths"
fi

if [ ! -d "/CLIProxyAPI/logs" ] || [ ! -L "/CLIProxyAPI/logs" ]; then
    rm -rf /CLIProxyAPI/logs 2>/dev/null || true
    ln -sf /data/logs /CLIProxyAPI/logs
    echo "已链接 logs 目录到持久化存储: /data/logs"
fi

# 显示环境信息
echo "工作目录: $(pwd)"
echo "持久化存储挂载点: /data"
echo "认证数据目录: /root/.cli-proxy-api -> /data/auths"
echo "日志目录: /CLIProxyAPI/logs -> /data/logs"

# 检查必需的环境变量
if [ -z "$MANAGEMENT_PASSWORD" ]; then
    echo "⚠️  警告: MANAGEMENT_PASSWORD 未设置,管理面板将无法使用"
    echo "   请在 Render Dashboard 中设置此环境变量"
fi

# 启动服务
echo "=== 启动 CLIProxyAPI ==="
exec /CLIProxyAPI/CLIProxyAPI "$@"
