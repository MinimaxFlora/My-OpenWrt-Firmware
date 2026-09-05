#!/usr/bin/env bash
# ==============================================================================
# ZeroWrt Firmware Post-Build Processing Engine
# 运行阶段: 固件编译完成后执行 (Post-build)
# 功能说明: 提取内核 Hash 生成专属索引目录、整理 kmod 依赖、生成 OTA 升级索引 (ota.json)
# ==============================================================================

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}[*] 开始执行固件后期处理脚本...${NC}"

# ==============================================================================
# 1. 生成内核索引与 kmod 包整理
# ==============================================================================
echo -e "\n${BLUE}[*] 正在生成内核索引并打包 kmod...${NC}"

KERNEL_VER_FILE="target/linux/generic/kernel-6.12"
kmodpkg_name=""

if [ -f "$KERNEL_VER_FILE" ]; then
    get_kernel_version=$(cat "$KERNEL_VER_FILE")
    
    kmod_base=$(echo -e "$get_kernel_version" | awk -F'HASH-' '{print $2}' | awk '{print $1}')
    kmod_hash=$(echo -e "$kmod_base" | tail -1 | md5sum | awk '{print $1}')
    
    kmodpkg_name="${kmod_base}~${kmod_hash}-r1"
    
    echo -e "${GREEN}[+] 提取到内核 kmod 目录名称: ${kmodpkg_name}${NC}"

    mkdir -p "$kmodpkg_name"
    cp -a bin/targets/x86/*/packages/* "$kmodpkg_name/" 2>/dev/null || true
    rm -f "$kmodpkg_name/Packages"*
    
    cp -a bin/packages/x86_64/base/rtl88*a-firmware*.apk "$kmodpkg_name/" 2>/dev/null || true
    
    tar -czf "../${kmodpkg_name}.tar.gz" "$kmodpkg_name"
    echo -e "${GREEN}[+] kmod 依赖包打包完成: ${kmodpkg_name}.tar.gz${NC}"
    
    if [ -n "$GITHUB_ENV" ]; then
        echo "KMOD_PKG_NAME=${kmodpkg_name}" >> "$GITHUB_ENV"
    fi
else
    echo -e "${YELLOW}[!] 警告: 未找到 ${KERNEL_VER_FILE}，跳过内核索引生成。${NC}"
fi

# ==============================================================================
# 2. 生成 OTA 升级索引 (ota.json)
# ==============================================================================
echo -e "\n${BLUE}[*] 正在生成 OTA (ota.json) 升级索引...${NC}"

CURRENT_DATE=$(date +%s)
OTA_URL="https://github.com/MinimaxFlora/My-OpenWrt-Firmware/releases/download"

VERSION=$(curl -sI "https://github.com/MinimaxFlora/My-OpenWrt-Firmware/releases/latest" \
  | grep -i '^location:' \
  | sed -E 's#.*releases/tag/([^[:space:]\r\n]+).*#\1#')

[ -z "$VERSION" ] && VERSION="latest"
echo -e "${GREEN}[+] 获取到远端最新版本 Tag: ${VERSION}${NC}"

FIRMWARE_FILE=$(ls bin/targets/x86/64*/*-generic-squashfs-combined-efi.img.gz 2>/dev/null | head -n 1)

if [ -n "$FIRMWARE_FILE" ] && [ -f "$FIRMWARE_FILE" ]; then
    SHA256=$(sha256sum "$FIRMWARE_FILE" | awk '{print $1}')
    echo -e "${GREEN}[+] 计算固件 SHA256: ${SHA256}${NC}"
else
    SHA256="UNKNOWN"
    echo -e "${YELLOW}[!] 警告: 未找到本地固件文件，SHA256 将留空。${NC}"
fi

cat > ../ota.json <<EOF
{
  "x86_64": [
    {
      "build_date": "$CURRENT_DATE",
      "sha256sum": "$SHA256",
      "url": "$OTA_URL/$VERSION/openwrt-x86-64-generic-squashfs-combined-efi.img.gz"
    }
  ]
}
EOF

echo -e "${GREEN}[+] ota.json 升级索引生成成功！${NC}"
