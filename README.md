# TinyNAS 简盒 · OpenWrt Image Builder 集成层

[TinyNAS 简盒](https://github.com/tinynas-labs) 是面向斐讯 N1 / 迷你主机 / 家用路由器的"轻量 NAS + AI 助理"家庭算力网关系统。本仓库是 TinyNAS 在 **OpenWrt 官方 Image Builder** 上的多架构集成层。

> 项目代号：**`TinyNAS`**（中文：**简盒**）—— Tiny 一眼传递硬件小巧，NAS 一眼传递品类。
> 文档详见 [`tinynas-labs/amlogic-s9xxx-openwrt`](https://github.com/tinynas-labs/amlogic-s9xxx-openwrt) 与 [品牌主页](https://github.com/tinynas-labs)。

---

## 仓库结构（单仓多分支）

```
tinynas-labs/openwrt-imagebuilder
├── README.md                  ← 本文件
├── CONTRIBUTING.md            ← 如何新增架构
├── common/                    ← 所有架构共享的模板与覆盖层
│   ├── build-template.sh      ← 打包脚本模板（被各 arch/build.sh 引用）
│   ├── packages.common.txt    ← 通用包列表
│   └── tinynas-files/         ← TinyNAS rootfs 覆盖层（权威源）
├── arch/                      ← 按架构分支的专属配置
│   ├── x86_64/                ← 分支: arch/x86_64
│   │   ├── build.sh
│   │   ├── packages.txt
│   │   ├── profiles/
│   │   └── README.md
│   └── armvirt-64/            ← 分支: arch/armvirt-64
│       └── ...
└── .github/workflows/         ← GitHub Actions
    ├── lint.yml               ← main 分支: 文档/lint
    └── build.yml              ← arch/** 分支: 跑打包验证
```

## 分支约定

| 分支 | 用途 | CI |
|------|------|-----|
| `main` | 文档、模板、`common/` 通用配置 | lint + 文档构建 |
| `arch/<name>` | 具体架构的打包配置（`arch/<name>/` 目录） | 跑打包验证、产出镜像 |

每个 `arch/<name>` 分支只放该架构专属文件；通用文件改在 `main` 分支 `common/` 下。

## 镜像命名规范

二次定制后产物（与 `tinynas-labs/amlogic-s9xxx-openwrt` 一致）：

```
openwrt_tinynas-<设备>_v<SemVer>-<渠道>_<YYYY.MM.DD>.img.gz
 └──┘ └──────┘ └─┘ └────┘ └──────┘ └──────┘
 openwrt 品牌+设备  版本   渠道    构建日期
```

例如：`openwrt_tinynas-x86_64_v1.0.0-stable_2026.08.28.img.gz`

## 当前支持的架构

| 架构 | 分支 | 状态 |
|------|------|------|
| x86_64（迷你主机） | `arch/x86_64` | ✅ 已验证 |
| armvirt-64（通用 ARMv8） | `arch/armvirt-64` | 🧪 框架就绪，待验证 |

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

> `build.sh` 会自动从 [OpenWrt 官方下载站](https://downloads.openwrt.org/releases/) 拉取对应版本的 Image Builder（不在仓库中），注入 `common/tinynas-files/` 覆盖层，产出命名规范的 img.gz。

## 与其他 TinyNAS 仓库的关系

| 仓库 | 用途 |
|------|------|
| [`tinynas-labs/amlogic-s9xxx-openwrt`](https://github.com/tinynas-labs/amlogic-s9xxx-openwrt) | 斐讯 N1 / 小米盒子3 等 Amlogic S9xxx 系列（基于 ophub 上游 fork） |
| `tinynas-labs/openwrt-imagebuilder`（本仓库） | 路由器 / 迷你主机 / 通用 ARMv8（基于 OpenWrt 官方 Image Builder） |
| `tinynas-labs/armbian-build`（未来） | 非 OpenWrt 平台（基于 Armbian） |
| `tinynas-labs/dashboard` | 仪表盘前端（Vue3 CDN SPA） |
| `tinynas-labs/pairing` | 云端配对服务（Rust + Axum + SQLite） |

所有 fork 仓共享 `common/tinynas-files/` 覆盖层，一次改动全平台生效。

## License

本仓库的脚本与配置遵循 Apache-2.0；`tinynas-files/` 覆盖层遵循 Apache-2.0；Image Builder 上游产物遵循 OpenWrt 自己的许可证（见 `OpenWrt` 主仓）。