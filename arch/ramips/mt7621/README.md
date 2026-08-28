# arch/ramips/mt7621

锦盒 TinyNAS 在 **MediaTek MT7621** 架构下的打包配置 —— 小米/红米路由器刷 Lite 档的主力分支。

## 支持机型（已对照 OpenWrt 25.12.5 官方设备定义核实）

| 机型 | 背面标签 | RAM / Flash | USB | 建议档位 | PROFILE |
|------|---------|-------------|-----|---------|---------|
| 小米路由器 4A 千兆版 v1 | R4A Gigabit | 128MB / 128MB | 无 | Lite | `xiaomi_mi-router-4a-gigabit` |
| 小米路由器 4A 千兆版 v2 | R4A v2 | 128MB / 128MB | 无 | Lite | `xiaomi_mi-router-4a-gigabit-v2` |
| 小米路由器 3G | R3G | 256MB / 128MB | **USB3** | Edge/Lite | `xiaomi_mi-router-3g` |
| 小米路由器 3G v2 | R3G v2 | 256MB / 128MB | USB3 | Edge/Lite | `xiaomi_mi-router-3g-v2` |
| 小米路由器 3 Pro | R3P | 256MB / 256MB | USB3 | Edge/Lite | `xiaomi_mi-router-3-pro` |
| 小米路由器 AC2100 | R2100 | 128MB / 128MB | 无 | Lite | `xiaomi_mi-router-ac2100` |
| 红米路由器 AC2100 | — | 128MB / 128MB | 无 | Lite | `xiaomi_redmi-router-ac2100` |

> **⛔ 不支持机型警示**（未进入 OpenWrt 官方 25.12.5 设备树，本管线无法覆盖）：
> **小米路由器 3（R3）**、**小米路由器 HD（R3D，内置 1TB 硬盘）**、3C/3A/3L。
> 这些机型只能走 Breed + 社区固件路线，且无稳定维护。买之前认准上表型号；
> 尤其"3 代带硬盘"大概率是 HD（R3D）——它**刷不了**本固件，请勿入手。

## 基本信息

| 项 | 值 |
|---|---|
| OpenWrt 版本 | 25.12.5 |
| target 路径 | `ramips/mt7621` |
| 默认 PROFILE | `generic`（推荐按机型指定） |
| 默认档位 | `lite` |
| Image Builder | [下载链接](https://downloads.openwrt.org/releases/25.12.5/targets/ramips/mt7621/openwrt-imagebuilder-25.12.5-ramips-mt7621.Linux-x86_64.tar.zst) |
| 架构族 | ramips |

## 打包用法

```bash
# 默认：generic profile + Lite 档
./build.sh

# 指定机型（产物自动带 factory/sysupgrade 两类 .bin）
./build.sh stable 1.0.0 xiaomi_mi-router-4a-gigabit lite
./build.sh stable 1.0.0 xiaomi_mi-router-3g edge        # 3G 有 USB3 + 256MB，可上 Edge

# 产物命名
output/openwrt_tinynas-lite-ramips-mt7621_v1.0.0-stable_YYYY.MM.DD-sysupgrade.bin
output/openwrt_tinynas-lite-ramips-mt7621_v1.0.0-stable_YYYY.MM.DD-factory.bin
```

- WiFi 驱动（mt7603/mt76x2/mt7615 等）由各 PROFILE 的 DEVICE_PACKAGES 自动带入，无需手配
- `sysupgrade.bin`：给已刷 OpenWrt 的设备在线升级用
- `factory.bin`：给 Breed 引导导入用

## 刷机 SOP

### 前置：为什么不能直接网页升级

小米原厂固件对升级包做签名校验，OpenWrt 的 factory.bin 直接在原厂 Web 后台升级会被拒。标准路径只有两条：

- **路线 A（exploit）**：4A 千兆 v1、AC2100 系列可用 [OpenWRTInvasion](https://github.com/acecilia/OpenWRTInvasion) 拿到 SSH → 直接刷 sysupgrade.bin
- **路线 B（Breed 引导）**：所有机型通用，先刷不死 Breed，再从 Breed 网页刷 OpenWrt——**最稳妥，推荐**

### 通用流程（路线 B · Breed）

1. **备份**：刷入 Breed 后第一件事在 Breed 网页里**完整备份编程器固件**（含原厂分区，救砖+回原厂全靠它）
2. 按机型下载对应 Breed（搜索"机型 + breed 不死引导"，如 `r3g breed`、`r4ag breed`），通过 exploit/临时 root 写入
3. 断电，按住 reset 上电 → 电脑网卡设为 `192.168.1.2/24` → 浏览器进 `192.168.1.1`（Breed 界面）
4. 「固件更新」→ 选 `openwrt_tinynas-*-factory.bin` → Flash → 完成后拔电重启
5. 设备起 OpenWrt 后 LAN 口 `192.168.1.1` 进锦盒向导

### 各机型差异

| 机型 | 入侵/Breed 工具 | 注意事项 |
|------|----------------|---------|
| 4A 千兆 v1 | OpenWRTInvasion 直刷 | 原厂 SSH 直接可用 |
| 4A 千兆 v2 | 需专用 R4Av2 Breed | flash 布局与 v1 不同，**不可混刷** |
| 3G / 3G v2 | Breed | 3G v2 同样有专属布局，认准型号 |
| 3 Pro | Breed | 256MB flash，可放心装 Lite 全家桶 |
| AC2100（小米/红米） | OpenWRTInvasion | v1/v2 需认准型号 |

> ⚠️ 刷机有变砖风险；动手前确认型号与 Breed 一一对应，并做好第 1 步的备份。

## Lite 档说明（本分支默认档位）

Lite = Samba + MiniDLNA + uhttpd 静态仪表盘 + aria2 + curl/jq，**不含 ZeroClaw（AI）**。
128MB RAM 机型注意：MiniDLNA 媒体库建议控制在几千文件内；256MB 机型（3G/3 Pro）体验更从容。
存储经 USB 口外接（3G/3 Pro 为 USB3，其余 USB2 仅适合轻量下载盘）。

## 已验证机型

| 机型 | 状态 |
|------|------|
| 小米路由器 4A 千兆版 | 🧪 待验证 |
| 小米路由器 3G | 🧪 待验证 |
| 小米路由器 3 Pro | 🧪 待验证 |
| 红米 AC2100 | 🧪 待验证 |

## 相关链接

- 通用打包模板: `common/build-template.sh`
- 通用包列表: `common/packages.common.txt`
- 档位包列表: `common/packages.tier-{pro,edge,lite}.txt`
- 覆盖层: `common/tinynas-files/`
- 设备查询: [OpenWrt Table of Hardware](https://openwrt.org/toh/start)
