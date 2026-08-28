# `tinynas-files/` 覆盖层

这是 **锦盒 TinyNAS** 的 rootfs 覆盖层，会被各架构打包脚本注入到 Image Builder 的 `files/` 目录，最终合并进产出的 OpenWrt 固件。

## 目录结构

```
tinynas-files/
├── etc/
│   ├── tinynas/         ← 机器码、激活密钥、版本、渠道（首次启动时生成）
│   ├── config/          ← Samba、MiniDLNA、uHTTPd 预置配置
│   └── init.d/          ← 首次启动向导 + 激活劫持脚本
├── www/
│   ├── tinynas/         ← 仪表盘前端（Vue3 SPA，静态资源本地内置零外链）
│   │                     由 tinynas-labs/dashboard 仓库构建后产物
│   └── tinynas-wizard.html  ← 首次启动向导页
├── cgi-bin/             ← 状态/文件/激活 API
│   ├── status           ← 系统状态 JSON API
│   ├── files            ← 文件列表 JSON API
│   ├── activate         ← 激活码校验 CGI
│   └── agent            ← AI 智能体控制 API
└── usr/bin/
    ├── tinynas-organize ← 文件归类工具（Rust 实现）
    └── tinynas-vision   ← 图片分析工具（调用云端 vision API）
```

## 与上游 dashboard 仓库的关系

`www/tinynas/` 目录下的前端由 [`tinynas-labs/dashboard`](https://github.com/tinynas-labs/dashboard) 构建后产物发布；本仓库不直接维护前端源码，仅做集成。

## 当前状态

⚠️ **骨架已就位，等待实际填充**：

- `etc/tinynas/`、`etc/config/`、`etc/init.d/` 为空目录
- `www/tinynas/` 为空目录（待 dashboard 仓库构建产物）
- `www/cgi-bin/` 为空目录
- `usr/bin/` 为空目录（待 Rust 工具链产出）

后续 PR 将逐步填充：
1. 仪表盘前端（依赖 dashboard 仓库）
2. CGI 脚本（Shell 实现）
3. tinynas-organize / tinynas-vision（Rust 交叉编译产物）