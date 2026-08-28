# arch/sunxi/cortexa53

TinyNAS 锦盒在 **Allwinner ARM9/A7/A8/A53 SBC**（sunxi-cortexa53）架构下的打包配置。

## 基本信息

| 项 | 值 |
|---|---|
| OpenWrt 版本 | 25.12.5 |
| target 路径 | `sunxi-cortexa53` |
| 默认 PROFILE | `generic` |
| Image Builder | [下载链接](https://downloads.openwrt.org/releases/25.12.5/targets/sunxi-cortexa53/openwrt-imagebuilder-25.12.5-sunxi-cortexa53.Linux-x86_64.tar.xz) |
| 架构族 | sunxi |

## 典型硬件

Allwinner ARM9/A7/A8/A53 SBC。

## 刷机

请先通过 OpenWrt 官网确认你的设备是否在 [Table of Hardware](https://openwrt.org/toh/start) 支持列表内：

- ✅ OpenWrt 支持 → 使用本分支打包的固件，按官方 wiki 刷机
- ❌ OpenWrt 不支持 → 检查设备是否在本仓其他分支或 [tinynas-labs/amlogic-s9xxx-openwrt](https://github.com/tinynas-labs/amlogic-s9xxx-openwrt) 的支持范围

## 已知限制

⚠️ **本仓库刚完成 25.12.5 全架构分支骨架填充**，实际打包验证待：
1. Image Builder tarball 下载链路通畅
2. 产物在真机/虚拟机上能正常启动
3. `tinynas-files/` 覆盖层实际内容就绪后做端到端测试

如发现本架构的 `packages.txt` 需要 SOC 专属驱动，欢迎提 PR。

## 相关链接

- Image Builder: https://downloads.openwrt.org/releases/25.12.5/targets/sunxi-cortexa53/openwrt-imagebuilder-25.12.5-sunxi-cortexa53.Linux-x86_64.tar.xz
- 通用打包模板: `common/build-template.sh`
- 通用包列表: `common/packages.common.txt`
- 覆盖层: `common/tinynas-files/`
