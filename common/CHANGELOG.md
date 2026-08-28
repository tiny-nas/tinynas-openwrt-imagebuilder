# Changelog

所有对 `tinynas-files/` 覆盖层、`build-template.sh`、`packages.common.txt` 的改动都应记录在此。

格式参考 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.1.0/)。

## [Unreleased]

### Added
- 仓库初始化：`common/build-template.sh`、`common/packages.common.txt`、`common/tinynas-files/` 目录骨架
- README.md、CONTRIBUTING.md、.gitignore
- 文档化的命名规范与分支约定
- 92 个 `arch/<name>` 架构分支（基于 OpenWrt 25.12.5 官方 targets 全量覆盖）
- `scripts/gen-arch-branch.sh`：批量生成 arch 分支
- `scripts/sync-common-to-branches.sh`：把 main 的公共文件批量同步到全部 arch 分支
- 产品档位体系 Pro / Edge / Lite：`packages.tier-{pro,edge,lite}.txt` 三层包叠加（common + tier + arch），`build-template.sh` 新增 TIER 参数（第 7 参数或环境变量），构建时写入 `/etc/tinynas/tier` 等运行时标识，产物命名第 2 段带档位：`openwrt_tinynas-<档位>-<设备>_v...`

### Changed
- 仓库更名 `openwrt-imagebuilder` → `tinynas-openwrt-imagebuilder`（自有仓库带 tinynas- 前缀，fork 保留上游名）
- 品牌字统一：简盒 → 锦盒

### Fixed
- `build-template.sh`：适配 OpenWrt 24.10+ Image Builder 的 `.tar.zst` 格式（23.05 及更早仍兼容 `.tar.xz`）。此前 25.12.5 分支会在下载步骤 404。
- `scripts/gen-arch-branch.sh`：`git add` → `git add -f`，修复 main 的 `.gitignore` 含 `/arch/` 时新分支内容被静默忽略导致脚本无声退出的问题。

### Pending
- `tinynas-files/etc/init.d/tinynas-boot` 首次启动向导脚本
- `tinynas-files/etc/tinynas/` 运行时配置模板
- `tinynas-files/www/tinynas/` 仪表盘前端（依赖 dashboard 仓库）
- `tinynas-files/www/cgi-bin/` 系统 API
- `tinynas-files/usr/bin/tinynas-organize` + `tinynas-vision`（Rust 实现）
- FileBrowser / Alist / ZeroClaw 二进制的按档位 manifest 装配（Pro: 三者全量；Edge: 仅 ZeroClaw；Lite: 无）
