#!/usr/bin/env bash
# ==============================================================================
# OpenWrt Feed Post-Update Processing Engine
# 运行阶段: feeds 更新后执行 (Post-update)
# 功能说明: 自动清理冲突包、拉取最新定制组件、配置系统优化参数、应用内核/UI补丁
# 参考项目: https://github.com/MinimaxFlora/My-OpenWrt-Firmware
# ==============================================================================

set -eo pipefail

# ------------------------------------------------------------------------------
# 终端颜色与格式化定义
# ------------------------------------------------------------------------------
if [ -t 1 ]; then
    CLR_RESET='\033[0m'
    CLR_BOLD='\033[1m'
    CLR_RED='\033[31m'
    CLR_GREEN='\033[32m'
    CLR_YELLOW='\033[33m'
    CLR_BLUE='\033[34m'
    CLR_PURPLE='\033[35m'
    CLR_CYAN='\033[36m'
    CLR_GRAY='\033[90m'
else
    CLR_RESET='' CLR_BOLD='' CLR_RED='' CLR_GREEN=''
    CLR_YELLOW='' CLR_BLUE='' CLR_PURPLE='' CLR_CYAN='' CLR_GRAY=''
fi

# ------------------------------------------------------------------------------
# UI 响应与日志输出函数
# ------------------------------------------------------------------------------
log_banner() {
    echo -e "${CLR_CYAN}${CLR_BOLD}"
    echo "=============================================================================="
    echo "  $1"
    echo "=============================================================================="
    echo -e "${CLR_RESET}"
}

log_step() {
    echo -e "\n${CLR_PURPLE}${CLR_BOLD}>>> $1${CLR_RESET}"
}

log_info() {
    echo -e "${CLR_BLUE}[ INFO ]${CLR_RESET} $1"
}

log_success() {
    echo -e "${CLR_GREEN}[  OK  ]${CLR_RESET} $1"
}

log_warn() {
    echo -e "${CLR_YELLOW}[ WARN ]${CLR_RESET} $1"
}

log_error() {
    echo -e "${CLR_RED}[ FAIL ]${CLR_RESET} $1"
}

# ------------------------------------------------------------------------------
# 运行前环境校验
# ------------------------------------------------------------------------------
if [ ! -f "include/version.mk" ]; then
    log_error "未检测到 OpenWrt 根目录特征文件 (include/version.mk)！"
    log_error "请确保在正确的 OpenWrt 源码根目录下运行此脚本。"
    exit 1
fi

START_TIME=$(date +%s)
log_banner "    OpenWrt Post-Update Pipeline Initialization    "

# ------------------------------------------------------------------------------
# 1. 冲突软件包清理
# ------------------------------------------------------------------------------
log_step "阶段 1/5: 清理源码库冲突与冗余组件"

REMOVE_PATHS=(
    "package/system/urngd"
    "package/firmware/intel-microcode"
    "feeds/packages/lang/golang"
    "feeds/packages/lang/rust"
    "feeds/packages/lang/node"
    "feeds/packages/net/xray-core"
    "feeds/packages/net/v2ray-core"
    "feeds/packages/net/v2ray-geodata"
    "feeds/packages/net/sing-box"
    # "feeds/packages/net/samba4"
    "feeds/packages/utils/coremark"
    "feeds/packages/net/zerotier"
    "feeds/packages/net/nginx"
    "feeds/packages/utils/docker"
    "feeds/packages/utils/dockerd"
    "feeds/packages/utils/containerd"
    "feeds/packages/utils/runc"
    "feeds/luci/applications/luci-app-dockerman"
    "feeds/luci/applications/luci-app-filemanager"
)

for target in "${REMOVE_PATHS[@]}"; do
    if [ -e "$target" ]; then
        rm -rf "$target"
        log_info "已移除冲突路径: ${CLR_GRAY}${target}${CLR_RESET}"
    fi
done
log_success "基础环境清理完成。"

# ------------------------------------------------------------------------------
# 2. 定制与替代软件包拉取
# ------------------------------------------------------------------------------
log_step "阶段 2/5: 克隆与注入高质量第三方 Package"

