# `tinynas-files/` 覆盖层

锦盒 TinyNAS rootfs 覆盖层权威源，被 `common/build-template.sh` 注入到各架构固件 rootfs。

## V1 状态（2026-08-28）

### 已完成
- `etc/tinynas/brand` + `secret` 模板
- `etc/init.d/tinynas-boot` 劫持/激活两态
- `etc/init.d/tinynas-license-check` 开机指纹复核
- `etc/config/samba4` + `mnt/usb/share/` 共享
- `etc/config/minidlna` + `etc/aria2.conf` 媒体/下载

### 待 SP-2 注入
- `www/tinynas/` 仪表盘产物
- `www/tinynas-wizard.html` 首次启动向导页

### 待 SP-3 注入
- `usr/bin/tinynas-nats-consumer` 消息消费者
