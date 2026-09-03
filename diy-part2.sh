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
rm -rf package/system/urngd
rm -rf package/firmware/intel-microcode
rm -rf feeds/packages/lang/{golang,rust,node}
rm -rf feeds/packages/utils/{docker,dockerd,containerd,runc}
rm -rf feeds/luci/applications/luci-app-dockerman

# 示例 B: 修改默认主题配置
# sed -i 's/luci-theme-bootstrap/luci-theme-nebula/g' feeds/luci/collections/luci/Makefile
# ------------------------------------------------------------------------------

# Go 1.27
git clone --depth=1 -b 27.x https://github.com/sbwml/packages_lang_golang feeds/packages/lang/golang
# ------------------------------------------------------------------------------

# Rust
git clone --depth=1 https://github.com/sbwml/packages_lang_rust feeds/packages/lang/rust
# ------------------------------------------------------------------------------

# Node - Prebuilt
git clone --depth=1 -b packages-25.12 https://github.com/sbwml/feeds_packages_lang_node feeds/packages/lang/node
# ------------------------------------------------------------------------------

# V2ray 地理数据
git clone --depth=1 https://github.com/sbwml/v2ray-geodata package/new/v2ray-geodata
# ------------------------------------------------------------------------------

# Mosdns 转发器
git clone --depth=1 -b v5 https://github.com/sbwml/luci-app-mosdns package/new/luci-app-mosdns
# ------------------------------------------------------------------------------

# OpenList 网盘
git clone --depth=1 -b main https://github.com/sbwml/luci-app-openlist2 package/new/luci-app-openlist2
# ------------------------------------------------------------------------------

# 蓝牙
git clone --depth=1 https://github.com/sbwml/luci-app-bluetooth package/new/luci-app-bluetooth
git clone --depth=1 https://github.com/sbwml/package_new_bluez-alsa package/new/bluez-alsa
# ------------------------------------------------------------------------------

# 磁盘管理
git clone --depth=1 https://github.com/sbwml/luci-app-diskman package/new/diskman
# ------------------------------------------------------------------------------

# 文件管理
rm -rf feeds/luci/applications/luci-app-filemanager
git clone --depth=1 https://github.com/sbwml/luci-app-filemanager package/new/luci-app-filemanager
# ------------------------------------------------------------------------------

# QuickFlie文件管理
git clone --depth=1 https://github.com/sbwml/luci-app-quickfile package/new/quickfile
# ------------------------------------------------------------------------------

# AirPlay2
git clone --depth=1 https://github.com/sbwml/luci-app-airplay2 package/new/airplay2
# ------------------------------------------------------------------------------

# WebDav
git clone --depth=1 https://github.com/sbwml/luci-app-webdav package/new/luci-app-webdav
# ------------------------------------------------------------------------------

# Airconnect
git clone --depth=1 https://github.com/sbwml/luci-app-airconnect package/new/airconnect
# ------------------------------------------------------------------------------

# qBittorrent
git clone --depth=1 https://github.com/sbwml/luci-app-qbittorrent package/new/qbittorrent
# ------------------------------------------------------------------------------

# Docker 管理
git clone --depth=1 https://github.com/sbwml/luci-app-dockerman -b openwrt-25.12 feeds/luci/applications/luci-app-dockerman
git clone --depth=1 https://github.com/sbwml/packages_utils_docker feeds/packages/utils/docker
git clone --depth=1 https://github.com/sbwml/packages_utils_dockerd feeds/packages/utils/dockerd
git clone --depth=1 https://github.com/sbwml/packages_utils_containerd feeds/packages/utils/containerd
git clone --depth=1 https://github.com/sbwml/packages_utils_runc feeds/packages/utils/runc
# ------------------------------------------------------------------------------

# Urugd
git clone --depth=1 https://github.com/sbwml/package_system_urngd package/system/urngd
# ------------------------------------------------------------------------------

# TCP-Brutal
git clone --depth=1 https://github.com/sbwml/package_kernel_tcp-brutal package/kernel/tcp-brutal

# Intel-Microcode
git clone --depth=1 https://github.com/MinimaxFlora/intel-microcode package/firmware/intel-microcode

# Argon 主题
git clone --depth=1 -b master https://github.com/jerrykuku/luci-theme-argon package/new/luci-theme-argon
git clone --depth=1 -b master https://github.com/jerrykuku/luci-app-argon-config package/new/luci-app-argon-config
# ------------------------------------------------------------------------------