# 定义克隆矩阵 (格式: URL|分支|目标路径)
REPOS=(
    "https://github.com/sbwml/packages_lang_golang|27.x|feeds/packages/lang/golang"
    "https://github.com/sbwml/packages_lang_rust||feeds/packages/lang/rust"
    "https://github.com/sbwml/feeds_packages_lang_node|packages-25.12|feeds/packages/lang/node"
    "https://github.com/sbwml/v2ray-geodata||package/new/v2ray-geodata"
    "https://github.com/sbwml/luci-app-mosdns|v5|package/new/luci-app-mosdns"
    "https://github.com/sbwml/luci-app-openlist2|main|package/new/luci-app-openlist2"
    "https://github.com/sbwml/luci-app-bluetooth||package/new/luci-app-bluetooth"
    "https://github.com/sbwml/package_new_bluez-alsa||package/new/bluez-alsa"
    "https://github.com/sbwml/luci-app-diskman||package/new/diskman"
    "https://github.com/sbwml/luci-app-filemanager||package/new/luci-app-filemanager"
    "https://github.com/sbwml/luci-app-quickfile||package/new/quickfile"
    "https://github.com/sbwml/luci-app-airplay2||package/new/airplay2"
    "https://github.com/sbwml/luci-app-webdav||package/new/webdav"
    "https://github.com/sbwml/luci-app-airconnect||package/new/airconnect"
    "https://github.com/sbwml/luci-app-qbittorrent||package/new/qbittorrent"
    "https://github.com/sbwml/feeds_packages_net_zerotier||feeds/packages/net/zerotier"
    "https://github.com/sbwml/openwrt_helloworld|v5|package/new/helloworld"
    "https://github.com/sbwml/luci-app-dockerman|openwrt-25.12|feeds/luci/applications/luci-app-dockerman"
    "https://gitea.kejizero.xyz/zhao/packages_utils_docker||feeds/packages/utils/docker"
    # "https://github.com/sbwml/feeds_packages_net_samba4||feeds/packages/net/samba4"
    "https://gitea.kejizero.xyz/zhao/packages_utils_dockerd||feeds/packages/utils/dockerd"
    "https://gitea.kejizero.xyz/zhao/packages_utils_containerd||feeds/packages/utils/containerd"
    "https://gitea.kejizero.xyz/zhao/packages_utils_runc||feeds/packages/utils/runc"
    "https://github.com/sbwml/package_system_urngd||package/system/urngd"
    "https://github.com/sbwml/package_kernel_tcp-brutal||package/kernel/tcp-brutal"
    "https://github.com/MinimaxFlora/intel-microcode||package/firmware/intel-microcode"
    "https://github.com/jerrykuku/luci-theme-argon|master|package/new/luci-theme-argon"
    "https://github.com/jerrykuku/luci-app-argon-config|master|package/new/luci-app-argon-config"
    "https://github.com/sbwml/feeds_packages_net_nginx|openwrt-25.12|feeds/packages/net/nginx"
    "https://github.com/sbwml/openwrt_pkgs||package/new/custom"
    "https://github.com/sbwml/OpenAppFilter||package/new/OpenAppFilter"
    "https://github.com/sbwml/luci-app-mentohust||package/new/mentohust"
)

clone_repo() {
    local entry="$1"
    IFS="|" read -r url branch dest <<< "$entry"
    local branch_cmd=""
    
    if [ -n "$branch" ]; then
        branch_cmd="-b $branch"
    fi

    # 若目标路径已存在则预先清理，确保 git clone 能顺利进行
    [ -d "$dest" ] && rm -rf "$dest"

    mkdir -p "$(dirname "$dest")"
    if git clone --depth=1 $branch_cmd "$url" "$dest" &>/dev/null; then
        log_info "拉取成功: ${CLR_CYAN}$(basename "$dest")${CLR_RESET} -> ${CLR_GRAY}${dest}${CLR_RESET}"
    else
        log_warn "拉取异常: ${url} (请检查网络或 URL)"
    fi
}

for item in "${REPOS[@]}"; do
    clone_repo "$item"
done

# 清理拉取第三方仓库中不需要的冲突子包
rm -rf package/new/custom/ddns-scripts-aliyun

