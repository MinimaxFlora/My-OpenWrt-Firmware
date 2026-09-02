#!/bin/bash
# ==============================================================================
# 脚本名称: 自定义 Feed 源添加脚本
# 运行阶段: feeds 更新前执行
# 功能说明: 在 feeds.conf.default 文件末尾追加自定义的第三方软件源 / 源码包
# 参考项目: https://github.com/MinimaxFlora/My-OpenWrt-Firmware
# ==============================================================================

# 1. 检查当前是否处于 openwrt 根目录下
if [ ! -f "feeds.conf.default" ]; then
    echo "❌ 错误: 未找到 feeds.conf.default 文件，请确保在 openwrt 根目录执行！"
    exit 1
fi

echo "📦 正在添加自定义扩展源..."

# 2. 追加第三方软件源 (按需取消注释并修改下方地址)
# 格式: src-git <源名称> <Git仓库地址>;<分支名称>
echo "src-git custom_feed https://github.com/MinimaxFlora/openwrt_package.git;master" >> feeds.conf.default

echo "✨ 自定义 Feed 源配置已完成！"
