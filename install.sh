#!/bin/bash

# --- 颜色定义 ---
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # 无颜色

# --- 配置区 ---
APP_NAME="pve-pci-fixer"
INSTALL_DIR="/usr/local/bin"
CONF_DIR="/etc/pve-pci-fixer"
REPO="yituorou/pve-pci-fixer"
# 默认安装最新 Release；可通过环境变量指定版本，例如：VERSION=v0.2.0 bash install.sh
VERSION="${VERSION:-latest}"
# 国内网络可通过 GitHub 加速代理下载，例如：GH_PROXY=https://ghfast.top/ bash install.sh
GH_PROXY="${GH_PROXY:-}"
if [ -n "$GH_PROXY" ] && [ "${GH_PROXY%/}" = "$GH_PROXY" ]; then
    GH_PROXY="$GH_PROXY/"
fi
if [ "$VERSION" = "latest" ]; then
    # releases/latest/download/<asset> 由 GitHub 自动跳转到最新版本，直连和代理都适用
    BINARY_URL="${GH_PROXY}https://github.com/$REPO/releases/latest/download/$APP_NAME"
else
    BINARY_URL="${GH_PROXY}https://github.com/$REPO/releases/download/$VERSION/$APP_NAME"
fi
SERVICE_PATH="/etc/systemd/system/$APP_NAME.service"

echo -e "${BLUE}>>> Starting PvePciFixer Installation...${NC}"

# 1. 权限检查
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}[Error]${NC} 请使用 root 权限运行"
  exit 1
fi

# 2. 创建目录
mkdir -p $CONF_DIR

# 3. 下载并赋权
echo -e "${BLUE}[1/4]${NC} Downloading binary from GitHub ($REPO, $VERSION)${GH_PROXY:+ via $GH_PROXY}..."
# 先下载到临时目录，校验通过后再替换，避免升级时覆盖正在运行的二进制 (Text file busy)
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT
if ! curl -fL "$BINARY_URL" -o "$TMP_DIR/$APP_NAME"; then
    echo -e "${RED}[Error]${NC} 下载失败，请检查网络或版本号 ($VERSION) 是否存在"
    exit 1
fi

# 检查下载的文件大小，防止下载到 404 文本
FILE_SIZE=$(stat -c%s "$TMP_DIR/$APP_NAME")
if [ $FILE_SIZE -lt 1000 ]; then
    echo -e "${RED}[Error]${NC} 下载的文件异常小 ($FILE_SIZE bytes)，可能是链接已失效。"
    exit 1
fi

# 校验 SHA-256 (v0.2.0 起的 Release 附带 .sha256 文件)
if curl -fsSL "$BINARY_URL.sha256" -o "$TMP_DIR/$APP_NAME.sha256"; then
    if ! (cd "$TMP_DIR" && sha256sum -c "$APP_NAME.sha256" >/dev/null); then
        echo -e "${RED}[Error]${NC} SHA-256 校验失败，已中止安装"
        exit 1
    fi
    echo -e "${GREEN}[OK]${NC} SHA-256 校验通过"
else
    echo -e "${BLUE}[Info]${NC} 该版本未提供 .sha256，跳过校验"
fi

install -m 755 "$TMP_DIR/$APP_NAME" "$INSTALL_DIR/$APP_NAME"
echo -e "${GREEN}[OK]${NC} 已安装 $APP_NAME $VERSION"

# 4. 初始化默认配置
echo -e "${BLUE}[2/4]${NC} Creating default config.yml..."
if [ ! -f "$CONF_DIR/config.yml" ]; then
    cat <<EOF > $CONF_DIR/config.yml
mode: "prod"
enable_web: true
targets: []
EOF
fi

# 5. 配置 Systemd 服务
echo -e "${BLUE}[3/4]${NC} Configuring Systemd service..."
cat <<EOF > $SERVICE_PATH
[Unit]
Description=PVE PCI Address Fixer Service
# /etc/pve 由 pve-cluster (pmxcfs) 挂载，必须等它就绪
Wants=pve-cluster.service
After=network.target pve-cluster.service
# 必须在 PVE 自动启动虚拟机之前完成修复
Before=pve-guests.service

[Service]
Type=simple
WorkingDirectory=$CONF_DIR
# ExecStartPre 同步执行，完成后本服务才算启动，pve-guests 会等待它
ExecStartPre=$INSTALL_DIR/$APP_NAME --fix-only
TimeoutStartSec=120
ExecStart=$INSTALL_DIR/$APP_NAME
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# 6. 激活服务
echo -e "${BLUE}[4/4]${NC} Enabling and starting service..."
systemctl daemon-reload
systemctl enable $APP_NAME
systemctl restart $APP_NAME

echo -e "${GREEN}------------------------------------------------${NC}"
echo -e "${GREEN}  Installation Successful! / 安装成功！${NC}"
echo -e "  Web UI: http://$(hostname -I | awk '{print $1}'):3000"
echo -e "  Config: $CONF_DIR/config.yml"
echo -e "${GREEN}------------------------------------------------${NC}"