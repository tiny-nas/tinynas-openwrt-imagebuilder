# `tinynas-files/` 覆盖层

这是 **锦盒 TinyNAS** 的 rootfs 覆盖层权威源，被所有架构打包脚本经 Image Builder `FILES=` 注入固件（92 架构直出 + Amlogic remake 共享此单源）。

## 当前内容（S1 已实现）

```
tinynas-files/
├── etc/
│   ├── tinynas/                  ← 运行时标识目录（brand/tier/version/channel/build
│   │                                由 build-template.sh 构建期写入；
│   │                                ed25519-pub.key 由 CI secret 注入）
│   ├── init.d/
│   │   ├── tinynas-license-check ← S98 开机指纹复核（硬件变更撤销激活）
│   │   └── tinynas-boot          ← S99 激活状态机（劫持↔解锁 + 服务编排）
│   ├── uci-defaults/
│   │   └── 50-tinynas-uhttpd     ← 首启幂等 uHTTPd 配置
│   ├── config/
│   │   ├── samba4                ← SMB2/3 + NetBIOS 广播（电视可识别）
│   │   └── minidlna              ← 锦盒-媒体库 + inotify
│   └── hotplug.d/block/
│       └── 50-tinynas-disk       ← 机械盘接入触发快扫（不挂载，序号>10）
├── usr/bin/
│   └── tinynas-machine-id        ← 五要素 machine_digest 设备身份
├── www/
│   ├── index.html                ← 根路径跳转 /tinynas/（激活后）
│   ├── tinynas-wizard.html       ← 首次激活向导（单文件 ≤50KB 零外链）
│   ├── tinynas/                  ← 仪表盘 SPA（dashboard 仓构建产物）
│   └── cgi-bin/
│       ├── machine-id            ← 身份+配对码 JSON
│       ├── license-import        ← Ed25519 许可证导入验证
│       ├── status                ← 5s 轮询状态
│       └── files                 ← 白名单目录列表（Edge 档文件入口）
└── tests/                        ← 宿主行为测试（macOS/Linux 可跑）
    ├── run-lint.sh               ← 8 条军规静态门禁（见 docs/plan V1-Arch §5.3）
    ├── test-machine-id.sh        ← TDD 期望值由 python3 独立生成
    ├── test-license-import.sh    ← Ed25519 四用例（需 openssl 支持 -rawin）
    ├── gen-test-license.sh       ← 测试信封生成器（测试密钥，绝不用于生产）
    └── fixtures/                 ← sysinfo / share / keys
```

## 待交付（P1/S3）

`usr/bin/tinynas-nats-consumer`、`etc/init.d/tinynas-nats`、`usr/bin/tinynas-disk-check`（hotplug 已预留调用点）。

## 硬约束（V1-Arch §5.3 八条军规）

1. init.d 必含 rc.common shebang + `START=`（否则构建期静默不 enable）
2. procd 服务写 `start_service()`，不写 `start()`
3. uci-defaults 幂等 + 结尾 `exit 0`
4. CGI 放 `/www/cgi-bin/` 且 `+x`，避开 `luci` 前缀，60s 内返回，root 运行禁拼 shell
5. 不自写挂载 hotplug 与 block-mount `10-mount` 竞争（附加序号 >10）
6. CGI 输入全部不可信（白名单字符、禁 eval）
7. 前端零公网 CDN（`(src|href)="https?://` 门禁）
8. 覆盖层目录镜像 rootfs 根；禁手放 `/etc/rc.d/`（IB 自动 enable）

## 宿主测试

```bash
cd common/tinynas-files
tests/run-lint.sh        # 全部静态 + 行为门禁
```
