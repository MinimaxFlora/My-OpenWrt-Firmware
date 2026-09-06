#!/usr/bin/env bash
# ==============================================================================
# OpenWrt Firmware Post-Build Processing Engine (GitHub Actions Workflow Only)
# ==============================================================================

# 定义终端颜色输出
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}[*] 开始执行固件后期处理脚本...${NC}"

# ==============================================================================
# 1. 生成内核索引与 kmod 包整理
# ==============================================================================
echo -e "\n${BLUE}[*] 正在生成内核索引并打包 kmod...${NC}"

KERNEL_VER_FILE="target/linux/generic/kernel-6.12"

if [ -f "$KERNEL_VER_FILE" ]; then
    kmod_base=$(grep 'HASH-' "$KERNEL_VER_FILE" | head -1 | awk -F'HASH-' '{print $2}' | awk '{print $1}')
    kmod_hash=$(echo -e "$kmod_base" | tail -1 | md5sum | awk '{print $1}')

    kmodpkg_name="${kmod_base}~${kmod_hash}-r1"
    echo -e "${GREEN}[+] 提取到内核 kmod 目录名称: ${kmodpkg_name}${NC}"

    mkdir -p "$kmodpkg_name"
    cp -a bin/targets/x86/*/packages/* "$kmodpkg_name/" 2>/dev/null || true
    rm -f "$kmodpkg_name/Packages"*
    cp -a bin/packages/x86_64/base/rtl88*a-firmware*.apk "$kmodpkg_name/" 2>/dev/null || true

    KMOD_TAR_NAME="x86_64-${kmodpkg_name//\~/.}.tar.gz"
    tar -czf "$KMOD_TAR_NAME" "$kmodpkg_name"

    echo -e "${GREEN}[+] kmod 压缩包打包完成: ${KMOD_TAR_NAME}${NC}"

    # 传递给 GitHub Actions 后续步骤
    echo "KMOD_PKG_NAME=${kmodpkg_name}" >> "$GITHUB_ENV"
    echo "KMOD_TAR_NAME=${KMOD_TAR_NAME}" >> "$GITHUB_ENV"
else
    echo -e "${YELLOW}[!] 警告: 未找到 ${KERNEL_VER_FILE}，跳过内核索引生成。${NC}"
fi

# ==============================================================================
# 2. 生成 OTA 升级索引 (ota.json)
# ==============================================================================
echo -e "\n${BLUE}[*] 正在生成 OTA (ota.json) 升级索引...${NC}"

GH_PROXY="https://gh-proxy.kejizero.xyz"
REPO_NAME="MinimaxFlora/My-OpenWrt-Firmware"
OTA_URL="https://github.com/${REPO_NAME}/releases/download"

# 直接使用工作流传入的变量
VERSION="$RELEASE_TAG"
echo -e "${GREEN}[+] 使用工作流 Release Tag: ${VERSION}${NC}"
echo -e "${GREEN}[+] 使用工作流时间戳: ${CURRENT_DATE}${NC}"

# 获取固件文件及计算 SHA256
FIRMWARE_FILE=$(ls bin/targets/x86/64*/*-generic-squashfs-combined-efi.img.gz 2>/dev/null | head -n 1)

if [ -n "$FIRMWARE_FILE" ] && [ -f "$FIRMWARE_FILE" ]; then
    SHA256=$(sha256sum "$FIRMWARE_FILE" | awk '{print $1}')
    FIRMWARE_NAME=$(basename "$FIRMWARE_FILE")
    echo -e "${GREEN}[+] 找到固件文件: ${FIRMWARE_NAME}${NC}"
    echo -e "${GREEN}[+] 计算固件 SHA256: ${SHA256}${NC}"
else
    echo -e "${YELLOW}[!] 错误: 未找到本地固件文件！${NC}"
    exit 1
fi

# 处理 OTA 日志转义
CLEAN_LOGS=$(echo -e "$OTA_LOGS" | awk '{printf "%s\\n", $0}' | sed 's/\\n$//')

# 生成 ota.json
cat > ota.json <<EOF
{
  "x86_64": [
    {
      "build_date": "$CURRENT_DATE",
      "sha256sum": "$SHA256",
      "url": "$GH_PROXY/$OTA_URL/$VERSION/$FIRMWARE_NAME",
      "logs": "$CLEAN_LOGS"
    }
  ]
}
EOF

echo -e "${GREEN}[+] ota.json 升级索引生成成功！${NC}"
cat ota.json