# Attr 使用默认工具链
sed -i '/PKG_BUILD_PARALLEL/aPKG_BUILD_FLAGS:=no-mold' feeds/packages/utils/attr/Makefile
# ------------------------------------------------------------------------------

# 禁用缓解措施
sed -i 's/noinitrd/noinitrd mitigations=off/g' target/linux/x86/image/grub-efi.cfg
# ------------------------------------------------------------------------------

# DDNS - 修复启动
sed -i '/boot()/,+2d' feeds/packages/net/ddns-scripts/files/etc/init.d/ddns
# ------------------------------------------------------------------------------

# NlbWmon - 禁用系统日志
sed -i 's/stderr 1/stderr 0/g' feeds/packages/net/nlbwmon/files/nlbwmon.init
# ------------------------------------------------------------------------------

# NetdData
sed -i 's/syslog/none/g' feeds/packages/admin/netdata/files/netdata.conf
# ------------------------------------------------------------------------------

# 设置默认密码
default_password=$(openssl passwd -5 password)
sed -i "s|^root:[^:]*:|root:${default_password}:|" package/base-files/files/etc/shadow
# ------------------------------------------------------------------------------

# 切换 Nginx Web 管理
sed -i 's/+uhttpd /+luci-nginx /g' feeds/luci/collections/luci/Makefile
sed -i 's/+uhttpd-mod-ubus //' feeds/luci/collections/luci/Makefile
sed -i 's/+uhttpd /+luci-nginx /g' feeds/luci/collections/luci-light/Makefile
sed -i "s/+luci /+luci-nginx /g" feeds/luci/collections/luci-ssl-openssl/Makefile
sed -i "s/+luci /+luci-nginx /g" feeds/luci/collections/luci-ssl/Makefile
sed -i 's/+uhttpd +uhttpd-mod-ubus /+luci-nginx /g' feeds/packages/net/wg-installer/Makefile
sed -i '/uhttpd-mod-ubus/d' feeds/luci/collections/luci-light/Makefile
sed -i 's/+luci-nginx \\$/+luci-nginx/' feeds/luci/collections/luci-light/Makefile
# ------------------------------------------------------------------------------

# LibuBox 开启 02 级优化
sed -i '/TARGET_CFLAGS/ s/$/ -O2/' package/libs/libubox/Makefile
# ------------------------------------------------------------------------------

# Procps-ng - TOP
sed -i 's/enable-skill/enable-skill --disable-modern-top/g' feeds/packages/utils/procps-ng/Makefile
# ------------------------------------------------------------------------------

# TTYD
sed -i 's/services/system/g' feeds/luci/applications/luci-app-ttyd/root/usr/share/luci/menu.d/luci-app-ttyd.json
sed -i '3 a\\t\t"order": 50,' feeds/luci/applications/luci-app-ttyd/root/usr/share/luci/menu.d/luci-app-ttyd.json
sed -i 's/procd_set_param stdout 1/procd_set_param stdout 0/g' feeds/packages/utils/ttyd/files/ttyd.init
sed -i 's/procd_set_param stderr 1/procd_set_param stderr 0/g' feeds/packages/utils/ttyd/files/ttyd.init
# ------------------------------------------------------------------------------

# Nginx - 最新版
rm -rf feeds/packages/net/nginx
git clone --depth=1 -b openwrt-25.12 https://github.com/sbwml/feeds_packages_net_nginx feeds/packages/net/nginx -b openwrt-25.12
sed -i 's/procd_set_param stdout 1/procd_set_param stdout 0/g;s/procd_set_param stderr 1/procd_set_param stderr 0/g' feeds/packages/net/nginx/files/nginx.init
# ------------------------------------------------------------------------------

# Nginx - Ubus
sed -i 's/ubus_parallel_req 2/ubus_parallel_req 6/g' feeds/packages/net/nginx/files-luci-support/60_nginx-luci-support
sed -i '/ubus_parallel_req/a\        ubus_script_timeout 300;' feeds/packages/net/nginx/files-luci-support/60_nginx-luci-support
# ------------------------------------------------------------------------------

# Nginx-Util
sed -i '/\/etc\/nginx\/uci.conf.template/d' feeds/packages/net/nginx-util/Makefile
# ------------------------------------------------------------------------------

