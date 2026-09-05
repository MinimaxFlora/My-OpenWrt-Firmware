<div align="center">

# ZeroWrt

**面向 x86_64 的高性能 OpenWrt 25.12 固件**

开源定制 · 开箱即用 · 内核级网络优化

[![OpenWrt](https://img.shields.io/badge/OpenWrt-25.12-00B5E2?style=for-the-badge&logo=openwrt&logoColor=white)](https://openwrt.org)
[![Platform](https://img.shields.io/badge/Platform-x86__64-F59E0B?style=for-the-badge&logo=intel&logoColor=white)](#固件版本)
[![Kernel](https://img.shields.io/badge/Kernel-6.12-4F46E5?style=for-the-badge&logo=linux&logoColor=white)](#内核与网络栈)
[![License](https://img.shields.io/badge/License-GPL--2.0-22C55E?style=for-the-badge)](./LICENSE)

[![Build Releases](https://img.shields.io/github/actions/workflow/status/MinimaxFlora/My-OpenWrt-Firmware/build-release.yml?branch=master&style=flat-square&label=Build)](https://github.com/MinimaxFlora/My-OpenWrt-Firmware/actions)
[![Latest Release](https://img.shields.io/github/v/release/MinimaxFlora/My-OpenWrt-Firmware?style=flat-square)](https://github.com/MinimaxFlora/My-OpenWrt-Firmware/releases/latest)
[![Downloads](https://img.shields.io/github/downloads/MinimaxFlora/My-OpenWrt-Firmware/total?style=flat-square)](https://github.com/MinimaxFlora/My-OpenWrt-Firmware/releases)
[![Stars](https://img.shields.io/github/stars/MinimaxFlora/My-OpenWrt-Firmware?style=flat-square)](https://github.com/MinimaxFlora/My-OpenWrt-Firmware/stargazers)

[English](./README.md) | **简体中文**

[下载固件](https://github.com/MinimaxFlora/My-OpenWrt-Firmware/releases/latest) · [自行编译](#自行编译) · [目录说明](#仓库结构) · [反馈问题](https://github.com/MinimaxFlora/My-OpenWrt-Firmware/issues)

</div>

---

> [!TIP]
> 按机器选择镜像：带 `efi` 的文件用于 **UEFI**，不带 `efi` 的 `*-combined.img.gz` 用于 **传统 BIOS**。生产环境优先 **SquashFS**；需要直接扩容根分区时用 **EXT4**。刷写前核对 `sha256sums.txt`。首次使用请先读完本文，默认登录信息、镜像对照和常见注意点都写在下面。

> [!IMPORTANT]
> 本仓库只构建 **x86_64 generic** 固件（软路由、迷你主机、NUC、虚拟机）。这不是晶晨 / 瑞芯微电视盒子镜像，不能写入 ARM 盒子的 eMMC。

---

## 特性一览

| | |
| :--- | :--- |
| **上游** | 官方 [OpenWrt](https://github.com/openwrt/openwrt) 分支 `openwrt-25.12` |
| **平台** | `x86/64` generic · 内核 **6.12** · GCC **15** · LTO + mold |
| **界面** | LuCI 跑在 **Nginx**（HTTP/3 / QUIC）· **Argon** 主题 · 简体中文 |
| **协议栈** | **BBRv3** · TCP Brutal · **LRNG** · eBPF / XDP / BTF · MPTCP · nft fullcone |
| **应用** | Docker · Nikki / Mihomo · HomeProxy · MosDNS · Samba4 · qBittorrent · SQM |
| **CI** | GitHub Actions 自动编译，发布带 SHA256 的 **ZeroWrt** Release |

---

## 默认登录

| 项目 | 值 |
| :--- | :--- |
| 管理地址 | `192.168.1.1` |
| 用户名 | `root` |
| 密码 | `password` |
| 主机名 | `ZeroWrt` |
| 时区 | `Asia/Shanghai`（`CST-8`） |
| Web 界面 | `http://192.168.1.1`（Nginx · 80 端口） |
| SSH | `ssh root@192.168.1.1` |

> [!WARNING]
> 第一次登录后立刻改密码。GRUB EFI 启用了 `mitigations=off` 以换取转发性能，会关闭部分 CPU 侧缓解。不要把 LuCI 或 SSH 直接暴露到公网。

---

## 固件版本

Release 产物（gzip 压缩的磁盘镜像）：

| 文件 | 文件系统 | 固件类型 |
| :--- | :--- | :--- |
| `openwrt-x86-64-generic-squashfs-combined-efi.img.gz` | SquashFS | UEFI |
| `openwrt-x86-64-generic-squashfs-combined.img.gz` | SquashFS | 传统 BIOS |
| `openwrt-x86-64-generic-ext4-combined-efi.img.gz` | EXT4 | UEFI |
| `openwrt-x86-64-generic-ext4-combined.img.gz` | EXT4 | 传统 BIOS |
| `sha256sums.txt` | — | 校验和 |

**推荐：** 现代迷你主机 / NUC 使用 `squashfs-combined-efi`。

分区来自 `.config`：

- 内核分区：**32 MiB**
- 根分区：**944 MiB**

---

## 刷写

1. 从 [Releases](https://github.com/MinimaxFlora/My-OpenWrt-Firmware/releases/latest) 下载对应镜像和 `sha256sums.txt`。
2. 校验 SHA256。
3. 解压后用 [balenaEtcher](https://etcher.balena.io/)、`dd` 或 `pv` 写入磁盘。
4. 网线接 LAN，电脑 DHCP（或 `192.168.1.x/24`），浏览器打开 `http://192.168.1.1`。

```bash
# Linux：把 sdX 换成目标磁盘（会清空该盘）
gunzip -k openwrt-x86-64-generic-squashfs-combined-efi.img.gz
sudo dd if=openwrt-x86-64-generic-squashfs-combined-efi.img of=/dev/sdX bs=4M status=progress conv=fsync
```

> [!CAUTION]
> `dd` / Etcher 会擦除目标盘。写入前用 `lsblk` 确认设备名。替换正在运行的路由前，先备份配置。

---

## 功能清单

### 内核与网络栈

- Linux **6.12**，集成 **BBRv3** 与 **TCP Brutal**
- 使用 **LRNG** 替代 `urngd`
- eBPF events、cgroup BPF、BTF、XDP sockets
- MPTCP（IPv4 / IPv6）
- nftables **fullcone**、flow offload、socket、tproxy
- SQM / CAKE；`autocore` 开启 packet steering、RPS、网卡卸载
- Intel IGC i225 / i226 关闭 EEE（稳定性补丁）
- `vm.swappiness=5`、加大 UDP 缓冲、开启 BPF JIT

### 界面与系统

- LuCI 由 **Nginx** 提供（Brotli / zstd / QUIC / stream / WebDAV）
- **Argon** 主题（粉色主色 `#e879a8`）+ Argon Config
- 状态页：CPU、温度、网口、实时速率
- LuCI 补丁：重启确认框、真实进程内存、dmesg 彩色、刷新间隔、Docker 根目录挂载、ZRAM
- 默认 shell：**bash** · NTP：阿里云 / 腾讯云
- APK 软件源使用 [交大镜像](https://mirror.sjtu.edu.cn/openwrt/)

### 硬件驱动

| 类别 | 模块 |
| :--- | :--- |
| 有线网卡 | Intel i40e · Mellanox mlx4/mlx5 · Realtek r8101 / r8125-rss / r8126-rss / r8127-rss |
| 无线 | mt76x2 · mt7921e/u · mt7922 · mt7925 |
| 存储 | NVMe · USB 3 · exFAT / F2FS / NTFS3 / XFS / VFAT |
| 其他 | Intel i915 HuC · HDA Realtek · USB RNDIS / iPhone 网络共享 |

### LuCI 应用

<details>
<summary>展开应用列表</summary>

| 分类 | 软件包 |
| :--- | :--- |
| 代理 / DNS | `luci-app-nikki` · `luci-app-homeproxy` · `luci-app-mosdns` · `mihomo-meta` |
| 容器 / 存储 | `luci-app-dockerman` · `luci-app-diskman` · `luci-app-quickfile` · `luci-app-openlist2` |
| 共享 | `luci-app-samba4` · `luci-app-webdav` · `luci-app-qbittorrent` |
| 网络 | `luci-app-sqm` · `luci-app-upnp` · `luci-app-natmap` · `luci-app-frpc` · `luci-app-zerotier` · `luci-app-eqos` · `luci-app-oaf` · `luci-app-socat` · `luci-app-wol` |
| 媒体 | `luci-app-airplay2` · `luci-app-airconnect` · `luci-app-rtp2httpd` |
| 运维 | `luci-app-ota` · `luci-app-ttyd` · `luci-app-commands` · `luci-app-cpufreq` · `luci-app-ddns` · `luci-app-autoreboot` · `luci-app-watchcat` · `luci-app-ramfree` · `luci-app-nlbwmon` · `luci-app-netspeedtest` · `luci-app-mentohust` · `luci-app-vlmcsd` · `luci-app-argon-config` |

</details>

---

## 自行编译

GitHub Actions 在 `ubuntu-24.04`（公开工作流）或自托管 Runner（私有工作流）上编译。手动触发：**Actions → Build Releases → Run workflow**。

本地流程与 CI 一致：

```bash
git clone --depth=1 -b openwrt-25.12 https://github.com/openwrt/openwrt.git
cd openwrt

# 1. 额外 feeds（在 ./scripts/feeds update 之前）
cp /path/to/My-OpenWrt-Firmware/diy-part1.sh ./
./diy-part1.sh

./scripts/feeds update -a
./scripts/feeds install -a

# 2. 清理冲突包、拉取第三方组件、打 LuCI / FRPC / NATMAP 补丁
cp /path/to/My-OpenWrt-Firmware/diy-part2.sh ./
./diy-part2.sh

# 3. 内核补丁
cp patches/IGC/*.patch  target/linux/x86/patches-6.12/
cp patches/BBRv3/*      target/linux/generic/backport-6.12/
cp patches/LRNG/*       target/linux/generic/hack-6.12/

# 4. 配置与 files 覆盖层
cp /path/to/My-OpenWrt-Firmware/.config ./
cp -a /path/to/My-OpenWrt-Firmware/files ./
make defconfig

make download -j$(nproc)
make -j$(nproc)
```

编译成功后，`diy-part3.sh` 会整理 kmod 目录并生成 OTA 用的 `fw.json`。

> [!NOTE]
> 完整 x86_64 镜像含 Docker、LLVM/Clang 和全套 kmod，磁盘占用大、耗时数小时。没有现成编译机时，优先用 GitHub Actions。

---

## 仓库结构

```text
My-OpenWrt-Firmware/
├── .config                          # x86_64 配置（内核、LuCI、kmod）
├── diy-part1.sh                     # feeds 更新前：追加软件源
├── diy-part2.sh                     # feeds 更新后：软件包、调优、补丁、汉化
├── diy-part3.sh                     # 编译后：kmod 目录 + OTA fw.json
├── files/                           # 写入镜像的根文件系统覆盖层
│   ├── etc/uci-defaults/            # 首次启动：主机名、Nginx、Argon、Docker 镜像
│   ├── etc/sysctl.d/                # TCP / swappiness / UDP 缓冲
│   ├── etc/nikki/profiles/          # 默认 Mihomo 配置
│   ├── usr/bin/ota-upgrade          # OTA 脚本
│   └── www/luci-static/             # 状态页组件 + Argon 壁纸
├── patches/
│   ├── BBRv3/                       # TCP BBR v3（内核 6.12）
│   ├── LRNG/                        # Linux 随机数发生器
│   ├── IGC/                         # Intel i225/i226 关闭 EEE
│   ├── LUCI/                        # 状态页 / 系统设置补丁
│   ├── FRPC/  NATMAP/  GENERIC/
│   └── README.md
├── scripts/                         # kmod 签名辅助
├── LICENSE                          # GPL-2.0
└── .github/
    ├── workflows/                   # build-release.yml · 自托管 Runner
    ├── ISSUE_TEMPLATE/              # bug / 功能表单
    ├── PULL_REQUEST_TEMPLATE.md
    ├── dependabot.yml
    └── CODEOWNERS
```

改 `.config`、往 `files/` 丢文件、或在 `patches/` 加补丁即可定制（见 `patches/README.md`）。

---

## 首次启动默认值

由 `files/etc/uci-defaults/` 写入：

- 主机名 `ZeroWrt`，时区 `Asia/Shanghai`
- Nginx 监听 LAN `:80`（不使用 uhttpd）
- Argon：浅色、粉色主色、本地壁纸
- Docker 镜像 `https://docker.m.daocloud.io`
- LuCI 网络诊断目标 `www.qq.com`
- 额外 kmod 源：`https://core.kejizero.xyz/25.12/...`

---

## 许可证

[GPL-2.0](./LICENSE)，与 OpenWrt 同属 GPL-2.0 体系。第三方软件包保留各自许可证。

---

## 免责声明

本项目是非官方 OpenWrt 衍生固件，仅供个人与实验使用。刷写、配置及合法合规由使用者自行负责，维护者不提供任何担保。提 [Issue](https://github.com/MinimaxFlora/My-OpenWrt-Firmware/issues) 时请附设备型号、镜像文件名和日志。

---

## 致谢

- [OpenWrt](https://github.com/openwrt/openwrt)
- [sbwml](https://github.com/sbwml) — golang / rust / node feeds、MosDNS、Docker、Nginx、helloworld 及大量 LuCI 应用
- [jerrykuku](https://github.com/jerrykuku/luci-theme-argon) — luci-theme-argon
- Linux 内核 BBR 与 LRNG 作者

---

<div align="center">

[下载 Release](https://github.com/MinimaxFlora/My-OpenWrt-Firmware/releases/latest) · [Actions](https://github.com/MinimaxFlora/My-OpenWrt-Firmware/actions) · [English](./README.md)

</div>
