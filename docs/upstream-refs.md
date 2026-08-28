# 上游参考源（本地锁定版）

为随时核对上游行为，以下参考源已浅克隆到本地（**不入本仓库**）：

| 仓库 | 锁定版本 | 本地路径 | 用途 |
|:---|:---|:---|:---|
| openwrt/openwrt | tag `v25.12.5` | `../upstream-refs/openwrt` | 基础系统 init（uhttpd/block-mount 等）、feeds 锁定 |
| openwrt/packages | feed pin `5caa62e`（25.12.5 feeds.conf.default 锁定） | `../upstream-refs/packages` | samba4/minidlna/aria2 等 opkg 包的 init/uci schema |
| openwrt/luci | feed pin `128a781` | `../upstream-refs/luci` | SP-2B luci-theme 主题结构、luci-app 样板 |

## 核对约定

1. 任何对上游 init/uci 行为的断言（评审、任务、SOP），必须引用本目录内文件的路径+行号，不接受"我记得/网上说"
2. `tinynas-files/` 中的 uci 配置写法，以本目录对应包 init 的消费方式为准（`option` vs `list`、节类型、选项归属）
3. OpenWrt 版本升级时：按新版本 feeds.conf.default 重新锁定三份参考源
