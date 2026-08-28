# Changelog

所有对 `tinynas-files/` 覆盖层、`build-template.sh`、`packages.common.txt` 的改动都应记录在此。

格式参考 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.1.0/)。

## [Unreleased]

### Added
- 仓库初始化：`common/build-template.sh`、`common/packages.common.txt`、`common/tinynas-files/` 目录骨架
- README.md、CONTRIBUTING.md、.gitignore
- 文档化的命名规范与分支约定

### Pending
- `tinynas-files/etc/init.d/tinynas-boot` 首次启动向导脚本
- `tinynas-files/etc/tinynas/` 运行时配置模板
- `tinynas-files/www/tinynas/` 仪表盘前端（依赖 dashboard 仓库）
- `tinynas-files/www/cgi-bin/` 系统 API
- `tinynas-files/usr/bin/tinynas-organize` + `tinynas-vision`（Rust 实现）