# `patches/` — 可选源码补丁层

本目录用于存放适用于 **OpenWrt (x86_64)** 源码树的自定义补丁。

## 目录说明

构建时会自动按文件名顺序对 OpenWrt 源码树执行 `patch -p1`。本仓库/源码树主要包含以下类别的定制补丁：
* **BBR3**：内核拥塞控制算法支持
* **LRNG**：Linux 随机数生成器升级
* **LuCI**：界面优化与相关组件调整

放到本目录的 `.patch` 文件即会随构建自动生效；当内核或上游源码升级导致补丁失效时，只需修正对应的 `.patch` 文件即可。

---

## 生成补丁的常用方式

如果在 OpenWrt 源码树中进行了修改并希望导出为补丁，可在源码根目录下按以下方式操作：

```bash
# 在 OpenWrt 源码目录中进行修改后（例如 target/linux/x86/ 或 package/ 等目录）
git diff > patches/001-x86-custom-features.patch
