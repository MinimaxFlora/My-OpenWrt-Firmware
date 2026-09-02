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
# 示例 A: 替换或删除冲突的软件包
# rm -rf package/lean/some-conflict-package

# 示例 B: 修改默认主题配置
# sed -i 's/luci-theme-bootstrap/luci-theme-nebula/g' feeds/luci/collections/luci/Makefile
# ------------------------------------------------------------------------------

# xl2tpd
sed -i '/ifneq (0,0)/i TARGET_CFLAGS += -std=gnu17\n' feeds/packages/net/xl2tpd/Makefile
# ------------------------------------------------------------------------------

echo "✨ Feed 更新后的各项调整已全部完成！"
