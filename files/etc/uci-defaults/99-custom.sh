#!/bin/sh

. /etc/os-release
. /lib/functions/uci-defaults.sh

[ $(uname -m) = "x86_64" ] && alias board_name="echo x86_64"

# OTA 在线更新
OTA_URL="https://api.kejizero.xyz/openwrt-25.12/ota.json"

# 时区与主机名
uci -q set system.@system[0].hostname='ZeroWrt'
uci set system.@system[0].timezone=CST-8
uci set system.@system[0].zonename=Asia/Shanghai
uci commit system

# 日志级别
uci set system.@system[0].conloglevel='1'
uci set system.@system[0].cronloglevel='9'
uci commit system

# 添加 Kmod支持
distfeeds=/etc/apk/repositories.d/distfeeds.list
echo "https://core.kejizero.xyz/25.12/targets/x86/64/$(grep kernel /etc/apk/world | awk -F= '{print $2}')/packages.adb" >> "$distfeeds"

# Nginx 设置
uci set nginx.global.uci_enable='true'
uci del nginx._lan
uci del nginx._redirect2ssl
uci add nginx server
uci rename nginx.@server[0]='_lan'
uci set nginx._lan.server_name='_lan'
uci add_list nginx._lan.listen='80 default_server'
uci add_list nginx._lan.listen='[::]:80 default_server'
#uci add_list nginx._lan.include='restrict_locally'
uci add_list nginx._lan.include='conf.d/*.locations'
uci set nginx._lan.access_log='off; # logd openwrt'
uci commit nginx
service nginx restart

# Docker 镜像源
if [ -f /etc/config/dockerd ] && [ $(grep -c daocloud.io /etc/config/dockerd) -eq '0' ]; then
    uci add_list dockerd.globals.registry_mirrors="https://docker.m.daocloud.io"
    uci commit dockerd
fi

# 网络诊断
if [ $(uci -q get luci.diag.ping) = "openwrt.org" ]; then
    uci set luci.diag.dns='www.qq.com'
    uci set luci.diag.ping='www.qq.com'
    uci set luci.diag.route='www.qq.com'
    uci commit luci
fi

# 关闭 coremark
sed -i '/coremark/d' /etc/crontabs/root
crontab /etc/crontabs/root

# 清理
rm -rf /etc/profile.d/busybox-history-file.sh

exit 0