# Uwsgi - 修复超时问题
sed -i '$a cgi-timeout = 600' feeds/packages/net/uwsgi/files-luci-support/luci-*.ini
sed -i '/limit-as/c\limit-as = 5000' feeds/packages/net/uwsgi/files-luci-support/luci-webui.ini
# ------------------------------------------------------------------------------

# 关闭错误日志
sed -i "s/procd_set_param stderr 1/procd_set_param stderr 0/g" feeds/packages/net/uwsgi/files/uwsgi.init
# ------------------------------------------------------------------------------

# Uwsgi - 表现
sed -i 's/threads = 1/threads = 2/g' feeds/packages/net/uwsgi/files-luci-support/luci-webui.ini
sed -i 's/processes = 3/processes = 4/g' feeds/packages/net/uwsgi/files-luci-support/luci-webui.ini
sed -i 's/cheaper = 1/cheaper = 2/g' feeds/packages/net/uwsgi/files-luci-support/luci-webui.ini
# ------------------------------------------------------------------------------

# Rpcd - 修复超时问题
sed -i 's/option timeout 30/option timeout 60/g' package/system/rpcd/files/rpcd.config
sed -i 's#20) \* 1000#60) \* 1000#g' feeds/luci/modules/luci-base/htdocs/luci-static/resources/rpc.js
# ------------------------------------------------------------------------------

# ProFlie
sed -i 's#\\u@\\h:\\w\\\$#\\[\\e[32;1m\\][\\u@\\h\\[\\e[0m\\] \\[\\033[01;34m\\]\\W\\[\\033[00m\\]\\[\\e[32;1m\\]]\\[\\e[0m\\]\\\$#g' package/base-files/files/etc/profile
sed -ri 's/(export PATH=")[^"]*/\1%PATH%:\/opt\/bin:\/opt\/sbin:\/opt\/usr\/bin:\/opt\/usr\/sbin/' package/base-files/files/etc/profile
sed -i '/ENV/i\export TERM=xterm-color' package/base-files/files/etc/profile
# ------------------------------------------------------------------------------

# Bash
sed -i 's#ash#bash#g' package/base-files/files/etc/passwd
sed -i '\#export ENV=/etc/shinit#a export HISTCONTROL=ignoredups' package/base-files/files/etc/profile
# ------------------------------------------------------------------------------

# BUSYBOX
sed -i '/profile\.d/d' package/utils/busybox/Makefile
# ------------------------------------------------------------------------------

# NTP
sed -i 's/0.openwrt.pool.ntp.org/ntp1.aliyun.com/g' package/base-files/files/bin/config_generate
sed -i 's/1.openwrt.pool.ntp.org/ntp2.aliyun.com/g' package/base-files/files/bin/config_generate
sed -i 's/2.openwrt.pool.ntp.org/time1.cloud.tencent.com/g' package/base-files/files/bin/config_generate
sed -i 's/3.openwrt.pool.ntp.org/time2.cloud.tencent.com/g' package/base-files/files/bin/config_generate
# ------------------------------------------------------------------------------

# BOOTSTRAP
sed -i 's/font-size: 13px/font-size: 14px/g' feeds/luci/themes/luci-theme-bootstrap/htdocs/luci-static/bootstrap/cascade.css
sed -i 's/9.75px/10.75px/g' feeds/luci/themes/luci-theme-bootstrap/htdocs/luci-static/bootstrap/cascade.css
# ------------------------------------------------------------------------------

# KERNEL VERMAGIC
sed -ie 's/^\(.\).*vermagic$/\1cp $(TOPDIR)\/.vermagic $(LINUX_DIR)\/.vermagic/' include/kernel-defaults.mk
grep HASH target/linux/generic/kernel-6.12 | awk -F'HASH-' '{print $2}' | awk '{print $1}' | md5sum | awk '{print $1}' > .vermagic
# ------------------------------------------------------------------------------

# 移除 RTL8812AU-CT
sed -i 's/^\([[:space:]]*DEPENDS:=.*\)$/\1 @BROKEN/' package/kernel/rtl8812au-ct/Makefile
# ------------------------------------------------------------------------------

# XL2TPD 隧道
sed -i '/ifneq (0,0)/i TARGET_CFLAGS += -std=gnu17\n' feeds/packages/net/xl2tpd/Makefile
# ------------------------------------------------------------------------------

# 应用 GENERIC 补丁
patch -p1 < "$GITHUB_WORKSPACE/patches/GENERIC/0001-build-kernel-add-out-of-tree-kernel-config.patch"
# ------------------------------------------------------------------------------

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