log_success "所有目标仓库处理完毕。"

# ------------------------------------------------------------------------------
# 3. 配置文件修改与构建优化 (Sed)
# ------------------------------------------------------------------------------
log_step "阶段 3/5: 执行系统级微调与构建参数优化"

# --- Toolchain & System Performance ---
log_info "调整工具链与系统性能参数..."
sed -i '/PKG_BUILD_PARALLEL/aPKG_BUILD_FLAGS:=no-mold' feeds/packages/utils/attr/Makefile
sed -i 's/noinitrd/noinitrd mitigations=off/g' target/linux/x86/image/grub-efi.cfg
sed -i '/TARGET_CFLAGS/ s/$/ -O2/' package/libs/libubox/Makefile
sed -i 's/enable-skill/enable-skill --disable-modern-top/g' feeds/packages/utils/procps-ng/Makefile
sed -i 's/^\([[:space:]]*DEPENDS:=.*\)$/\1 @BROKEN/' package/kernel/rtl8812au-ct/Makefile
sed -i '/ifneq (0,0)/i TARGET_CFLAGS += -std=gnu17\n' feeds/packages/net/xl2tpd/Makefile

# --- Default Root Password ---
log_info "重置系统默认密码..."
default_password=$(openssl passwd -5 password)
sed -i "s|^root:[^:]*:|root:${default_password}:|" package/base-files/files/etc/shadow

# --- Shell & Terminal Enhancements ---
log_info "优化 Bash 终端交互与 Profile..."
sed -i 's#\\u@\\h:\\w\\\$#\\[\\e[32;1m\\][\\u@\\h\\[\\e[0m\\] \\[\\033[01;34m\\]\\W\\[\\033[00m\\]\\[\\e[32;1m\\]]\\[\\e[0m\\]\\\$#g' package/base-files/files/etc/profile
sed -ri 's/(export PATH=")[^"]*/\1%PATH%:\/opt\/bin:\/opt\/sbin:\/opt\/usr\/bin:\/opt\/usr\/sbin/' package/base-files/files/etc/profile
sed -i '/ENV/i\export TERM=xterm-color' package/base-files/files/etc/profile
sed -i 's#ash#bash#g' package/base-files/files/etc/passwd
sed -i '\#export ENV=/etc/shinit#a export HISTCONTROL=ignoredups' package/base-files/files/etc/profile
sed -i '/profile\.d/d' package/utils/busybox/Makefile

# --- Network & Time Sync ---
log_info "配置网络与中国大陆 NTP 服务器..."
sed -i '/boot()/,+2d' feeds/packages/net/ddns-scripts/files/etc/init.d/ddns
sed -i 's/0.openwrt.pool.ntp.org/ntp1.aliyun.com/g' package/base-files/files/bin/config_generate
sed -i 's/1.openwrt.pool.ntp.org/ntp2.aliyun.com/g' package/base-files/files/bin/config_generate
sed -i 's/2.openwrt.pool.ntp.org/time1.cloud.tencent.com/g' package/base-files/files/bin/config_generate
sed -i 's/3.openwrt.pool.ntp.org/time2.cloud.tencent.com/g' package/base-files/files/bin/config_generate

# --- Services Logging & TTYD Optimization ---
log_info "收紧服务日志输出，调整 TTYD 菜单位置..."
sed -i 's/stderr 1/stderr 0/g' feeds/packages/net/nlbwmon/files/nlbwmon.init
sed -i 's/syslog/none/g' feeds/packages/admin/netdata/files/netdata.conf
sed -i 's/services/system/g' feeds/luci/applications/luci-app-ttyd/root/usr/share/luci/menu.d/luci-app-ttyd.json
sed -i '3 a\t\t"order": 50,' feeds/luci/applications/luci-app-ttyd/root/usr/share/luci/menu.d/luci-app-ttyd.json
sed -i 's/procd_set_param stdout 1/procd_set_param stdout 0/g' feeds/packages/utils/ttyd/files/ttyd.init
sed -i 's/procd_set_param stderr 1/procd_set_param stderr 0/g' feeds/packages/utils/ttyd/files/ttyd.init

