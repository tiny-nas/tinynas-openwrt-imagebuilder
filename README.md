# 锦盒 TinyNAS · OpenWrt Image Builder 集成层

[锦盒 TinyNAS](https://github.com/tinynas-labs) 是面向斐讯 N1 / 迷你主机 / 家用路由器的"轻量 NAS + AI 助理"家庭算力网关系统。本仓库是 TinyNAS 在 **OpenWrt 官方 Image Builder** 上的多架构集成层。

> 项目代号：**`TinyNAS`**（中文：**锦盒**）—— Tiny 一眼传递硬件小巧，NAS 一眼传递品类。
> 主标语：**锦盒 TinyNAS —— 斐讯 N1 变身家庭 AI 私有云**
> 文档详见 [`tinynas-labs/amlogic-s9xxx-openwrt`](https://github.com/tinynas-labs/amlogic-s9xxx-openwrt) 与 [品牌主页](https://github.com/tinynas-labs)。

---

## 支持的架构（OpenWrt 25.12.5，共 92 个分支）

> 基于 [OpenWrt 25.12.5 官方 targets 目录](https://downloads.openwrt.org/releases/25.12.5/targets/) 全量覆盖

### Amlogic 设备

> ⚠️ 斐讯 N1 / 小米盒子3 等 Amlogic S9xxx 系列不在本仓库（它们使用 ophub 打包工具链），请使用 [`tinynas-labs/amlogic-s9xxx-openwrt`](https://github.com/tinynas-labs/amlogic-s9xxx-openwrt)。

### 通用 ARM / ARMv8 主机

| 分支 | 适用 | OpenWrt target |
|------|------|----------------|
| `arch/armvirt-64` | 通用 ARMv8 主机（非 Amlogic） | `armvirt/64` |
| `arch/armsr/armv7` | ARMv7 软路由 | `armsr/armv7` |
| `arch/armsr/armv8` | ARMv8 软路由 | `armsr/armv8` |
| `arch/rockchip-armv8` | 瑞芯微 RK3328/RK3399/RK3568 等 ARMv8 SBC | `rockchip/armv8` |

### 树莓派（bcm27xx）

| 分支 | 适用 | OpenWrt target |
|------|------|----------------|
| `arch/bcm27xx/bcm2708` | 树莓派 1 | `bcm27xx/bcm2708` |
| `arch/bcm27xx/bcm2709` | 树莓派 2 | `bcm27xx/bcm2709` |
| `arch/bcm27xx/bcm2710` | 树莓派 3 | `bcm27xx/bcm2710` |
| `arch/bcm27xx/bcm2711` | 树莓派 4 | `bcm27xx/bcm2711` |
| `arch/bcm27xx/bcm2712` | 树莓派 5 | `bcm27xx/bcm2712` |

### Qualcomm 高通路由器

| 分支 | 适用 | OpenWrt target |
|------|------|----------------|
| `arch/ipq40xx/chromium` | IPQ40xx Chromium 路由器 | `ipq40xx/chromium` |
| `arch/ipq40xx-generic` | IPQ40xx 通用 | `ipq40xx/generic` |
| `arch/ipq40xx/mikrotik` | MikroTik IPQ40xx | `ipq40xx/mikrotik` |
| `arch/ipq806x/chromium` | IPQ806x Chromium | `ipq806x/chromium` |
| `arch/ipq806x-generic` | IPQ806x 通用 | `ipq806x/generic` |
| `arch/qualcommax-ipq50xx` | IPQ50xx | `qualcommax/ipq50xx` |
| `arch/qualcommax-ipq60xx` | IPQ60xx | `qualcommax/ipq60xx` |
| `arch/qualcommax-ipq807x` | IPQ807x 高端路由器 | `qualcommax/ipq807x` |

### MediaTek 路由器

| 分支 | 适用 | OpenWrt target |
|------|------|----------------|
| `arch/mediatek/filogic` | MediaTek Filogic 系列 | `mediatek/filogic` |
| `arch/mediatek/mt7622` | MT7622 | `mediatek/mt7622` |
| `arch/mediatek/mt7623` | MT7623 | `mediatek/mt7623` |
| `arch/mediatek/mt7629` | MT7629 | `mediatek/mt7629` |
| `arch/ramips/mt7620` | MT7620 路由器 | `ramips/mt7620` |
| `arch/ramips/mt7621` | MT7621 路由器（小米路由器 4A、红米 AC2100 等） | `ramips/mt7621` |
| `arch/ramips/mt76x8` | MT76x8 | `ramips/mt76x8` |
| `arch/ramips/rt305x` | RT305x | `ramips/rt305x` |
| `arch/ramips/rt3883` | RT3883 | `ramips/rt3883` |

### Atheros 路由器

| 分支 | 适用 | OpenWrt target |
|------|------|----------------|
| `arch/ath79-generic` | Atheros ath79 通用 | `ath79/generic` |
| `arch/ath79/mikrotik` | MikroTik ath79 | `ath79/mikrotik` |
| `arch/ath79/nand` | ath79 NAND 设备 | `ath79/nand` |
| `arch/ath79/tiny` | ath79 小型设备 | `ath79/tiny` |

### x86 / x86_64

| 分支 | 适用 | OpenWrt target |
|------|------|----------------|
| `arch/x86_64` | 迷你主机 / 工控机 / KVM 虚拟机 | `x86/64` |

### Broadcom

| 分支 | 适用 | OpenWrt target |
|------|------|----------------|
| `arch/bcm47xx-generic` | BCM47xx 通用 | `bcm47xx/generic` |
| `arch/bcm47xx-legacy` | BCM47xx 旧设备 | `bcm47xx/legacy` |
| `arch/bcm47xx-mips74k` | BCM47xx MIPS74K | `bcm47xx/mips74k` |
| `arch/bcm4908-generic` | BCM4908 | `bcm4908/generic` |
| `arch/bcm53xx-generic` | BCM53xx | `bcm53xx/generic` |
| `arch/bmips-bcm6318` | BCM6318 光猫 | `bmips/bcm6318` |
| `arch/bmips-bcm63268` | BCM63268 | `bmips/bcm63268` |
| `arch/bmips-bcm6328` | BCM6328 | `bmips/bcm6328` |
| `arch/bmips-bcm6358` | BCM6358 | `bmips/bcm6358` |
| `arch/bmips-bcm6362` | BCM6362 | `bmips/bcm6362` |
| `arch/bmips-bcm6368` | BCM6368 | `bmips/bcm6368` |

### Lantiq / xRX / DSL

| 分支 | 适用 | OpenWrt target |
|------|------|----------------|
| `arch/lantiq-xrx200` | Lantiq xRX200 | `lantiq/xrx200` |
| `arch/lantiq-xrx200_legacy` | Lantiq xRX200 旧驱动 | `lantiq/xrx200_legacy` |
| `arch/lantiq-xway` | Lantiq xWAY DSL | `lantiq/xway` |

### Marvell

| 分支 | 适用 | OpenWrt target |
|------|------|----------------|
| `arch/mvebu-cortexa53` | ARMADA 370/7K/8K (Cortex-A53) | `mvebu/cortexa53` |
| `arch/mvebu-cortexa72` | ARMADA 7K/8K (Cortex-A72) | `mvebu/cortexa72` |
| `arch/mvebu-cortexa9` | ARMADA 375/38x (Cortex-A9) | `mvebu/cortexa9` |
| `arch/apm821xx-nand` | AMCC APM821xx NAND | `apm821xx/nand` |
| `arch/apm821xx-sata` | AMCC APM821xx SATA | `apm821xx/sata` |
| `arch/kirkwood-generic` | Marvell Kirkwood NAS | `kirkwood/generic` |

### NXP / Freescale / PowerPC

| 分支 | 适用 | OpenWrt target |
|------|------|----------------|
| `arch/imx-cortexa53` | i.MX 8M | `imx/cortexa53` |
| `arch/imx-cortexa7` | i.MX 6UL/7D | `imx/cortexa7` |
| `arch/imx-cortexa9` | i.MX 6 | `imx/cortexa9` |
| `arch/layerscape/armv7` | NXP Layerscape ARMv7 | `layerscape/armv7` |
| `arch/layerscape/armv8_64b` | NXP Layerscape ARMv8 64-bit | `layerscape/armv8_64b` |
| `arch/mpc85xx-p1010` | Freescale P1010 | `mpc85xx/p1010` |
| `arch/mpc85xx-p1020` | Freescale P1020 | `mpc85xx/p1020` |
| `arch/mpc85xx-p2020` | Freescale P2020 | `mpc85xx/p2020` |
| `arch/qoriq-generic` | NXP QorIQ | `qoriq/generic` |

### Allwinner sunxi

| 分支 | 适用 | OpenWrt target |
|------|------|----------------|
| `arch/sunxi/arm926ejs` | Allwinner ARM926 | `sunxi/arm926ejs` |
| `arch/sunxi/cortexa53` | Allwinner Cortex-A53（H6 等） | `sunxi/cortexa53` |
| `arch/sunxi/cortexa7` | Allwinner Cortex-A7（H3 等） | `sunxi/cortexa7` |
| `arch/sunxi/cortexa8` | Allwinner Cortex-A8 | `sunxi/cortexa8` |

### Realtek（交换机为主）

| 分支 | 适用 | OpenWrt target |
|------|------|----------------|
| `arch/realtek-rtl838x` | RTL838x | `realtek/rtl838x` |
| `arch/realtek-rtl839x` | RTL839x | `realtek/rtl839x` |
| `arch/realtek-rtl930x` | RTL930x | `realtek/rtl930x` |
| `arch/realtek/rtl930x_nand` | RTL930x NAND | `realtek/rtl930x_nand` |
| `arch/realtek-rtl931x` | RTL931x | `realtek/rtl931x` |
| `arch/realtek/rtl931x_nand` | RTL931x NAND | `realtek/rtl931x_nand` |

### MIPS / RISC-V / 国产

| 分支 | 适用 | OpenWrt target |
|------|------|----------------|
| `arch/octeon-generic` | Cavium Octeon MIPS64 | `octeon/generic` |
| `arch/gemini-generic` | Cortina Gemini | `gemini/generic` |
| `arch/malta-be` | MIPS Malta BE | `malta/be` |
| `arch/malta-be64` | MIPS Malta BE64 | `malta/be64` |
| `arch/malta-le` | MIPS Malta LE | `malta/le` |
| `arch/malta-le64` | MIPS Malta LE64 | `malta/le64` |
| `arch/loongarch64-generic` | 龙芯 LoongArch64 | `loongarch64/generic` |
| `arch/sifiveu-generic` | SiFive U54/U74 RISC-V | `sifiveu/generic` |
| `arch/siflower-sf21` | 矽力杰 SF21xx | `siflower/sf21` |
| `arch/starfive-generic` | StarFive JH7100 / VisionFive | `starfive/generic` |
| `arch/d1-generic` | 全志 D1 (RISC-V) | `d1/generic` |

### Microchip / Atmel / ST / TI / Xilinx / NVIDIA / Intel IXP

| 分支 | 适用 | OpenWrt target |
|------|------|----------------|
| `arch/microchipsw-lan969x` | Microchip LAN969x 交换机 | `microchipsw/lan969x` |
| `arch/at91-sam9x` | Atmel SAM9x | `at91/sam9x` |
| `arch/at91-sama5` | Atmel SAMA5 | `at91/sama5` |
| `arch/at91-sama7` | Atmel SAMA7 | `at91/sama7` |
| `arch/mxs-generic` | Freescale i.MX28 | `mxs/generic` |
| `arch/omap-generic` | TI OMAP | `omap/generic` |
| `arch/pistachio-generic` | ImgTec Pistachio | `pistachio/generic` |
| `arch/stm32-stm32mp1` | STMicro STM32MP1 | `stm32/stm32mp1` |
| `arch/tegra-generic` | NVIDIA Tegra | `tegra/generic` |
| `arch/zynq-generic` | Xilinx Zynq-7000 | `zynq/generic` |
| `arch/ixp4xx-generic` | Intel XScale IXP4xx | `ixp4xx/generic` |

---

## 仓库结构（单仓多分支）

```
tinynas-labs/tinynas-openwrt-imagebuilder
├── README.md                  ← 本文件
├── CONTRIBUTING.md            ← 如何新增架构
├── .github/workflows/         ← GitHub Actions
│   ├── lint.yml               ← shellcheck + markdownlint + 目录结构校验
│   └── build.yml              ← arch/** 分支: 跑打包验证
├── scripts/
│   └── gen-arch-branch.sh     ← 批量生成架构分支的脚本
├── common/                    ← 所有架构共享的模板与覆盖层
│   ├── build-template.sh      ← 打包脚本模板（被各 arch/build.sh 引用）
│   ├── packages.common.txt    ← 通用包列表
│   ├── tinynas-files/         ← TinyNAS rootfs 覆盖层（权威源）
│   └── CHANGELOG.md
└── arch/                      ← 按架构分支的专属配置（仅在各自 arch/<name> 分支存在）
    ├── x86_64/
    ├── armvirt-64/
    └── ...
```

## 分支约定

| 分支 | 用途 | CI |
|------|------|-----|
| `main` | 文档、模板、`common/` 通用配置、`scripts/` | lint + 文档构建 |
| `arch/<name>` | 具体架构的打包配置（`arch/<name>/` 目录） | 跑打包验证、产出镜像 |

每个 `arch/<name>` 分支只放该架构专属文件；通用文件改在 `main` 分支 `common/` 下。

## 镜像命名规范

二次定制后产物（与 `tinynas-labs/amlogic-s9xxx-openwrt` 一致，第 2 段带功能档位）：

```
openwrt_tinynas-<档位>-<设备>_v<SemVer>-<渠道>_<YYYY.MM.DD>.img.gz
 └──┘ └─────┬─────┘ └─┘ └────┘ └──────┘ └──────┘
 openwrt  档位+设备     版本   渠道    构建日期
```

例如：`openwrt_tinynas-pro-x86_64_v1.0.0-stable_2026.08.28.img.gz`

## 产品档位（Pro / Edge / Lite）

打包时通过 `TIER` 选择功能档位，包集合三层叠加：`packages.common.txt`（全档共享）+ `packages.tier-<档位>.txt`（档位差异）+ `arch/<name>/packages.txt`（硬件驱动）。

| 档位 | 推荐硬件 | 内存档 | 功能差异 |
|------|---------|--------|---------|
| **Pro** | N1（eMMC+千兆，建议 2GB） | 1–2GB | 全功能：Alist 网盘聚合 + FileBrowser + ZeroClaw AI |
| **Edge** | 小米盒子3 / 魔百盒（U盘+百兆） | 1GB | 无 Alist/FileBrowser，文件管理走 CGI，保留 ZeroClaw AI |
| **Lite** | 路由器（128–256MB RAM） | 128–256MB | 再去 ZeroClaw（AI），纯轻 NAS + 下载机（仅 aria2，Samba 建议换 ksmbd） |

```bash
# 用法：环境变量传入（默认 pro；arch/<name>/build.sh 可按设备写死第 7 参数）
TIER=lite ./build.sh stable 1.0.0
```

构建时会将档位写入固件 `/etc/tinynas/tier`，dashboard 据此隐藏不可用模块（Lite 隐藏智能体中心、Edge 隐藏网盘聚合），同一份前端代码全档复用。

## 快速开始

```bash
# 1. 切到对应架构分支
git checkout arch/x86_64

# 2. 在 Linux 主机上跑打包脚本
cd arch/x86_64
./build.sh

# 3. 产物在
ls output/openwrt_tinynas-x86_64_v*.img.gz
```

> `build.sh` 会自动从 [OpenWrt 官方下载站](https://downloads.openwrt.org/releases/25.12.5/targets/) 拉取对应版本的 Image Builder（不在仓库中），注入 `common/tinynas-files/` 覆盖层，产出命名规范的 img.gz。

## 与其他 TinyNAS 仓库的关系

| 仓库 | 用途 |
|------|------|
| [`tinynas-labs/amlogic-s9xxx-openwrt`](https://github.com/tinynas-labs/amlogic-s9xxx-openwrt) | 斐讯 N1 / 小米盒子3 等 Amlogic S9xxx 系列（基于 ophub 上游 fork） |
| `tinynas-labs/tinynas-openwrt-imagebuilder`（本仓库） | 92 个 OpenWrt 官方架构（基于 OpenWrt 官方 Image Builder） |
| `tinynas-labs/armbian-build`（未来） | 非 OpenWrt 平台（基于 Armbian） |
| `tinynas-labs/dashboard` | 仪表盘前端（Vue3 SPA，静态资源本地内置零外链） |
| `tinynas-labs/pairing` | 云端配对服务（Rust + Axum + SQLite） |

所有 fork 仓共享 `common/tinynas-files/` 覆盖层，一次改动全平台生效。

## 新增架构

参见 [CONTRIBUTING.md](./CONTRIBUTING.md)。简言之：在 `main` 上跑 `bash scripts/gen-arch-branch.sh <arch-list.txt>`，或在 OpenWrt 上游有新架构后更新清单。

## License

本仓库的脚本与配置遵循 Apache-2.0；`tinynas-files/` 覆盖层遵循 Apache-2.0；Image Builder 上游产物遵循 OpenWrt 自己的许可证（见 `OpenWrt` 主仓）。