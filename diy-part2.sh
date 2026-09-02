#!/bin/bash
# ==============================================================================
# 脚本名称: Feed 更新后处理脚本
# 运行阶段: feeds 更新后执行 (Post-update)
# 功能说明: 用于处理 feeds 更新后的各项调整，如覆盖软件包、调整主题、
#           修改内核配置或应用自定义补丁。
# 参考项目: https://github.com/MinimaxFlora/My-OpenWrt-Firmware
# ==============================================================================

# 1. 检查当前是否处于 OpenWrt 根目录下
if [ ! -f "include/version.mk" ]; then
    echo "❌ 错误: 未找到 OpenWrt 根目录，请确保在正确的工作目录执行！"
    exit 1
fi

echo "⚙️ 正在执行 feeds 更新后的自定义调整..."

# 2. 预留区域：在此处编写更新后的调整逻辑 (按需取消注释并修改)
# ------------------------------------------------------------------------------
# 替换或删除冲突的软件包
rm -rf feeds/packages/lang/golang

# 示例 B: 修改默认主题配置
# sed -i 's/luci-theme-bootstrap/luci-theme-nebula/g' feeds/luci/collections/luci/Makefile
# ------------------------------------------------------------------------------

# Go 1.27
git clone https://github.com/sbwml/packages_lang_golang -b 27.x feeds/packages/lang/golang
# ------------------------------------------------------------------------------

# V2ray 地理数据
git clone --depth=1 https://github.com/sbwml/v2ray-geodata package/new/v2ray-geodata
# ------------------------------------------------------------------------------

# Mosdns 转发器
git clone --depth=1 -b v5 https://github.com/sbwml/luci-app-mosdns package/new/luci-app-mosdns
# ------------------------------------------------------------------------------

# OpenList 网盘
git clone --depth=1 -b main https://github.com/sbwml/luci-app-openlist2 package/new/luci-app-openlist2

# Argon 主题
git clone --depth=1 -b master https://github.com/jerrykuku/luci-theme-argon package/new/luci-theme-argon
git clone --depth=1 -b master https://github.com/jerrykuku/luci-app-argon-config package/new/luci-app-argon-config
# ------------------------------------------------------------------------------

# XL2TPD 隧道
sed -i '/ifneq (0,0)/i TARGET_CFLAGS += -std=gnu17\n' feeds/packages/net/xl2tpd/Makefile
# ------------------------------------------------------------------------------

# 应用 GENERIC 补丁
patch -p1 < "$GITHUB_WORKSPACE/patches/GENERIC/0001-build-kernel-add-out-of-tree-kernel-config.patch"

# 应用 LUCI 补丁
pushd feeds/luci
patch -p1 < "$GITHUB_WORKSPACE/patches/LUCI/0001-luci-mod-system-add-modal-overlay-dialog-to-reboot.patch"
patch -p1 < "$GITHUB_WORKSPACE/patches/LUCI/0002-luci-mod-status-displays-actual-process-memory-usage.patch"
patch -p1 < "$GITHUB_WORKSPACE/patches/LUCI/0003-luci-mod-status-storage-index-applicable-only-to-val.patch"
patch -p1 < "$GITHUB_WORKSPACE/patches/LUCI/0004-luci-mod-status-firewall-disable-legacy-firewall-rul.patch"
patch -p1 < "$GITHUB_WORKSPACE/patches/LUCI/0005-luci-mod-system-add-refresh-interval-setting.patch"
patch -p1 < "$GITHUB_WORKSPACE/patches/LUCI/0006-luci-mod-system-mounts-add-docker-directory-mount-po.patch"
patch -p1 < "$GITHUB_WORKSPACE/patches/LUCI/0007-luci-mod-system-add-ucitrack-luci-mod-system-zram.js.patch"
patch -p1 < "$GITHUB_WORKSPACE/patches/LUCI/0008-luci-mod-status-dmesg-add-ANSI-terminal-color-and-re.patch"
popd
# ------------------------------------------------------------------------------

echo "✨ Feed 更新后的各项调整已全部完成！"
