# Changelog

所有对 `tinynas-files/` 覆盖层、`build-template.sh`、`packages.common.txt` 的改动都应记录在此。

格式参考 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.1.0/)。

## [Unreleased]

### Fixed
- `build-template.sh`：适配 OpenWrt 24.10+ Image Builder 的 `.tar.zst` 格式（23.05 及更早仍兼容 `.tar.xz`）。此前 25.12.5 分支会在下载步骤 404。
- `scripts/gen-arch-branch.sh`：`git add` → `git add -f`，修复 main 的 `.gitignore` 含 `/arch/` 时新分支内容被静默忽略导致脚本无声退出的问题。

### Added
- 仓库初始化：`common/build-template.sh`、`common/packages.common.txt`、`common/tinynas-files/` 目录骨架
- README.md、CONTRIBUTING.md、.gitignore
- 文档化的命名规范与分支约定
- 92 个 `arch/<name>` 架构分支（基于 OpenWrt 25.12.5 官方 targets 全量覆盖）
- `scripts/sync-common-to-branches.sh`：把 main 的公共文件批量同步到全部 arch 分支

### Pending
- `tinynas-files/etc/init.d/tinynas-boot` 首次启动向导脚本
- `tinynas-files/etc/tinynas/` 运行时配置模板
- `tinynas-files/www/tinynas/` 仪表盘前端（依赖 dashboard 仓库）
- `tinynas-files/www/cgi-bin/` 系统 API
- `tinynas-files/usr/bin/tinynas-organize` + `tinynas-vision`（Rust 实现）