# --- LuCI Menu Redirection (Services -> Network) ---
log_info "调整部分 LuCI 应用菜单分类至网络菜单..."
MENU_JSONS=(
    "package/new/custom/luci-app-socat/root/usr/share/luci/menu.d/luci-app-socat.json"
    "package/new/custom/luci-app-netspeedtest/root/usr/share/luci/menu.d/luci-app-netspeedtest.json"
    "package/new/luci-app-netspeedtest/root/usr/share/luci/menu.d/luci-app-netspeedtest.json"
    "feeds/luci/applications/luci-app-netspeedtest/root/usr/share/luci/menu.d/luci-app-netspeedtest.json"
)

for json in "${MENU_JSONS[@]}"; do
    if [ -f "$json" ]; then
        sed -i 's#"admin/services/"#"admin/network/"#g; s#"target": "admin/services/#"target": "admin/network/#g' "$json"
        log_info "已重定向菜单路径: ${CLR_GRAY}$(basename "$json")${CLR_RESET}"
    fi
done

# --- Web Engine (Nginx / uWSGI / Rpcd) Tuning ---
log_info "切换 Web 引擎至 Nginx，全面优化 RPC 与并发响应..."
sed -i 's/+uhttpd /+luci-nginx /g' feeds/luci/collections/luci/Makefile
sed -i 's/+uhttpd-mod-ubus //' feeds/luci/collections/luci/Makefile
sed -i 's/+uhttpd /+luci-nginx /g' feeds/luci/collections/luci-light/Makefile
sed -i "s/+luci /+luci-nginx /g" feeds/luci/collections/luci-ssl-openssl/Makefile
sed -i "s/+luci /+luci-nginx /g" feeds/luci/collections/luci-ssl/Makefile
sed -i 's/+uhttpd +uhttpd-mod-ubus /+luci-nginx /g' feeds/packages/net/wg-installer/Makefile
sed -i '/uhttpd-mod-ubus/d' feeds/luci/collections/luci-light/Makefile
sed -i 's/+luci-nginx \\$/+luci-nginx/' feeds/luci/collections/luci-light/Makefile

sed -i 's/procd_set_param stdout 1/procd_set_param stdout 0/g;s/procd_set_param stderr 1/procd_set_param stderr 0/g' feeds/packages/net/nginx/files/nginx.init
sed -i 's/ubus_parallel_req 2/ubus_parallel_req 6/g' feeds/packages/net/nginx/files-luci-support/60_nginx-luci-support
sed -i '/ubus_parallel_req/a\        ubus_script_timeout 300;' feeds/packages/net/nginx/files-luci-support/60_nginx-luci-support
sed -i '/\/etc\/nginx\/uci.conf.template/d' feeds/packages/net/nginx-util/Makefile

sed -i '$a cgi-timeout = 600' feeds/packages/net/uwsgi/files-luci-support/luci-*.ini
sed -i '/limit-as/c\limit-as = 5000' feeds/packages/net/uwsgi/files-luci-support/luci-webui.ini
sed -i "s/procd_set_param stderr 1/procd_set_param stderr 0/g" feeds/packages/net/uwsgi/files/uwsgi.init
sed -i 's/threads = 1/threads = 2/g' feeds/packages/net/uwsgi/files-luci-support/luci-webui.ini
sed -i 's/processes = 3/processes = 4/g' feeds/packages/net/uwsgi/files-luci-support/luci-webui.ini
sed -i 's/cheaper = 1/cheaper = 2/g' feeds/packages/net/uwsgi/files-luci-support/luci-webui.ini

sed -i 's/option timeout 30/option timeout 60/g' package/system/rpcd/files/rpcd.config
sed -i 's#20) \* 1000#60) \* 1000#g' feeds/luci/modules/luci-base/htdocs/luci-static/resources/rpc.js

# --- Natmap ---
log_info "配置 Natmap..."
sed -i 's/log_stdout:bool:1/log_stdout:bool:0/g;s/log_stderr:bool:1/log_stderr:bool:0/g' feeds/packages/net/natmap/files/natmap.init

