<div align="center">

<img width="768" src="./doc/zerowrt.webp"/>

**High-performance OpenWrt 25.12 firmware for x86_64**

Open Source · Tailored Experience · High Performance

[![OpenWrt](https://img.shields.io/badge/OpenWrt-25.12-00B5E2?style=for-the-badge&logo=openwrt&logoColor=white)](https://openwrt.org)
[![Platform](https://img.shields.io/badge/Platform-x86__64-F59E0B?style=for-the-badge&logo=intel&logoColor=white)](#firmware-variants)
[![Kernel](https://img.shields.io/badge/Kernel-6.12-4F46E5?style=for-the-badge&logo=linux&logoColor=white)](#kernel--network-stack)
[![License](https://img.shields.io/badge/License-GPL--2.0-22C55E?style=for-the-badge)](./LICENSE)

[![Build Releases](https://img.shields.io/github/actions/workflow/status/MinimaxFlora/My-OpenWrt-Firmware/build-release.yml?branch=master&style=flat-square&label=Build)](https://github.com/MinimaxFlora/My-OpenWrt-Firmware/actions)
[![Latest Release](https://img.shields.io/github/v/release/MinimaxFlora/My-OpenWrt-Firmware?style=flat-square)](https://github.com/MinimaxFlora/My-OpenWrt-Firmware/releases/latest)
[![Downloads](https://img.shields.io/github/downloads/MinimaxFlora/My-OpenWrt-Firmware/total?style=flat-square)](https://github.com/MinimaxFlora/My-OpenWrt-Firmware/releases)
[![Stars](https://img.shields.io/github/stars/MinimaxFlora/My-OpenWrt-Firmware?style=flat-square)](https://github.com/MinimaxFlora/My-OpenWrt-Firmware/stargazers)

**English** | [简体中文](./README_ZH.md)

[Download](https://github.com/MinimaxFlora/My-OpenWrt-Firmware/releases/latest) · [Build](#build-from-source) · [Customize](#repository-layout) · [Issues](https://github.com/MinimaxFlora/My-OpenWrt-Firmware/issues)

</div>

---

> [!TIP]
> Pick the image that matches your machine: `*-efi.img.gz` for **UEFI**, `*-combined.img.gz` (no `efi`) for **legacy BIOS**. **SquashFS** is the recommended production filesystem; **EXT4** is easier to resize. Always verify `sha256sums.txt` before flashing. Read this document before first boot — it covers default login, image selection, and common pitfalls.

> [!IMPORTANT]
> This repository builds **x86_64 generic** firmware only (soft routers, mini PCs, NUCs, VMs). It is **not** an Amlogic / Rockchip TV-box image and cannot be written to eMMC on ARM boxes.

---

## Highlights

| | |
| :--- | :--- |
| **Upstream** | Official [OpenWrt](https://github.com/openwrt/openwrt) `openwrt-25.12` |
| **Target** | `x86/64` generic · kernel **6.12** · GCC **15** · LTO + mold |
| **Web UI** | LuCI on **Nginx** (HTTP/3 / QUIC) · **Argon** theme · Simplified Chinese |
| **Stack** | **BBRv3** · TCP Brutal · **LRNG** · eBPF / XDP / BTF · MPTCP · nft fullcone |
| **Apps** | Docker · Nikki / Mihomo · HomeProxy · MosDNS · Samba4 · qBittorrent · SQM |
| **CI** | GitHub Actions → tagged **ZeroWrt** releases with SHA256 |

---

## Default Access

| Item | Value |
| :--- | :--- |
| LAN IP | `192.168.1.1` |
| Username | `root` |
| Password | `password` |
| Hostname | `ZeroWrt` |
| Timezone | `Asia/Shanghai` (`CST-8`) |
| Web UI | `http://192.168.1.1` (Nginx · port 80) |
| SSH | `ssh root@192.168.1.1` |

> [!WARNING]
> Change the default password on first login. GRUB EFI is built with `mitigations=off` for throughput — that trades some CPU-side mitigations for performance. Do not expose LuCI or SSH to the public Internet.

---

## Firmware Variants

Release artifacts (gzip-compressed disk images):

| File | Filesystem | Firmware |
| :--- | :--- | :--- |
| `openwrt-x86-64-generic-squashfs-combined-efi.img.gz` | SquashFS | UEFI |
| `openwrt-x86-64-generic-squashfs-combined.img.gz` | SquashFS | Legacy BIOS |
| `openwrt-x86-64-generic-ext4-combined-efi.img.gz` | EXT4 | UEFI |
| `openwrt-x86-64-generic-ext4-combined.img.gz` | EXT4 | Legacy BIOS |
| `sha256sums.txt` | — | Checksums |

**Recommended:** `squashfs-combined-efi` on any UEFI mini PC / NUC.

Image layout from `.config`:

- Kernel partition: **32 MiB**
- Rootfs partition: **944 MiB**

---

## Flash

1. Download the matching image and `sha256sums.txt` from [Releases](https://github.com/MinimaxFlora/My-OpenWrt-Firmware/releases/latest).
2. Verify the checksum.
3. Write the decompressed `.img` with [balenaEtcher](https://etcher.balena.io/), `dd`, or `pv`.
4. Connect the LAN port, set the PC to DHCP (or `192.168.1.x/24`), open `http://192.168.1.1`.

```bash
# Linux: replace sdX with the target disk (this wipes the disk)
gunzip -k openwrt-x86-64-generic-squashfs-combined-efi.img.gz
sudo dd if=openwrt-x86-64-generic-squashfs-combined-efi.img of=/dev/sdX bs=4M status=progress conv=fsync
```

> [!CAUTION]
> `dd` / Etcher will erase the destination disk. Confirm the device node (`lsblk`) before writing. Snapshot any existing OpenWrt config first if you are replacing a running router.

---

## Feature Set

### Kernel & network stack

- Linux **6.12** with **BBRv3** congestion control and **TCP Brutal**
- **LRNG** (Linux Random Number Generator) in place of `urngd`
- eBPF events, cgroup BPF, BTF, XDP sockets
- MPTCP (IPv4 / IPv6)
- nftables **fullcone**, flow offload, socket, tproxy
- SQM / CAKE, packet steering, RPS, ethtool offloads via `autocore`
- Intel IGC i225 / i226 EEE disabled (stability patch)
- `vm.swappiness=5`, enlarged UDP buffers, BPF JIT on

### Web & system

- LuCI served by **Nginx** (Brotli / zstd / QUIC / stream / WebDAV)
- **Argon** theme (pink accent `#e879a8`) + Argon Config
- Status page: CPU, temperature, ports, live network speed
- LuCI patches: reboot confirm modal, real process RSS, dmesg ANSI colors, refresh interval, Docker root-dir mount, ZRAM
- Default shell: **bash** · NTP: Aliyun / Tencent
- APK feeds mirrored at [SJTU](https://mirror.sjtu.edu.cn/openwrt/)

### Hardware drivers

| Class | Modules |
| :--- | :--- |
| NIC | Intel i40e · Mellanox mlx4/mlx5 · Realtek r8101 / r8125-rss / r8126-rss / r8127-rss |
| Wi-Fi | mt76x2 · mt7921e/u · mt7922 · mt7925 |
| Storage | NVMe · USB 3 · exFAT / F2FS / NTFS3 / XFS / VFAT |
| Other | Intel i915 HuC · HDA Realtek · USB RNDIS / iPhone tethering |

### LuCI applications

<details>
<summary>Click to expand the application list</summary>

| Category | Packages |
| :--- | :--- |
| Proxy / DNS | `luci-app-nikki` · `luci-app-homeproxy` · `luci-app-mosdns` · `mihomo-meta` |
| Container / storage | `luci-app-dockerman` · `luci-app-diskman` · `luci-app-quickfile` · `luci-app-openlist2` |
| Sharing | `luci-app-samba4` · `luci-app-webdav` · `luci-app-qbittorrent` |
| Network | `luci-app-sqm` · `luci-app-upnp` · `luci-app-natmap` · `luci-app-frpc` · `luci-app-zerotier` · `luci-app-eqos` · `luci-app-oaf` · `luci-app-socat` · `luci-app-wol` |
| Media | `luci-app-airplay2` · `luci-app-airconnect` · `luci-app-rtp2httpd` |
| Ops | `luci-app-ota` · `luci-app-ttyd` · `luci-app-commands` · `luci-app-cpufreq` · `luci-app-ddns` · `luci-app-autoreboot` · `luci-app-watchcat` · `luci-app-ramfree` · `luci-app-nlbwmon` · `luci-app-netspeedtest` · `luci-app-mentohust` · `luci-app-vlmcsd` · `luci-app-argon-config` |

</details>

---

## Build from Source

GitHub Actions compiles on `ubuntu-24.04` (public workflow) or a self-hosted runner (private workflow). Manual trigger: **Actions → Build Releases → Run workflow**.

Local outline (same stages as CI):

```bash
git clone --depth=1 -b openwrt-25.12 https://github.com/openwrt/openwrt.git
cd openwrt

# 1. Extra feeds (before ./scripts/feeds update)
cp /path/to/My-OpenWrt-Firmware/diy-part1.sh ./
./diy-part1.sh

./scripts/feeds update -a
./scripts/feeds install -a

# 2. Replace conflicting packages, clone extras, apply LuCI / FRPC / NATMAP patches
cp /path/to/My-OpenWrt-Firmware/diy-part2.sh ./
./diy-part2.sh

# 3. Kernel patches
cp patches/IGC/*.patch  target/linux/x86/patches-6.12/
cp patches/BBRv3/*      target/linux/generic/backport-6.12/
cp patches/LRNG/*       target/linux/generic/hack-6.12/

# 4. Config + rootfs overlay
cp /path/to/My-OpenWrt-Firmware/.config ./
cp -a /path/to/My-OpenWrt-Firmware/files ./
make defconfig

make download -j$(nproc)
make -j$(nproc)
```

After a successful build, `diy-part3.sh` writes the kmod index directory and `fw.json` for OTA.

> [!NOTE]
> A full x86_64 image with Docker, LLVM/Clang, and all kmods needs a large disk and several hours. Prefer GitHub Actions unless you already have an OpenWrt build host.

---

## Repository Layout

```text
My-OpenWrt-Firmware/
├── .config                          # x86_64 defconfig (kernel, LuCI, kmods)
├── diy-part1.sh                     # Extra feeds, runs before feeds update
├── diy-part2.sh                     # Post-feeds: packages, tuning, patches, i18n
├── diy-part3.sh                     # Post-build: kmod layout + OTA fw.json
├── files/                           # Rootfs overlay copied into the image
│   ├── etc/uci-defaults/            # First-boot: hostname, Nginx, Argon, Docker mirror
│   ├── etc/sysctl.d/                # TCP / swappiness / UDP buffer tuning
│   ├── etc/nikki/profiles/          # Default Mihomo profile
│   ├── usr/bin/ota-upgrade          # OTA helper
│   └── www/luci-static/             # Status widgets + Argon wallpaper
├── patches/
│   ├── BBRv3/                       # TCP BBR v3 backports (kernel 6.12)
│   ├── LRNG/                        # Linux Random Number Generator
│   ├── IGC/                         # Intel i225/i226 disable EEE
│   ├── LUCI/                        # Status / system UI patches
│   ├── FRPC/  NATMAP/  GENERIC/
│   └── README.md
├── doc/zerowrt.webp                 # README banner
├── scripts/                         # kmod signing helpers
├── LICENSE                          # GPL-2.0
└── .github/
    ├── workflows/                   # build-release.yml · private runner
    ├── ISSUE_TEMPLATE/              # bug / feature forms
    ├── PULL_REQUEST_TEMPLATE.md
    ├── dependabot.yml
    └── CODEOWNERS
```

Customize by editing `.config`, dropping files under `files/`, or adding patches under `patches/` (see `patches/README.md`).

---

## First-Boot Defaults

Applied by `files/etc/uci-defaults/`:

- Hostname `ZeroWrt`, timezone `Asia/Shanghai`
- Nginx LAN server on `:80` (uhttpd is not used)
- Argon: light mode, pink primary, local wallpaper
- Docker registry mirror `https://docker.m.daocloud.io`
- LuCI diagnostics against `www.qq.com`
- Extra kmod index: `https://core.kejizero.xyz/25.12/...`

---

## License

[GPL-2.0](./LICENSE) — same family as OpenWrt. Third-party packages keep their own licenses.

---

## Disclaimer

This is an unofficial OpenWrt derivative for personal / lab use. You are responsible for flashing, configuration, and compliance with local law. The maintainers provide **no warranty**. Opening an [Issue](https://github.com/MinimaxFlora/My-OpenWrt-Firmware/issues) is welcome when you can include device model, image filename, and logs.

---

## Credits

- [OpenWrt](https://github.com/openwrt/openwrt)
- [sbwml](https://github.com/sbwml) — golang / rust / node feeds, MosDNS, Docker, Nginx, helloworld, and many LuCI apps
- [jerrykuku](https://github.com/jerrykuku/luci-theme-argon) — luci-theme-argon
- Linux kernel BBR and LRNG authors

---

<div align="center">

[Release](https://github.com/MinimaxFlora/My-OpenWrt-Firmware/releases/latest) · [Actions](https://github.com/MinimaxFlora/My-OpenWrt-Firmware/actions) · [中文文档](./README_ZH.md)

</div>
