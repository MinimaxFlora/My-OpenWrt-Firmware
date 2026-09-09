# 更新日志 (Changelog)

本仓库（构建流水线 / 配置 / 文档）的变更记录。固件本体的 OTA 更新说明见各
[ZeroWrt_* Release](https://github.com/MinimaxFlora/My-OpenWrt-Firmware/releases) 的发布说明。

格式参考 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.1.0/)。

## [2026-09-09]

### 新增

- **工具链缓存流水线**（参考 [sbwml/r4s_build_script](https://github.com/sbwml/r4s_build_script)）：
  - 新工作流 `Build Toolchain Cache`：手动触发编译 host tools + 交叉工具链，将
    `build_dir/ dl/ staging_dir/ tmp/` 打包为 `toolchain_musl_x86_64_gcc-15.tar.zst`
    （zstd -19）并上传到滚动 Release Tag **`Toolchain_Cache`**；
  - `build-release.yml` 在编译前自动从 `Toolchain_Cache` Release 下载并解压工具链缓存，
    上游源码更新不再触发工具链整链重编；缓存缺失时自动回退为全量编译。
- 仓库更新日志 `CHANGELOG.md`。

### 变更

- `build-release.yml`：移除 `HiGarfield/cachewrtbuild` 缓存，改用 Release 版工具链缓存；
  编译依赖补充 `zstd`（`tar -I zstd` 需要）。
- `delete-older-releases-workflows.yml`：清理旧 Release 时默认保留 `Toolchain_Cache`
  （`releases_keep_keyword` 增加关键词）。
- README / README_ZH 同步说明工具链缓存的用法与仓库结构。

## [2026-09-07]

### 新增

- UPX 压缩支持（编译工具链 + 根文件系统，见 `patches/UPX/`）。
- UCI 配置文件读写权限补丁（`patches/UCI/`）。
- `Delete older releases and workflows` 清理工作流（手动 / 仓库事件触发）。

### 变更

- 固件产物与 Release 命名统一为 ZeroWrt；默认仅保留 1 个历史 Release。

## [2026-09-06]

### 新增

- SQM / CAKE 支持（自维护 sqm-scripts 的 Makefile，见 `patches/SQM/`）。
- 构建工作流增强：系统诊断输出、Release Tag / OTA 时间戳 / 更新日志变量注入、
  OTA URL 代理支持。

### 变更

- kmod 签名包与 `ota.json` 随固件 Release 发布（kmod 滚动 Tag `kmod-openwrt-25.12`）。

## [2026-09-05]

### 新增

- 双语 README（`README.md` / `README_ZH.md`）、GPL-2.0 LICENSE 与 GitHub 社区文件
  （Issue 模板、PR 模板、CODEOWNERS、dependabot）。
- ZeroWrt-Tools 固件管理工具箱（`/usr/bin/ZeroWrt`）。
- Argon 主题与首次启动默认值定制（`files/etc/uci-defaults/`）。

### 变更

- 工作流与 Release 命名从 EternalWrt 迁移到 ZeroWrt。
- 上传 / 下载 artifact 的 action 升级（upload-artifact v4→v7、download-artifact v5→v8）。

## [2026-09-04]

### 新增

- x86_64 构建工作流重构：磁盘 LVM 扩容、多线程编译、编译产物整理与 Release 发布流程。
- Intel IGC i225 / i226 关闭 EEE 补丁（`patches/IGC/`）。
- `luci-app-sqm`、`luci-app-ota` 加入固件配置。

## [2026-09-03] — 初始版本

### 新增

- 基于 OpenWrt `openwrt-25.12` 的 x86_64 固件构建仓库（内核 6.12、GCC 15、musl）：
  - `diy-part1/2/3.sh` 构建流水线（额外 feeds、冲突包替换 / 补丁、kmod 与 OTA 整理）；
  - `.config`：LuCI 全家桶、Docker、科学插件（Nikki / HomeProxy / MosDNS）、
    Samba4 / qBittorrent 等；
  - `files/` 根文件系统覆盖层（Nginx + LuCI、Argon 主题、Mihomo 默认配置、sysctl 调优）；
  - 补丁族：BBRv3 / LRNG / UCI / LUCI / FRPC / NATMAP / MESON / UPX / GENERIC；
  - kmod APK 签名脚本（`scripts/kmod-sign`）。