pushd feeds/luci >/dev/null
    curl -s "https://raw.githubusercontent.com/MinimaxFlora/My-OpenWrt-Firmware/refs/heads/master/patches/NATMAP/0001-luci-app-natmap-add-default-STUN-server-lists.patch" | patch -p1
popd >/dev/null

# --- FRPC ---
log_info "配置 FRPC..."
sed -i 's/procd_set_param stdout $stdout/procd_set_param stdout 0/g' feeds/packages/net/frp/files/frpc.init
sed -i 's/procd_set_param stderr $stderr/procd_set_param stderr 0/g' feeds/packages/net/frp/files/frpc.init
sed -i 's/stdout stderr //g' feeds/packages/net/frp/files/frpc.init
sed -i '/stdout:bool/d;/stderr:bool/d' feeds/packages/net/frp/files/frpc.init
sed -i '/stdout/d;/stderr/d' feeds/packages/net/frp/files/frpc.config
sed -i 's/env conf_inc/env conf_inc enable/g' feeds/packages/net/frp/files/frpc.init
sed -i "s/'conf_inc:list(string)'/& \\\\/" feeds/packages/net/frp/files/frpc.init
sed -i "/conf_inc:list/a\\\t\t\'enable:bool:0\'" feeds/packages/net/frp/files/frpc.init
sed -i '/procd_open_instance/i\	[ "$enable" -ne 1 ] && return 1\n' feeds/packages/net/frp/files/frpc.init

curl -s "https://raw.githubusercontent.com/MinimaxFlora/My-OpenWrt-Firmware/refs/heads/master/patches/FRPC/001-luci-app-frpc-hide-token.patch" | patch -p1
curl -s "https://raw.githubusercontent.com/MinimaxFlora/My-OpenWrt-Firmware/refs/heads/master/patches/FRPC/002-luci-app-frpc-add-enable-flag.patch" | patch -p1

# --- Samba4 ---
log_info "配置 Samba4..."
# 启用 multi-channel
sed -i '/workgroup/a \\n\t## enable multi-channel' feeds/packages/net/samba4/files/smb.conf.template
sed -i '/enable multi-channel/a \\tserver multi channel support = yes' feeds/packages/net/samba4/files/smb.conf.template

# 默认参数微调
sed -i 's/#aio read size = 0/aio read size = 0/g' feeds/packages/net/samba4/files/smb.conf.template
sed -i 's/#aio write size = 0/aio write size = 0/g' feeds/packages/net/samba4/files/smb.conf.template
sed -i 's/invalid users = root/#invalid users = root/g' feeds/packages/net/samba4/files/smb.conf.template
sed -i 's/bind interfaces only = yes/bind interfaces only = no/g' feeds/packages/net/samba4/files/smb.conf.template
sed -i 's/#create mask/create mask/g' feeds/packages/net/samba4/files/smb.conf.template
sed -i 's/#directory mask/directory mask/g' feeds/packages/net/samba4/files/smb.conf.template

# 修正文件权限掩码
sed -i 's/0666/0644/g;s/0744/0755/g;s/0777/0755/g' feeds/luci/applications/luci-app-samba4/htdocs/luci-static/resources/view/samba4.js
sed -i 's/0666/0644/g;s/0777/0755/g' feeds/packages/net/samba4/files/samba.config
sed -i 's/0666/0644/g;s/0777/0755/g' feeds/packages/net/samba4/files/smb.conf.template

# --- Bootstrap Theme & Vermagic ---
log_info "修正 Bootstrap UI 细节与 Vermagic 哈希计算..."
sed -i 's/font-size: 13px/font-size: 14px/g' feeds/luci/themes/luci-theme-bootstrap/htdocs/luci-static/bootstrap/cascade.css
sed -i 's/9.75px/10.75px/g' feeds/luci/themes/luci-theme-bootstrap/htdocs/luci-static/bootstrap/cascade.css

sed -ie 's/^\(.\).*vermagic$/\1cp $(TOPDIR)\/.vermagic $(LINUX_DIR)\/.vermagic/' include/kernel-defaults.mk
grep HASH target/linux/generic/kernel-6.12 | awk -F'HASH-' '{print $2}' | awk '{print $1}' | md5sum | awk '{print $1}' > .vermagic

log_success "配置与参数微调完成。"

# ------------------------------------------------------------------------------
# 4. 自动化应用 Patches 补丁包
# ------------------------------------------------------------------------------
log_step "阶段 4/5: 应用通用与 LuCI 修复补丁"

WORK_DIR="${GITHUB_WORKSPACE:-.}"

apply_patch() {
    local patch_path="$1"
    local target_dir="${2:-.}"

    if [ -f "$patch_path" ]; then
        log_info "正在应用补丁: ${CLR_GRAY}$(basename "$patch_path")${CLR_RESET}"
        patch -p1 -d "$target_dir" < "$patch_path" > /dev/null
    else
        log_warn "未找到补丁文件，已跳过: ${patch_path}"
    fi
}

# Generic Kernel Patches
apply_patch "$WORK_DIR/patches/GENERIC/0001-build-kernel-add-out-of-tree-kernel-config.patch" "."

# LuCI Patches
LUCI_PATCHES=(
    "0001-luci-mod-system-add-modal-overlay-dialog-to-reboot.patch"
    "0002-luci-mod-status-displays-actual-process-memory-usage.patch"
    "0003-luci-mod-status-storage-index-applicable-only-to-val.patch"
    "0004-luci-mod-status-firewall-disable-legacy-firewall-rul.patch"
    "0005-luci-mod-system-add-refresh-interval-setting.patch"
    "0006-luci-mod-system-mounts-add-docker-directory-mount-po.patch"
    "0007-luci-mod-system-add-ucitrack-luci-mod-system-zram.js.patch"
    "0008-luci-mod-status-dmesg-add-ANSI-terminal-color-and-re.patch"
)

for p in "${LUCI_PATCHES[@]}"; do
    apply_patch "$WORK_DIR/patches/LUCI/$p" "feeds/luci"
done

log_success "补丁打入阶段完成。"

# ------------------------------------------------------------------------------
# 5. 补充与修正 LuCI 简体中文汉化
# ------------------------------------------------------------------------------
log_step "阶段 5/5: 注入自定义语言包 (po/zh_Hans)"

PO_FILE="feeds/luci/modules/luci-base/po/zh_Hans/base.po"

if [ -f "$PO_FILE" ]; then
    TRANSLATIONS=(
        "CPU usage|CPU 使用率"
        "Network Speed|网络速率"
        "Download Rate (RX)|下行速率"
        "Upload Rate (TX)|上行速率"
        "Calculating...|计算中..."
        "No active network interfaces|无活动的网络接口"
        "Confirm Reboot|确认重启"
        "Are you sure you want to reboot the system?|你确认要重启系统？"
        "Confirm|确认"
        "Base Setting|基本设置"
        "NFtables Firewall|NFtables 防火墙"
        "IPtables Firewall|IPtables 防火墙"
        "Refresh interval|刷新间隔"
        "Refresh interval in seconds|刷新间隔（以秒为单位）"
        "Use as docker root directory (/opt)|作为 docker 根目录使用（/opt）"
        "Help & Feedback|帮助与反馈"
        "Project Website|项目主页"
        "Issue Feedback|问题反馈"
        "Donation Address|捐赠地址"
    )

    added_count=0
    for item in "${TRANSLATIONS[@]}"; do
        IFS="|" read -r msgid msgstr <<< "$item"
        # 增加去重检查，仅注入不存在的 msgid
        if ! grep -q "msgid \"$msgid\"" "$PO_FILE"; then
            printf '\nmsgid "%s"\nmsgstr "%s"\n' "$msgid" "$msgstr" >> "$PO_FILE"
            added_count=$((added_count + 1))
        fi
    done
    log_success "成功注入 ${added_count} 条新增汉化词条。"
else
    log_warn "未找到目标 PO 文件: ${PO_FILE}，已跳过汉化补全。"
fi

# ------------------------------------------------------------------------------
# 总结与耗时输出
# ------------------------------------------------------------------------------
END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))

echo ""
log_banner " 🎉 Feed 自动化后处理全部成功完成！ (总耗时: ${ELAPSED}s) "
