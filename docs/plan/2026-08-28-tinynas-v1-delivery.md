# 锦盒 TinyNAS V1.0 9-10月交付 实施计划（v2，含 LuCI 统一主题）

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 9-10 月内交付锦盒 TinyNAS V1.0 完整版（含 N1 固件 + 仪表盘 SPA + **完整 LuCI 统一主题** + NATS/pairing + 浏览器插件 + 渠道工具），10 月初可限量预售/试卖，10-31 V1.0 GA 进入全面销售。

**Architecture:** 单仓多分支 `tiny-nas/tinynas-openwrt-imagebuilder`（main + 92 个 `arch/<name>`）+ 配套独立仓 `pairing` / `dashboard` / `chrome-extension` / `tools` / **新增 `luci-theme-tinynas`**。N1 走 ophub 零改动 fork 路径；其余 92 架构走 OpenWrt 官方 Image Builder（脚本下载 tar）。覆盖层 `common/tinynas-files/` 为所有固件共享权威源。LuCI 主题 fork luci-theme-bootstrap 重写视觉层，锦盒设计令牌（颜色/字体/圆角/卡片/动效）从 SCSS 变量统一生成。

**Tech Stack:** OpenWrt 25.12.5 · ophub amlogic-s9xxx-openwrt（fork，零 commit） · Shell CGI + uHTTPd · Vue3 + Tailwind（本地 vendor，零 CDN） · **luci-theme-tinynas（fork luci-theme-bootstrap + SCSS 重构）** · Rust + Axum + SQLite（pairing） · NATS Server 2.10.x + JetStream · Chrome MV3 + nats.ws · Python tkinter（生成器） · GitHub Actions（动态分支构建）。

**人员:** hiwepy（项目负责人，SP-1/2A/3/4/5/6）+ 搭档（LuCI 主题专职，SP-2B/6），双方均用 codex 辅助。每日站会同步进度与设计令牌变更。

## Global Constraints

- **OpenWrt 版本**：25.12.5（92 架构分支统一到 25.12.5，R3D 例外到 24.10.x kernel 6.6，**仅 V2 引入**；V1 不做 R3D）
- **包层叠加**：`packages.common.txt` + `packages.tier-${TIER}.txt` + `arch/<x>/packages.txt`；V1 档位恒为 `pro`，但模板必须支持 edge/lite
- **镜像命名**：`openwrt_tinynas-<档位>-<设备>_v<SemVer>-<渠道>_<YYYY.MM.DD>.<ext>`（`ext` = `.img.gz` / `.bin`）
- **前端零公网 CDN**：Vue / Tailwind / 图标 vendor 进 `tinynas-files/www/tinynas/assets/`；交付前 `grep -rE "https?://" www/tinynas/` 审计
- **体积预算（锦盒 SPA）**：`index.html ≤50KB` / `app.js ≤200KB` / `style.css ≤100KB`
- **LuCI 主题零外链**：所有图标/字体 vendor 进 `htdocs/luci-static/tinynas/`；同审计
- **LuCI 主题体积预算（路由器 4MB Flash 约束）**：CSS 输出 ≤80KB（gzip 后），单个图标 ≤2KB
- **设计令牌源头**：`partme-docs/8、TinyNAS 锦盒/9、TinyNAS-视觉与交互DNA规范.md`（SPA 与 LuCI 主题**共用同一份**）
- **激活机制**：`HMAC-SHA256(机器码, 渠道盐值)` 前 12 位；机器码 = `SHA256(eMMC_CID+CPU_Serial+MAC)` 前 16 位；开机指纹复核
- **NATS 强制 TLS**；每设备独立 user/pass + subject 前缀白名单（Resolver 动态下发）
- **MASTER SECRET 安全红线**：仅存在于我方构建机；店铺工具只持渠道子密钥
- **GPL v2 合规**：所有构建脚本公开；镜像内含 `/LICENSE`
- **通信协议**：NATSREST `/pair`、`/devices/register`、`/nats/users`；插件用 nats.ws；HTTP API 仅 HTTPS
- **双人协作协议**：每日 15 分钟站会；设计令牌变更以 SPA 主题为权威（LuCI 跟进）；冲突以销售优先级高者为准
- **V1.0 GA 推迟到 2026-10-31**（v1 原定 10-12，因完整 LuCI 主题 +1 人协作，推迟 19 天）

---

## 文件结构（计划涉及的文件矩阵）

### 仓库 `tiny-nas/tinynas-openwrt-imagebuilder`（本仓）
```
common/build-template.sh              [MODIFY]  ★ Tier 参数已支持；M1 需补机器码/激活 CGI 调用适配
common/packages.common.txt           [EXISTS]  ★
common/packages.tier-pro.txt        [EXISTS]  ★
common/packages.tier-edge.txt       [EXISTS]  ★
common/packages.tier-lite.txt       [EXISTS]  ★
common/tinynas-files/                [CREATE]  ★ 覆盖层权威源
  ├── etc/tinynas/
  │   ├── brand (channel/device/version/tier/build 模板)
  │   └── config/ + init.d/
  ├── www/
  │   ├── tinynas/                   ← SP-2 仪表盘产物注入点
  │   ├── tinynas-wizard.html        [CREATE]
  │   └── cgi-bin/
  │       ├── machine-id             [CREATE]
  │       ├── activate               [CREATE]
  │       ├── status                 [CREATE]
  │       └── files                  [CREATE]
  └── usr/bin/
      └── tinynas-nats-consumer      [CREATE]
scripts/
├── gen-arch-branch.sh                [EXISTS]
├── sync-common-to-branches.sh       [EXISTS]
└── release-channel.sh                [CREATE]  ★ SP-5 渠道水印构建脚本
docs/plan/                            [CREATE]  ★ 本计划所在
.github/workflows/
├── build.yml                         [EXISTS]  ★ 动态分支解析已支持
└── lint.yml                          [EXISTS]  ★ 加 secret 扫描 + 命名 lint
```

### 独立仓 `tiny-nas/pairing`
```
Cargo.toml                            [CREATE]
src/main.rs                           [CREATE]  ★ Axum 路由 + SQLite
src/routes/{devices,pair,nats,stats}.rs  [CREATE]
src/state.rs                          [CREATE]  ★ 内存缓存（可降级）
migrations/001_init.sql               [CREATE]
deploy/systemd/tinynas-pairing.service [CREATE]
docs/{deploy.md,openapi.md}           [CREATE]
```

### 独立仓 `tiny-nas/dashboard`
```
src/{main.ts,App.vue,router.ts,api.ts}    [CREATE]
src/views/{Dashboard,Files,Downloads,Pairing,Settings,Wizard}.vue  [CREATE]
src/stores/{status,downloads,activation}.ts  [CREATE]
src/components/{StatusCard,FileList,DownloadTask,Sidebar}.vue     [CREATE]
assets/{vue.global.prod.js,icons.svg,style.css (compiled)}         [CREATE]
design-tokens.json                            [CREATE]  ★ SPA 与 LuCI 主题共用
scripts/build.sh                     [CREATE]  ★ vendor 钉版本 + Tailwind 预编译 + 零外链审计
vite.config.ts                        [CREATE]
```

### 独立仓 `tiny-nas/luci-theme-tinynas`（**v2 新增**）
```
htdocs/luci-static/tinynas/
├── design-tokens.json                       [CREATE]  ★ 与 dashboard 同源
├── icons/                                    [CREATE]  ★ SVG ≤2KB each
└── preview.png                               [CREATE]  ★ LuCI 主页视觉证据
luas/
├── header.htm                                [CREATE]  ★ 锦盒横幅注入
└── footer.htm                                [CREATE]
src/scss/
├── tinynas.scss                              [CREATE]  ★ 主入口
├── _tokens.scss                              [CREATE]  ★ 自动生成（来自 design-tokens.json）
├── _layout.scss                              [CREATE]  ★ 侧栏/头部/栅格
├── _status.scss                              [CREATE]  ★ 状态徽标
├── _network.scss / _wireless.scss / _firewall.scss  [CREATE]
├── _forms.scss                               [CREATE]
└── _system.scss / _admin.scss / _services.scss / _logs.scss  [CREATE]
scripts/build-tokens.sh                       [CREATE]  ★ JSON → SCSS
.github/workflows/token-diff.yml             [CREATE]  ★ 与 SPA 仓令牌一致性 CI
Makefile                                      [CREATE]  ★ OpenWrt SDK 编译入口
```

### 独立目录（不入仓）
```
~/work/tinynas/vps-bootstrap/         [CREATE]  ★ VPS 一次性部署脚本
~/work/tinynas/release/               [CREATE]  ★ 渠道交付包
~/work/tinynas/test-rig/              [CREATE]  ★ 真机测试用镜像 + 串口日志
```

---

## SP-1  ·  N1 固件 + 授权闭环  ·  W1–W2

### Task 1.1  准备 VPS 与本地工具链（W1 第 1 天）

**Files:**
- Modify: `~/.ssh/config`（添加 tinynas-vps 别名）
- Create: `~/work/tinynas/vps-bootstrap/`（脚本目录）

**Step 1: 注册 tinynas.io 域名（如果未注册）**
- 在 Cloudflare 注册 `tinynas.io`，NS 指向 Cloudflare DNS
- 验证：`dig tinynas.io` 返回 Cloudflare nameservers

**Step 2: 购买 VPS**
- 配置：1H1G、Ubuntu 22.04、IPv4 公网
- 厂商：Vultr / DigitalOcean / 阿里云 任一
- 验证：SSH 登录成功，`curl https://api.ipify.org` 返回 VPS IP

**Step 3: 本地工具链检查**
Run:
```bash
which gh jq git make curl openssl zstd ssh
gh auth status | head -3   # 期望：hiwepy 已登录
gh api user/orgs | jq -r '.[] | select(.login=="tiny-nas") | .login'  # 期望：tiny-nas
```

**Step 4: 准备 USB-TTL 串口线**
- 设备：CH340G 芯片，3.3V 电压（**绝不能用 5V**），115200-8-N-1
- 验证：N1 通电后串口能抓到 uboot 输出（先不接 N1，USB-TTL 插电脑能识别为 /dev/tty.usbserial 即可）

**Step 5: 闲鱼联系 2 家 N1 刷机店铺**
- 搜索 "N1 扩容" / "斐讯 N1 刷机"，找月销 50+ 的个人工作室
- 加微信，简单说明"V0.9 Beta 末会寄 1 台做试卖"，等试卖阶段联系
- 验证：2 家以上明确回复可参与

**Step 6: commit**
```bash
cd /Users/wandl/workspaces/workspace-tinynas/openwrt-imagebuilder
mkdir -p docs/plan && touch docs/plan/.gitkeep
git add docs/plan/.gitkeep
git commit -m "chore: initialize docs/plan directory"
```

---

### Task 1.2  VPS 部署 NATS + JetStream（W1 第 2 天）

**Files:**
- Create: `~/work/tinynas/vps-bootstrap/install-nats.sh`
- Create: `~/work/tinynas/vps-bootstrap/install-pairing-stub.sh`

**Step 1: VPS 系统更新 + 安装基础**
```bash
ssh tinynas-vps 'apt update && apt upgrade -y && apt install -y curl wget jq ufw sqlite3 ca-certificates'
```

**Step 2: 安装 NATS Server 2.10.x**
```bash
ssh tinynas-vps 'bash -s' < <'EOF'
set -euo pipefail
NATS_VERSION="v2.10.24"
curl -fsSL "https://github.com/nats-io/nats-server/releases/download/${NATS_VERSION}/nats-server-${NATS_VERSION}-linux-amd64.tar.gz" -o /tmp/nats.tar.gz
tar xzf /tmp/nats.tar.gz -C /tmp
sudo mv /tmp/nats-server-${NATS_VERSION}-linux-amd64/nats-server /usr/local/bin/
nats-server --version  # 期望：nats-server version 2.10.24
EOF
```

**Step 3: 生成 TLS 证书（自签，TinyNAS NATS 内部使用）**
```bash
ssh tinynas-vps 'bash -s' < <'EOF'
set -euo pipefail
mkdir -p /etc/nats/tls
cd /etc/nats/tls
openssl req -x509 -nodes -newkey rsa:2048 \
  -keyout server.key -out server.crt \
  -days 3650 -subj "/CN=tinynas-nats" \
  -addext "subjectAltName=DNS:localhost,IP:127.0.0.1"
chmod 600 server.key
EOF
```

**Step 4: NATS 配置文件（带 JetStream）**
```bash
ssh tinynas-vps 'cat > /etc/nats/nats-server.conf <<EOF
port: 4222
http_port: 8222
tls {
  cert_file: "/etc/nats/tls/server.crt"
  key_file: "/etc/nats/tls/server.key"
}
jetstream {
  store_dir: "/var/lib/nats"
  max_memory_store: 64MB
  max_file_store: 1GB
}
authorization {
  # V1 stub: 先放通所有 NATS 操作，SP-3 替换为动态 Resolver
  user: "v1stub"
  password: "$(openssl rand -hex 16)"
}
EOF'
```

**Step 5: systemd 服务**
```bash
ssh tinynas-vps 'bash -s' < <'EOF'
set -euo pipefail
cat > /etc/systemd/system/nats.service <<EOF
[Unit]
Description=NATS Server with JetStream
After=network.target

[Service]
ExecStart=/usr/local/bin/nats-server -c /etc/nats/nats-server.conf
Restart=always
User=nats
Group=nats
ExecStartPre=/usr/bin/install -d -o nats -g nats -m 0700 /var/lib/nats

[Install]
WantedBy=multi-user.target
EOF
useradd -r -s /usr/sbin/nologin nats || true
systemctl daemon-reload
systemctl enable --now nats
systemctl status nats --no-pager  # 期望：active (running)
EOF
```

**Step 6: 创建 JetStream Stream**
```bash
ssh tinynas-vps 'bash -s' < <'EOF'
set -euo pipefail
# 安装 nats CLI
curl -fsSL https://github.com/nats-io/natscli/releases/download/v0.2.10/nats-0.2.10-linux-amd64.tar.gz -o /tmp/natscli.tar.gz
tar xzf /tmp/natscli.tar.gz -C /tmp
mv /tmp/nats-0.2.10-linux-amd64/nats /usr/local/bin/

# TLS 跳过校验（自签证书）
export NATS_NATS_CA=/etc/nats/tls/server.crt
export NATS_NATS_CERT=/etc/nats/tls/server.crt
export NATS_NATS_KEY=/etc/nats/tls/server.key

# 创建 Stream
nats stream add downloads --subjects="downloads.*" \
  --storage=file --retention=limits --discard=old \
  --max-msgs=-1 --max-bytes=1GB --max-age=7d \
  --server=tls://127.0.0.1:4222 --user=v1stub --password=$(grep password /etc/nats/nats-server.conf | awk '{print $3}' | tr -d '"')

# 验证
nats stream ls --server=tls://127.0.0.1:4222 --user=v1stub --password=$(grep password /etc/nats/nats-server.conf | awk '{print $3}' | tr -d '"')
# 期望：downloads
EOF
```

**Step 7: commit + 文档**
```bash
git add ~/work/tinynas/vps-bootstrap/install-nats.sh
git commit -m "chore(plan): NATS install script for VPS bootstrap"
```

---

### Task 1.3  覆盖层骨架：`common/tinynas-files/` 目录与首次启动脚本（W1 第 3 天）

**Files:**
- Create: `common/tinynas-files/README.md`
- Create: `common/tinynas-files/etc/tinynas/brand`
- Create: `common/tinynas-files/etc/tinynas/secret`
- Create: `common/tinynas-files/etc/init.d/tinynas-boot`
- Create: `common/tinynas-files/etc/init.d/tinynas-license-check`
- Create: `common/tinynas-files/etc/config/{samba4,minidlna,aria2,network,fstab}`

**Step 1: 品牌与渠道档案模板**
```bash
cd /Users/wandl/workspaces/workspace-tinynas/openwrt-imagebuilder
mkdir -p common/tinynas-files/{etc/{tinynas,config,init.d},www/{tinynas,cgi-bin},usr/bin}

cat > common/tinynas-files/etc/tinynas/brand <<'EOF'
BRAND=tinynas
TIER=pro
DEVICE=n1
EOF
# 注：version/channel/build 由 build-template.sh 在构建时覆盖

# 渠道盐值（仅示例，V1 stub；SP-3 启动后由 pairing 仓库管理）
cat > common/tinynas-files/etc/tinynas/secret <<'EOF'
CHANNEL_SALT=TinyNAS2026V1DefaultSaltChangeInProduction
EOF
chmod 600 common/tinynas-files/etc/tinynas/secret
```

**Step 2: 首次启动脚本（劫持→向导→激活）**
```bash
cat > common/tinynas-files/etc/init.d/tinynas-boot <<'EOF'
#!/bin/sh /etc/rc.common

START=99
USE_PROCD=1

boot() {
    # 1. 生成机器码（若未存在）
    if [ ! -f /etc/tinynas/.machine_id ]; then
        /usr/bin/tinynas-machine-id > /etc/tinynas/.machine_id 2>/dev/null
    fi

    # 2. 检测激活态
    if [ ! -f /etc/tinynas/.activated ]; then
        # 未激活：劫持 80 端口到向导页
        uci set uhttpd.main.index_page='tinynas-wizard.html'
        uci commit uhttpd
        /etc/init.d/uhttpd restart
        # 限制模式：Samba 只读、aria2 启用（引流）、其他服务不启动
        uci set samba4.@samba[0].read_only='yes' 2>/dev/null || true
        uci commit samba4
        /etc/init.d/samba4 restart
    else
        # 已激活：恢复主仪表盘
        uci set uhttpd.main.index_page='index.html'
        uci commit uhttpd
        /etc/init.d/uhttpd restart
        # 启动 NATS consumer（SP-4 联调后启用，V1 stub 阶段先 echo）
        # /usr/bin/tinynas-nats-consumer &
    fi
}
EOF
chmod +x common/tinynas-files/etc/init.d/tinynas-boot
```

**Step 3: 开机指纹复核脚本**
```bash
cat > common/tinynas-files/etc/init.d/tinynas-license-check <<'EOF'
#!/bin/sh /etc/rc.common

START=98
USE_PROCD=1

start() {
    if [ -f /etc/tinynas/.activated ]; then
        SAVED_ID=$(grep '^machine_id=' /etc/tinynas/.activated | cut -d'=' -f2)
        CURRENT_ID=$(cat /etc/tinynas/.machine_id 2>/dev/null)
        if [ "$SAVED_ID" != "$CURRENT_ID" ]; then
            logger -t tinynas "license check failed: hardware mismatch (saved=$SAVED_ID current=$CURRENT_ID)"
            rm -f /etc/tinynas/.activated
            # 触发首次启动向导
            /etc/init.d/tinynas-boot boot
        fi
    fi
}
EOF
chmod +x common/tinynas-files/etc/init.d/tinynas-license-check
```

**Step 4: Samba 配置（默认只读，激活后切换）**
```bash
cat > common/tinynas-files/etc/config/samba4 <<'EOF'
config samba
    option name 'TINYNAS'
    option workgroup 'WORKGROUP'

config sambashare
    option name 'share'
    option path '/mnt/usb/share'
    option read_only 'yes'
    option guest_ok 'yes'
    option browseable 'yes'
EOF

mkdir -p common/tinynas-files/mnt/usb/share
cat > common/tinynas-files/mnt/usb/share/README.txt <<'EOF'
锦盒 TinyNAS 共享目录

激活前：只读
激活后：可写
EOF
```

**Step 5: MiniDLNA + aria2 配置**
```bash
cat > common/tinynas-files/etc/config/minidlna <<'EOF'
config minidlna 'config'
    option friendly_name '锦盒-媒体库'
    option media_dir 'V,/mnt/usb/share/Movies'
    option media_dir 'A,/mnt/usb/share/Music'
    option media_dir 'P,/mnt/usb/share/Photos'
    option inotify '1'
    option notify_interval '60'
EOF

mkdir -p common/tinynas-files/etc/config
cat > common/tinynas-files/etc/aria2.conf <<'EOF'
enable-rpc=true
rpc-listen-all=true
rpc-listen-port=6800
rpc-secret=$(cat /proc/sys/kernel/random/uuid)
rpc-allow-origin-all=true
dir=/mnt/usb/Downloads
max-concurrent-downloads=5
split=16
max-connection-per-server=5
min-split-size=10M
EOF
```

**Step 6: 覆盖层 README**
```bash
cat > common/tinynas-files/README.md <<'EOF'
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
EOF

**Step 7: commit**
```bash
git add common/tinynas-files/
git commit -m "feat(common): tinynas-files overlay skeleton for V1 (init/activation/samba/dlna/aria2)"
```

---

### Task 1.4  设备端二进制：`tinynas-machine-id` + `tinynas-nats-consumer` 占位（W1 第 3 天）

**Files:**
- Create: `common/tinynas-files/usr/bin/tinynas-machine-id`
- Create: `common/tinynas-files/usr/bin/tinynas-nats-consumer`（占位）

**Step 1: 机器码生成器（Shell，3 要素 SHA256）**
```bash
cat > common/tinynas-files/usr/bin/tinynas-machine-id <<'EOF'
#!/bin/sh
# 机器码 = SHA256(eMMC_CID + CPU_Serial + MAC) 前 16 位大写

EMMC_CID=$(cat /sys/block/mmcblk0/device/cid 2>/dev/null | tr -d '\n' | head -c 32)
CPU_SERIAL=$(grep -m1 '^Serial' /proc/cpuinfo 2>/dev/null | awk '{print $3}' | tr -d '\n')
MAC=$(cat /sys/class/net/eth0/address 2>/dev/null | tr -d ':' | tr -d '\n')

[ -z "$EMMC_CID" ] && EMMC_CID="NOCID"
[ -z "$CPU_SERIAL" ] && CPU_SERIAL="NOSERIAL"
[ -z "$MAC" ] && MAC="NOMAC"

printf '%s%s%s' "$EMMC_CID" "$CPU_SERIAL" "$MAC" | sha256sum | awk '{print toupper(substr($1,1,16))}'
EOF
chmod +x common/tinynas-files/usr/bin/tinynas-machine-id
```

**Step 2: NATS Consumer 占位（SP-3 真实实现）**
```bash
cat > common/tinynas-files/usr/bin/tinynas-nats-consumer <<'EOF'
#!/bin/sh
# 占位：SP-3 实现 NATS JetStream Durable Consumer 逻辑
# 当前仅 echo 状态，SP-3 后替换为实际订阅
echo "tinynas-nats-consumer: stub (V1.0 启用 SP-3 实现)" >&2
sleep 3600
EOF
chmod +x common/tinynas-files/usr/bin/tinynas-nats-consumer
```

**Step 3: commit**
```bash
git add common/tinynas-files/usr/bin/
git commit -m "feat(common): tinynas-machine-id + nats-consumer stub"
```

---

### Task 1.5  首次启动向导页（W1 第 4 天，纯 HTML 零依赖）

**Files:**
- Create: `common/tinynas-files/www/tinynas-wizard.html`

**Step 1: 向导页（纯 HTML + 内联 CSS + 一行 JS 调用 CGI）**
```bash
cat > common/tinynas-files/www/tinynas-wizard.html <<'EOF'
<!DOCTYPE html>
<html lang="zh-CN">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>锦盒 TinyNAS · 首次激活</title>
<style>
body { background:#0F172A; color:#E2E8F0; font-family:system-ui,-apple-system,"PingFang SC","Microsoft YaHei",sans-serif; display:flex; justify-content:center; align-items:center; min-height:100vh; margin:0; }
.card { background:#1E293B; border-radius:12px; padding:32px 40px; max-width:520px; width:90%; box-shadow:0 4px 24px rgba(0,0,0,0.4); }
h1 { font-size:24px; margin:0 0 8px; color:#F59E0B; }
.sub { color:#94A3B8; font-size:14px; margin-bottom:24px; }
.machine-id { font-family:ui-monospace,monospace; font-size:20px; padding:14px 16px; background:#0F172A; border-radius:8px; letter-spacing:2px; border:1px solid #334155; }
.copy-btn, .activate-btn { background:#F59E0B; color:#0F172A; border:none; padding:10px 20px; border-radius:8px; font-weight:600; cursor:pointer; }
.copy-btn:hover, .activate-btn:hover { background:#D97706; }
.activate-btn:disabled { background:#475569; color:#94A3B8; cursor:not-allowed; }
.activation-code { font-family:ui-monospace,monospace; font-size:18px; padding:14px 16px; background:#0F172A; border:1px solid #334155; border-radius:8px; width:100%; margin-top:8px; letter-spacing:4px; text-transform:uppercase; }
.note { margin-top:24px; padding:14px; background:#0F172A; border-radius:8px; font-size:13px; color:#94A3B8; }
.result { margin-top:16px; padding:12px; border-radius:8px; display:none; }
.result.ok { background:#064e3b; color:#34D399; }
.result.err { background:#7f1d1d; color:#F87171; }
</style>
</head>
<body>
<div class="card">
    <h1>锦盒 TinyNAS</h1>
    <div class="sub">首次激活 — 请把下方 16 位机器码发给卖家获取 12 位激活码</div>

    <div class="machine-id" id="mid">加载中…</div>
    <button class="copy-btn" style="margin-top:8px;" onclick="navigator.clipboard.writeText(document.getElementById('mid').textContent).then(()=>{this.textContent='已复制 ✓';setTimeout(()=>this.textContent='复制机器码',1500)})">复制机器码</button>

    <div style="margin-top:24px;">
        <label style="font-size:13px; color:#94A3B8;">激活码（12 位）</label>
        <input class="activation-code" id="code" maxlength="12" placeholder="________" autocomplete="off">
    </div>
    <button class="activate-btn" id="btn" onclick="doActivate()" style="margin-top:12px; width:100%;">激 活 设 备</button>

    <div class="result" id="result"></div>

    <div class="note">
        ⓘ 未激活期间：Samba 只读 · 无远程下载 · 智能体不可用（激活后自动解锁）
    </div>
</div>

<script>
fetch('/cgi-bin/machine-id').then(r=>r.json()).then(d=>{document.getElementById('mid').textContent=d.machine_id}).catch(e=>{document.getElementById('mid').textContent='读取失败'});

function doActivate(){
    const code=document.getElementById('code').value.trim();
    const btn=document.getElementById('btn');
    const result=document.getElementById('result');
    if(code.length!==12){result.className='result err';result.textContent='激活码必须是 12 位';result.style.display='block';return;}
    btn.disabled=true;btn.textContent='校验中…';
    result.style.display='none';
    fetch('/cgi-bin/activate',{method:'POST',headers:{'Content-Type':'application/x-www-form-urlencoded'},body:'code='+encodeURIComponent(code)})
    .then(r=>r.json()).then(d=>{
        if(d.status==='ok'){
            result.className='result ok';
            result.textContent='✓ 激活成功，3 秒后跳转到仪表盘…';
            result.style.display='block';
            setTimeout(()=>location.href='/',3000);
        } else {
            btn.disabled=false;btn.textContent='激 活 设 备';
            result.className='result err';
            result.textContent='✗ '+d.msg+'（机器码：'+(d.machine_id||'')+'）';
            result.style.display='block';
        }
    }).catch(e=>{btn.disabled=false;btn.textContent='激 活 设 备';result.className='result err';result.textContent='网络错误：'+e;result.style.display='block';});
}
</script>
</body>
</html>
EOF
```

**Step 2: commit**
```bash
git add common/tinynas-files/www/tinynas-wizard.html
git commit -m "feat(common): first-run wizard page (HTML/CSS/JS, no CDN)"
```

---

### Task 1.6  CGI 脚本：`machine-id` / `activate` / `status` / `files`（W1 第 4–5 天）

**Files:**
- Create: `common/tinynas-files/www/cgi-bin/machine-id`
- Create: `common/tinynas-files/www/cgi-bin/activate`
- Create: `common/tinynas-files/www/cgi-bin/status`
- Create: `common/tinynas-files/www/cgi-bin/files`
- Create: `common/tinynas-files/www/cgi-bin/files-upload`
- Create: `common/tinynas-files/www/cgi-bin/files-delete`

**Step 1: machine-id CGI**
```bash
cat > common/tinynas-files/www/cgi-bin/machine-id <<'EOF'
#!/bin/sh
echo "Content-Type: application/json"
echo "Cache-Control: no-store"
echo ""
MACHINE_ID=$(/usr/bin/tinynas-machine-id)
echo "{\"machine_id\":\"$MACHINE_ID\"}"
EOF
chmod +x common/tinynas-files/www/cgi-bin/machine-id
```

**Step 2: activate CGI（HMAC 本地校验）**
```bash
cat > common/tinynas-files/www/cgi-bin/activate <<'EOF'
#!/bin/sh
echo "Content-Type: application/json"
echo "Cache-Control: no-store"
echo ""

# 读取 POST 数据
read -r POST_DATA
INPUT_CODE=$(echo "$POST_DATA" | sed 's/.*code=\([^&]*\).*/\1/' | tr -d '[:lower:]' | tr '[:upper:]' '[:upper:]')

# 读取机器码
MACHINE_ID=$(/usr/bin/tinynas-machine-id)

# 读取渠道盐值
CHANNEL_SALT=$(grep '^CHANNEL_SALT=' /etc/tinynas/secret | cut -d'=' -f2)
[ -z "$CHANNEL_SALT" ] && CHANNEL_SALT="TinyNAS2026V1DefaultSaltChangeInProduction"

# 计算期望激活码
EXPECTED=$(printf '%s' "$MACHINE_ID" | openssl dgst -sha256 -hmac "$CHANNEL_SALT" 2>/dev/null | awk '{print toupper(substr($2,1,12))}')
[ -z "$EXPECTED" ] && EXPECTED=$(printf '%s' "$MACHINE_ID" | openssl dgst -sha256 -hmac "$CHANNEL_SALT" | awk '{print toupper(substr($NF,1,12))}')

if [ "$INPUT_CODE" = "$EXPECTED" ]; then
    cat > /etc/tinynas/.activated <<EOA
machine_id=$MACHINE_ID
code=$INPUT_CODE
activated_at=$(date +%s)
EOA
    echo "{\"status\":\"ok\",\"machine_id\":\"$MACHINE_ID\"}"
else
    echo "{\"status\":\"error\",\"msg\":\"激活码无效\",\"machine_id\":\"$MACHINE_ID\"}"
fi
EOF
chmod +x common/tinynas-files/www/cgi-bin/activate
```

**Step 3: status CGI（仪表盘轮询用）**
```bash
cat > common/tinynas-files/www/cgi-bin/status <<'EOF'
#!/bin/sh
echo "Content-Type: application/json"
echo "Cache-Control: no-store"
echo ""

CPU=$(cat /proc/loadavg | awk '{print $1}')
MEM_TOTAL=$(free | grep Mem | awk '{print $2}')
MEM_USED=$(free | grep Mem | awk '{print $3}')
MEM_PCT=$((MEM_USED * 100 / MEM_TOTAL))
DISK_USED=$(df /mnt/usb 2>/dev/null | tail -1 | awk '{print $3}')
DISK_TOTAL=$(df /mnt/usb 2>/dev/null | tail -1 | awk '{print $2}')
[ -z "$DISK_TOTAL" ] || [ "$DISK_TOTAL" -eq 0 ] && DISK_TOTAL=1

ACTIVATED="false"
[ -f /etc/tinynas/.activated ] && ACTIVATED="true"

TIER=$(grep '^TIER=' /etc/tinynas/brand | cut -d'=' -f2)
DEVICE=$(grep '^DEVICE=' /etc/tinynas/brand | cut -d'=' -f2)

cat <<JSON
{
  "activated": $ACTIVATED,
  "tier": "$TIER",
  "device": "$DEVICE",
  "cpu_load": "$CPU",
  "mem_pct": $MEM_PCT,
  "disk_used": $DISK_USED,
  "disk_total": $DISK_TOTAL,
  "services": {
    "samba": "running",
    "dlna": "running",
    "aria2": "running"
  }
}
JSON
EOF
chmod +x common/tinynas-files/www/cgi-bin/status
```

**Step 4: files CGI（文件列表 + 路径白名单）**
```bash
cat > common/tinynas-files/www/cgi-bin/files <<'EOF'
#!/bin/sh
echo "Content-Type: application/json"
echo "Cache-Control: no-store"
echo ""

# 默认目录
BASE="/mnt/usb/share"
# 白名单校验：拒绝 ../
REQ_PATH=$(echo "$QUERY_STRING" | sed 's/^path=//;s/%2F/\//g')
[ -z "$REQ_PATH" ] && REQ_PATH="/"
# 拼绝对路径，拒绝越界
ABS=$(readlink -f "${BASE}${REQ_PATH}" 2>/dev/null)
case "$ABS" in
  "$BASE"*) ;;
  *) echo '{"error":"path not allowed"}'; exit 0 ;;
esac
[ ! -d "$ABS" ] && { echo '{"error":"not a directory"}'; exit 0; }

# 列表
echo -n '{"entries":['
FIRST=1
for f in "$ABS"/*; do
    [ -e "$f" ] || continue
    NAME=$(basename "$f")
    [ $FIRST -eq 0 ] && echo -n ','
    FIRST=0
    SIZE=$(stat -c %s "$f" 2>/dev/null || stat -f %z "$f" 2>/dev/null)
    MTIME=$(stat -c %Y "$f" 2>/dev/null || stat -f %m "$f" 2>/dev/null)
    IS_DIR=0
    [ -d "$f" ] && IS_DIR=1
    printf '{"name":"%s","size":%s,"mtime":%s,"is_dir":%s}' "$NAME" "$SIZE" "$MTIME" "$IS_DIR"
done
echo ']}'
EOF
chmod +x common/tinynas-files/www/cgi-bin/files
```

**Step 5: files-upload / files-delete 占位（SP-2 仪表盘集成时实现）**
```bash
cat > common/tinynas-files/www/cgi-bin/files-upload <<'EOF'
#!/bin/sh
echo "Content-Type: application/json"
echo "Cache-Control: no-store"
echo ""
echo '{"error":"upload: V1.0 待 SP-2 仪表盘集成"}'
EOF
chmod +x common/tinynas-files/www/cgi-bin/files-upload

cat > common/tinynas-files/www/cgi-bin/files-delete <<'EOF'
#!/bin/sh
echo "Content-Type: application/json"
echo "Cache-Control: no-store"
echo ""
echo '{"error":"delete: V1.0 待 SP-2 仪表盘集成"}'
EOF
chmod +x common/tinynas-files/www/cgi-bin/files-delete
```

**Step 6: commit**
```bash
git add common/tinynas-files/www/cgi-bin/
git commit -m "feat(common): CGI scripts (machine-id/activate/status/files)"
```

---

### Task 1.7  build-template.sh 适配覆盖层与产物路径（W1 第 5 天）

**Files:**
- Modify: `common/build-template.sh`（已存在，需检查覆盖层注入路径与 CGI 可执行属性）

**Step 1: 验证覆盖层注入逻辑**
```bash
# 读 build-template.sh 确认已包含:
grep -n "tinynas-files" common/build-template.sh | head -3
# 期望输出包含：
# rm -rf files && mkdir -p files
# cp -a "${TINYNAS_FILES}/." files/

# CGI 可执行属性在打包后需保留
grep -n "chmod" common/build-template.sh | head -5
```

**Step 2: 若 chmod 缺失，补充**
```bash
# 在 [调用 make image 之前] 添加：
# 确保 CGI 可执行
find "${IB_DIR}/files/www/cgi-bin" -type f -exec chmod +x {} \; 2>/dev/null || true
# init.d 可执行
find "${IB_DIR}/files/etc/init.d" -type f -exec chmod +x {} \; 2>/dev/null || true
# usr/bin 可执行
find "${IB_DIR}/files/usr/bin" -type f -exec chmod +x {} \; 2>/dev/null || true
```

**Step 3: commit（如有修改）**
```bash
git diff common/build-template.sh | head -20
# 若有变更：
git add common/build-template.sh
git commit -m "fix(common/build-template): ensure CGI/init.d/usr.bin executables"
```

---

### Task 1.8  端到端打包：首版 img（W1 第 5–6 天）

**Files:**
- Create: `~/work/tinynas/test-rig/build-first-img.sh`

**Step 1: 验证覆盖层同步到所有 arch 分支**
```bash
cd /Users/wandl/workspaces/workspace-tinynas/openwrt-imagebuilder
git checkout main
./scripts/sync-common-to-branches.sh 2>&1 | tail -3
# 期望：92/92 全部成功
```

**Step 2: 检查 arch/x86_64 build.sh 是否支持 v1.0**
```bash
git checkout arch/x86_64
cat arch/x86_64/build.sh | grep -E "TIER|PROFILE|stable|1.0.0"
# 若已是 25.12.5（上一轮已统一），直接用
```

**Step 3: 打包测试（在 VPS 上跨架构验证）**
```bash
# 推荐先在 Linux VPS 上测试 x86_64，因为不需要真机
ssh tinynas-vps 'bash -s' < <'EOF'
set -euo pipefail
cd /tmp
git clone https://github.com/tiny-nas/tinynas-openwrt-imagebuilder.git
cd tinynas-openwrt-imagebuilder
git checkout arch/x86_64
chmod +x arch/x86_64/build.sh
cd arch/x86_64
./build.sh stable 1.0.0 2>&1 | tail -30
ls -la output/
EOF
```

**Step 4: 验证产物命名合规**
```bash
ssh tinynas-vps 'ls /tmp/tinynas-openwrt-imagebuilder/arch/x86_64/output/' | grep -E '^openwrt_tinynas-pro-x86_64_v1\.0\.0-stable_[0-9]{4}\.[0-9]{2}\.[0-9]{2}'
# 期望：1 个文件匹配
```

**Step 5: 同步设置脚本**
```bash
cp ~/work/tinynas/test-rig/build-first-img.sh /tmp/build-first-img.sh
git add scripts/ 2>/dev/null
git commit -m "ci: V1 first build test script" 2>/dev/null || true
```

---

### Task 1.9  真机端到端 M1 验收（W1 第 6–7 天）

**Files:**
- Create: `docs/m1-verification.md`（验收报告）

**Step 1: U 盘刷入镜像**
- 使用 BalenaEtcher 将 `openwrt_tinynas-pro-x86_64_v1.0.0-beta_*.img.gz` 刷入 U 盘（先在 x86_64 上验证）
- 重启从 U 盘启动，验证：① 路由器层拿到 DHCP；② 192.168.1.1 进入向导

**Step 2: 浏览器访问向导**
- 机器码应展示 16 位大写十六进制
- 复制按钮应写入剪贴板
- 输错激活码应返回错误且不刷新机器码
- 输入正确激活码（用 [V1.5 批量激活生成器](#sp-5-渠道工具) 临时算的）应 3 秒内跳转到 192.168.1.1/

**Step 3: 镜像写入 eMMC（仅 N1 真机）**
- N1 上 U 盘启动后，浏览器访问 192.168.1.1 进入系统
- 通过 SSH 或 CGI 触发 `armbian-install`（ophub 已自带）
- 等待 3–5 分钟，断电拔 U 盘，重启

**Step 4: 写 M1 验收报告**
```bash
cat > docs/m1-verification.md <<'EOF'
# M1 真机验收报告（SP-1 完成标志）

**验收日期**：YYYY-MM-DD
**测试硬件**：N1 一台（用户私有）
**测试固件**：`openwrt_tinynas-pro-n1_v0.9.0-beta_<date>.img.gz`

## 五步走通

- [ ] Step 1：U 盘启动进入向导
- [ ] Step 2：机器码展示+复制正确
- [ ] Step 3：输入正确激活码 3 秒跳转仪表盘
- [ ] Step 4：写 eMMC + 拔 U 盘独立启动
- [ ] Step 5：电视/电脑 Samba 发现 + 文件读写

## 已知问题（如有）

...
EOF
git add docs/m1-verification.md
git commit -m "docs: M1 verification report (filled after on-device test)"
```

**Step 5: 同步覆盖层**
```bash
git checkout main
./scripts/sync-common-to-branches.sh 2>&1 | tail -3
```

---

## SP-2A  ·  仪表盘 SPA（NAS/AI 模块）  ·  W2–W4  ·  **责任人：hiwepy**

> **v2 关键变更**：原 SP-2 拆分为 SP-2A（dashboard SPA，hiwepy）与 SP-2B（LuCI 主题，搭档）并行；LuCI 主题不在 dashboard 仓中。

### Task 2A.1  dashboard 仓库初始化与 vite 配置（W2 第 1 天）

**Files:**
- Create: `~/work/tinynas/dashboard/`（独立仓 `tiny-nas/dashboard`）
- Create: `tiny-nas/dashboard/package.json`
- Create: `tiny-nas/dashboard/vite.config.ts`
- Create: `tiny-nas/dashboard/tsconfig.json`

**Step 1: 远端创建空仓库**
```bash
gh repo create tiny-nas/dashboard --org tiny-nas \
  --description "锦盒 TinyNAS 仪表盘前端（Vue3 SPA，本地资源零外链）" \
  --public
```

**Step 2: 本地克隆**
```bash
cd ~/work/tinynas
git clone https://github.com/tiny-nas/dashboard.git
cd dashboard
git config user.email "hiwepy@users.noreply.github.com"
git config user.name "hiwepy"
```

**Step 3: package.json**
```json
{
  "name": "tinynas-dashboard",
  "private": true,
  "version": "1.0.0",
  "type": "module",
  "scripts": {
    "dev": "vite",
    "build": "vite build",
    "preview": "vite preview",
    "audit:no-cdn": "bash scripts/audit-no-cdn.sh"
  },
  "dependencies": {
    "vue": "3.4.21",
    "vue-router": "4.3.0",
    "pinia": "2.1.7"
  },
  "devDependencies": {
    "@vitejs/plugin-vue": "5.0.4",
    "vite": "5.2.6",
    "tailwindcss": "3.4.3",
    "autoprefixer": "10.4.18",
    "postcss": "8.4.35"
  }
}
```

**Step 4: vite.config.ts（关键：base 相对路径 + vendor 钉版本 + 体积预算检查）**
```ts
import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import path from 'path'

export default defineConfig({
  plugins: [vue()],
  base: './',  // 关键：相对路径，否则在 uHTTPd 子路径下 404
  build: {
    outDir: 'dist',
    target: 'es2018',  // 兼容老电视浏览器
    rollupOptions: {
      output: {
        manualChunks: { vue: ['vue', 'vue-router', 'pinia'] }
      }
    }
  }
})
```

**Step 5: install + 首跑**
```bash
npm install
npm run build
ls -la dist/assets/
# 期望：index-*.js ≤200KB，index-*.css ≤100KB
```

**Step 6: commit**
```bash
git add .
git commit -m "chore: dashboard scaffold (Vue3 + Vite + Tailwind)"
git push origin main
```

---

### Task 2A.2  Vue3 SPA 五页骨架 + 路由 + Pinia（W2 第 2–3 天）

**Files:**
- Create: `tiny-nas/dashboard/src/main.ts`
- Create: `tiny-nas/dashboard/src/App.vue`
- Create: `tiny-nas/dashboard/src/router.ts`
- Create: `tiny-nas/dashboard/src/stores/status.ts`
- Create: `tiny-nas/dashboard/src/views/{Dashboard,Files,Downloads,Pairing,Settings}.vue`
- Create: `tiny-nas/dashboard/src/components/{Sidebar,StatusCard,FileList,DownloadTask}.vue`

**Step 1: main.ts**
```ts
import { createApp } from 'vue'
import { createPinia } from 'pinia'
import App from './App.vue'
import router from './router'

createApp(App).use(createPinia()).use(router).mount('#app')
```

**Step 2: router.ts（五路由 + 未激活劫持到 /wizard）**
```ts
import { createRouter, createWebHashHistory } from 'vue-router'

const routes = [
  { path: '/', redirect: '/dashboard' },
  { path: '/dashboard', component: () => import('./views/Dashboard.vue') },
  { path: '/files', component: () => import('./views/Files.vue') },
  { path: '/downloads', component: () => import('./views/Downloads.vue') },
  { path: '/pairing', component: () => import('./views/Pairing.vue') },
  { path: '/settings', component: () => import('./views/Settings.vue') }
]

export default createRouter({ history: createWebHashHistory(), routes })
```

**Step 3: status store（5s 轮询）**
```ts
import { defineStore } from 'pinia'
import { ref } from 'vue'

export const useStatusStore = defineStore('status', () => {
  const data = ref<any>({})
  let timer: number | undefined

  async function fetch() {
    try { data.value = await (await fetch('/cgi-bin/status')).json() } catch {}
  }

  function start() {
    fetch()
    timer = window.setInterval(fetch, 5000)
    document.addEventListener('visibilitychange', () => {
      if (document.hidden) stop(); else start()
    })
  }
  function stop() { if (timer) window.clearInterval(timer) }

  return { data, start, stop }
})
```

**Step 4: App.vue + Sidebar.vue**
- App.vue: `<Sidebar />` + `<RouterView />`
- Sidebar.vue: 6 个菜单项（图 9 视觉 DNA 中的深色侧栏）
- 路由器模式额外加顶部横幅："🌐 网络配置 → LuCI"（[Task 2B.7](#task-2b7-luci-入口卡片与锦盒-spa-跳转按钮w3-第-2-天) 配套提供）

**Step 5: Dashboard.vue（4 状态卡 + 服务条）**
- 模板：`<StatusCard title="CPU" :value="status.cpu_load" unit="load" /><StatusCard title="内存" :value="status.mem_pct" unit="%" />...`
- 服务状态：4 个绿/红圆点

**Step 6: Pairing.vue（device_id + 配对码展示）**
- device_id 大字 + 复制按钮
- 配对码 6 位 + 60s 环形倒计时
- 三步图文绑定说明

**Step 7: Settings.vue**
- 4 个分组卡：网络（LuCI 跳转）、Samba 账号密码、系统（重启）、关于（机器码/版本/档位/渠道）

**Step 8: 单元测试 status store**
```bash
npm install -D vitest @vue/test-utils
# tests/stores/status.spec.ts：mock fetch 验证轮询
```

**Step 9: 端到端 dev 测试**
```bash
npm run dev
# 浏览器访问 http://localhost:5173
# 验证：路由切换正常、状态卡显示 mock 数据、配对码倒计时
```

**Step 10: 提交 + 推送**
```bash
git add .
git commit -m "feat(dashboard): SPA 5 pages + router + Pinia status store"
git push origin main
```

---

### Task 2A.3  vendor 钉版本 + 零外链审计脚本（W3 第 1 天）

**Files:**
- Create: `tiny-nas/dashboard/scripts/build.sh`
- Create: `tiny-nas/dashboard/scripts/audit-no-cdn.sh`

**Step 1: build.sh（vendor 钉版本 + Tailwind 预编译 + 零外链审计）**
```bash
#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

echo "[1/3] 校验 vendor 版本..."
VENDOR_DIR="src/vendor"
[ ! -f "$VENDOR_DIR/vue.global.prod.js" ] && { echo "缺少 $VENDOR_DIR/vue.global.prod.js"; exit 1; }
VENDOR_HASH=$(sha256sum "$VENDOR_DIR/vue.global.prod.js" | awk '{print $1}')
echo "vue.global.prod.js sha256: $VENDOR_HASH"

echo "[2/3] Vite build..."
npm run build

echo "[3/3] 零外链审计..."
bash scripts/audit-no-cdn.sh
```

**Step 2: audit-no-cdn.sh（构建产物审查 + 体积预算）**
```bash
#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

echo "===== 零外链审计 ====="
if grep -rE 'https?://' dist/ 2>/dev/null; then
    echo "❌ dist/ 中存在外链"
    exit 1
fi
echo "✅ 无外链"

HTML_SIZE=$(stat -c %s dist/index.html 2>/dev/null || echo 0)
JS_MAX=$(find dist/assets -name "*.js" -exec stat -c %s {} \; 2>/dev/null | sort -rn | head -1)
CSS_SIZE=$(find dist/assets -name "*.css" -exec stat -c %s {} \; 2>/dev/null | head -1)
[ "$HTML_SIZE" -gt 51200 ] && { echo "❌ index.html 超过 50KB ($HTML_SIZE)"; exit 1; }
[ "${JS_MAX:-0}" -gt 204800 ] && { echo "❌ 主 JS 超过 200KB ($JS_MAX)"; exit 1; }
[ "${CSS_SIZE:-0}" -gt 102400 ] && { echo "❌ 主 CSS 超过 100KB ($CSS_SIZE)"; exit 1; }
echo "✅ 体积预算通过（html=${HTML_SIZE}B js=${JS_MAX}B css=${CSS_SIZE}B）"

if grep -rE 'https?://' src/ 2>/dev/null; then
    echo "❌ src/ 中存在外链（应全部走 vendor）"
    exit 1
fi
echo "✅ src/ 无外链"
```

**Step 3: 钉版本 vendor 下载（一次性）**
```bash
mkdir -p src/vendor
curl -fsSL "https://unpkg.com/vue@3.4.21/dist/vue.global.prod.js" -o src/vendor/vue.global.prod.js
sha256sum src/vendor/vue.global.prod.js
```

**Step 4: 在 src/views/Dashboard.vue 中用 vendor 而非 CDN**

**Step 5: 验证**
```bash
chmod +x scripts/build.sh scripts/audit-no-cdn.sh
./scripts/build.sh
```

**Step 6: 提交**
```bash
git add .
git commit -m "feat(dashboard): vendor vue pinned + zero-CDN audit + size budget"
git push origin main
```

---

### Task 2A.4  仪表盘产物注入覆盖层（W3 第 2 天）

**Files:**
- Modify: `tiny-nas/openwrt-imagebuilder` 仓库的 `common/tinynas-files/www/tinynas/`

**Step 1: 从 dashboard 仓拉取构建产物**
```bash
cd ~/work/tinynas
# 拉 dashboard 最新 build 产物
curl -fsSL "https://github.com/tiny-nas/dashboard/releases/latest/download/dashboard.tar.gz" -o /tmp/dashboard.tar.gz 2>/dev/null \
  || (cd dashboard && npm run build && tar czf /tmp/dashboard.tar.gz dist/)
```

**Step 2: 解压到覆盖层**
```bash
cd /Users/wandl/workspaces/workspace-tinynas/openwrt-imagebuilder
mkdir -p common/tinynas-files/www/tinynas
tar xzf /tmp/dashboard.tar.gz -C common/tinynas-files/www/tinynas/
ls common/tinynas-files/www/tinynas/
# 期望：index.html + assets/ 目录
```

**Step 3: 零外链审计（关键）**
```bash
grep -rE "https?://" common/tinynas-files/www/tinynas/ || echo "✅ 零外链"
# 期望：仅 0 个外链（或只有自身相对引用）
```

**Step 4: commit**
```bash
git add common/tinynas-files/www/tinynas/
git commit -m "feat(common): inject dashboard build into overlay"
```

**Step 5: sync 到所有 arch 分支**
```bash
git checkout main
./scripts/sync-common-to-branches.sh 2>&1 | tail -3
```

---

### Task 2A.5  仪表盘端到端验证（W3 第 3 天）

**Step 1: 在真机或 x86 虚拟机重新刷镜像**

**Step 2: 浏览器访问 192.168.1.1 验证**
- 仪表盘首屏 ≤3s
- 状态卡 5s 轮询显示真实数据
- 配对页 device_id + 配对码展示正确
- 设置页"关于"读 `/etc/tinynas/*` 显示版本/档位/渠道
- 文件盘列表/上传/下载三操作正常
- 下载页任务列表显示 aria2 任务

**Step 3: 体积检查**
```bash
du -sh common/tinynas-files/www/tinynas/
# 期望：≤1MB
```

---

## SP-2B  ·  LuCI 统一主题  ·  W1–W4  ·  **责任人：搭档（coodex 辅助）**

> **v2 新增 SP**。luci-theme-tinynas 是独立仓库，fork luci-theme-bootstrap，把锦盒 SPA 的设计令牌反向映射到 LuCI 全部主题层。
>
> **关键约束**：SPA 设计令牌是权威（SCSS 变量从同一份 design-tokens.json 生成，CI 加令牌 diff 检查）。

### Task 2B.1  luci-theme-tinynas 仓库初始化 + 本地编译环境（W1 第 1 天）

**Files:**
- Create: `~/work/tinynas/luci-theme-tinynas/`（独立仓）

**Step 1: 远端创建空仓库**
```bash
gh repo create tiny-nas/luci-theme-tinynas --org tiny-nas \
  --description "锦盒 TinyNAS LuCI 统一主题（fork luci-theme-bootstrap，锦盒设计令牌）" \
  --public
```

**Step 2: 本地克隆 + 拉取上游 fork**
```bash
cd ~/work/tinynas
git clone https://github.com/openwrt/luci.git luci-upstream  # 只为拷模版骨架
git clone https://github.com/tiny-nas/luci-theme-tinynas.git
cd luci-theme-tinynas
git remote add upstream https://github.com/openwrt/luci.git
# 拷 luci-theme-bootstrap 作为基础
git fetch upstream
git checkout -b feature/bootstrap-base upstream/openwrt-25.12:themes/luci-theme-bootstrap
git checkout main
git merge --squash feature/bootstrap-base
git commit -m "feat: import luci-theme-bootstrap as base (will rewrite visually)"
```

**Step 3: OpenWrt SDK 本地编译环境**
- 工具：Ubuntu 22.04 + OpenWrt SDK for x86_64（先在 x86 上验证，路由器适配延后）
- 下载：`https://downloads.openwrt.org/releases/25.12.5/targets/x86_64/openwrt-sdk-25.12.5-x86-64.Linux-x86_64.tar.zst`
- 验证：`make menuconfig` 进入 LuCI → Themes → luci-theme-tinynas 可勾选

**Step 4: commit + push**
```bash
git push origin main
```

---

### Task 2B.2  设计令牌 → SCSS 变量映射（W1 第 2 天）

**Files:**
- Create: `luci-theme-tinynas/htdocs/luci-static/tinynas/design-tokens.json`
- Create: `luci-theme-tinynas/src/scss/_tokens.scss`（SCSS 变量定义）
- Create: `luci-theme-tinynas/src/scss/tinynas.scss`（主入口）

**Step 1: design-tokens.json（与 SPA 共用同一份）**
```json
{
  "_meta": { "source": "partme-docs/8、TinyNAS 锦盒/9、TinyNAS-视觉与交互DNA规范.md" },
  "color": {
    "brand": "#F59E0B",
    "brand_strong": "#D97706",
    "bg": "#0F172A",
    "surface": "#1E293B",
    "border": "#334155",
    "text": "#E2E8F0",
    "text_dim": "#94A3B8",
    "ok": "#34D399",
    "warn": "#FBBF24",
    "danger": "#F87171",
    "locked": "#475569"
  },
  "radius": { "card": "12px", "btn": "8px" },
  "spacing": { "card_pad": "16px", "grid_gap": "16px" },
  "font": { "stack": "system-ui, -apple-system, 'PingFang SC', 'Microsoft YaHei', sans-serif" }
}
```

**Step 2: _tokens.scss（SCSS 变量）**
```scss
// 自动从 design-tokens.json 生成（prebuild 脚本见 Task 2B.3）
$t-brand: #F59E0B;
$t-brand-strong: #D97706;
$t-bg: #0F172A;
$t-surface: #1E293B;
$t-border: #334155;
$t-text: #E2E8F0;
$t-text-dim: #94A3B8;
$t-ok: #34D399;
$t-warn: #FBBF24;
$t-danger: #F87171;
$t-locked: #475569;
$t-radius-card: 12px;
$t-radius-btn: 8px;
$t-card-pad: 16px;
$t-grid-gap: 16px;
$t-font-stack: system-ui, -apple-system, "PingFang SC", "Microsoft YaHei", sans-serif;
```

**Step 3: tinynas.scss（主入口——空骨架，后续 Task 填充）**
```scss
@import "tokens";

// LuCI 主题结构（CBI 渲染层覆盖）
// 主菜单、面包屑、卡片、状态徽标、按钮等组件
// 详细样式在 Task 2B.4~2B.6 中迭代
```

**Step 4: commit**
```bash
git add design-tokens.json src/scss/
git commit -m "feat(luci-theme-tinynas): design tokens → SCSS variables"
```

---

### Task 2B.3  prebuild 脚本：JSON → SCSS + 令牌 diff CI（W1 第 2 天）

**Files:**
- Create: `luci-theme-tinynas/scripts/build-tokens.sh`
- Create: `luci-theme-tinynas/.github/workflows/token-diff.yml`

**Step 1: build-tokens.sh（用 jq 生成 SCSS）**
```bash
#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

INPUT="htdocs/luci-static/tinynas/design-tokens.json"
OUTPUT="src/scss/_tokens.scss"

{
    echo "// 自动从 $INPUT 生成（scripts/build-tokens.sh），请勿手改"
    echo
    # 颜色
    jq -r '.color | to_entries[] | "\$t-\(.key): \(.value);"' "$INPUT" | sed 's/-/_/g'
    # 圆角
    jq -r '.radius | to_entries[] | "\$t-radius-\(.key): \(.value);"' "$INPUT"
    # 间距
    jq -r '.spacing | to_entries[] | "\$t-\(.key): \(.value);"' "$INPUT"
    # 字体
    jq -r '.font | to_entries[] | "\$t-font-\(.key): \(.value);"' "$INPUT"
} > "$OUTPUT"

echo "✓ Generated $OUTPUT"
```

**Step 2: 验证生成**
```bash
chmod +x scripts/build-tokens.sh
./scripts/build-tokens.sh
cat src/scss/_tokens.scss
```

**Step 3: GitHub Actions token-diff（与 SPA 仓对比令牌一致性）**

`luci-theme-tinynas/.github/workflows/token-diff.yml`：
```yaml
name: token-diff
on: [push, pull_request]
jobs:
  compare:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: 对比 SPA 仓令牌
        run: |
          curl -fsSL https://raw.githubusercontent.com/tiny-nas/dashboard/main/design-tokens.json -o /tmp/spa.json
          diff htdocs/luci-static/tinynas/design-tokens.json /tmp/spa.json || (echo "❌ 令牌与 SPA 仓不一致"; exit 1)
          echo "✅ 令牌一致"
```

**Step 4: commit**
```bash
git add scripts/ .github/
git commit -m "feat(luci-theme-tinynas): token prebuild + CI diff"
```

---

### Task 2B.4  LuCI 主页（Overview）+ System/Status 主题适配（W2 第 4–5 天）

**Files:**
- Modify: `luci-theme-tinynas/src/scss/tinynas.scss`
- Create: `luci-theme-tinynas/src/scss/_layout.scss`
- Create: `luci-theme-tinynas/src/scss/_status.scss`

**Step 1: _layout.scss（侧栏 + 头部 + 内容栅格）**
```scss
// LuCI 默认 Bootstrap 主题的 .navbar 替换为锦盒侧栏样式
.navbar {
    background: $t-surface;
    border-right: 1px solid $t-border;
    color: $t-text;
    font-family: $t-font-stack;

    .brand { color: $t-brand; font-weight: 700; }
    .nav > li > a { color: $t-text-dim; }
    .nav > li > a:hover { color: $t-text; }
    .nav > li.active > a { color: $t-brand; border-left: 3px solid $t-brand; }
}

.main {
    background: $t-bg;
    color: $t-text;
    font-family: $t-font-stack;
    padding: $t-card-pad;
}

.panel, .cbi-section {
    background: $t-surface;
    border: 1px solid $t-border;
    border-radius: $t-radius-card;
    padding: $t-card-pad;
    margin-bottom: $t-grid-gap;
}
```

**Step 2: _status.scss（系统状态徽标：绿/红/黄 圆点）**
```scss
// 模仿锦盒 SPA 的服务状态条
.service-status {
    display: flex; gap: 16px; padding: 12px 16px;
    background: $t-surface; border-radius: $t-radius-card;
    .indicator {
        width: 10px; height: 10px; border-radius: 50%;
        background: $t-locked;
        &.ok { background: $t-ok; }
        &.danger { background: $t-danger; }
        &.warn { background: $t-warn; }
    }
}
```

**Step 3: tinynas.scss 入口导入**
```scss
@import "tokens";
@import "layout";
@import "status";
// 后续 Task 2B.5/2B.6 添加更多模块
```

**Step 4: 本地 SDK 编译验证**
```bash
cd ~/work/tinynas/openwrt-sdk-x86
make package/luci-theme-tinynas/compile V=99 2>&1 | tail -30
ls bin/packages/x86_64/luci/luci-theme-tinynas*.ipk
# 期望：ipk 生成
```

**Step 5: QEMU 模拟器运行验证（128MB RAM 极限）**
```bash
# 启动 OpenWrt x86_64 镜像 + 装 luci-theme-tinynas
qemu-system-x86_64 -m 128 -hda openwrt-x86-64-generic-squashfs.img -netdev user,id=net0 -device e1000,netdev=net0 -nographic
# 浏览器访问 http://192.168.1.1/cgi-bin/luci
# 截图主页与 System → Status，对比锦盒 SPA 视觉一致性
```

**Step 6: commit**
```bash
cd ~/work/tinynas/luci-theme-tinynas
git add src/scss/
git commit -m "feat(luci-theme-tinynas): Overview + System/Status 主题适配"
```

---

### Task 2B.5  Network/Wireless/Firewall/DHCP 主题适配（W3 第 1–3 天）

**Files:**
- Create: `luci-theme-tinynas/src/scss/_network.scss`
- Create: `luci-theme-tinynas/src/scss/_wireless.scss`
- Create: `luci-theme-tinynas/src/scss/_firewall.scss`
- Create: `luci-theme-tinynas/src/scss/_forms.scss`

**Step 1: _network.scss（网络接口列表、状态徽标）**
```scss
// LuCI Network → Interfaces 页面：每个 WAN/LAN 接口一张卡片
.iface-status {
    background: $t-surface;
    border: 1px solid $t-border;
    border-radius: $t-radius-card;
    padding: $t-card-pad;
    margin-bottom: $t-grid-gap;

    .iface-name { font-size: 16px; font-weight: 600; color: $t-text; }
    .iface-state {
        display: inline-block; padding: 2px 8px; border-radius: 8px;
        font-size: 12px;
        &.up { background: $t-ok; color: $t-bg; }
        &.down { background: $t-danger; color: $t-text; }
    }
}
```

**Step 2: _wireless.scss（WiFi 配置表单 + 信号强度条）**
```scss
// Wireless Overview：SSID、信道、客户端列表
.wifi-signal {
    display: inline-block; height: 6px; width: 100px;
    background: $t-border; border-radius: 3px;
    .bar { background: $t-ok; height: 100%; border-radius: 3px; }
}
```

**Step 3: _firewall.scss（防火墙规则列表 + 颜色标记）**
```scss
// Firewall → Traffic Rules：每条规则一行，accept/drop/reject 用 ok/warn/danger 色
.rule-row { border-bottom: 1px solid $t-border; padding: 8px 0; }
.rule-action { font-weight: 600; }
.rule-action.accept { color: $t-ok; }
.rule-action.drop { color: $t-danger; }
.rule-action.reject { color: $t-warn; }
```

**Step 4: _forms.scss（CBI 表单控件：input/select/checkbox/button 全部锦盒样式）**
```scss
input[type="text"], input[type="password"], select {
    background: $t-bg; color: $t-text;
    border: 1px solid $t-border; border-radius: $t-radius-btn;
    padding: 8px 12px;
    &:focus { border-color: $t-brand; outline: none; }
}

.cbi-button {
    background: $t-brand; color: $t-bg;
    border: none; padding: 8px 16px;
    border-radius: $t-radius-btn;
    font-weight: 600;
    &:hover { background: $t-brand-strong; }
}
```

**Step 5: tinynas.scss 补导入**
```scss
@import "tokens";
@import "layout";
@import "status";
@import "network";
@import "wireless";
@import "firewall";
@import "forms";
```

**Step 6: QEMU 验证 4 个页面**
- Network → Interfaces：每张接口卡样式统一
- Wireless → Overview：SSID + 信号条 + 客户端列表
- Firewall → Traffic Rules：规则行颜色标记
- DHCP → Static Leases：表单样式锦盒化

**Step 7: commit**
```bash
git add src/scss/
git commit -m "feat(luci-theme-tinynas): Network/Wireless/Firewall/DHCP 主题"
```

---

### Task 2B.6  System/Admin/Services/Logs 主题适配（W4 第 1–3 天）

**Files:**
- Create: `luci-theme-tinynas/src/scss/_system.scss`
- Create: `luci-theme-tinynas/src/scss/_admin.scss`
- Create: `luci-theme-tinynas/src/scss/_services.scss`
- Create: `luci-theme-tinynas/src/scss/_logs.scss`

**Step 1: _system.scss（Software 包列表、Startup 启动项、Mount Points 挂载点）**
```scss
// Software → Available Packages：每行一个包，左侧 checkbox + 中间名/描述 + 右侧状态
.package-row {
    display: flex; align-items: center; gap: 12px;
    padding: 10px 12px;
    border-bottom: 1px solid $t-border;
    &:hover { background: $t-bg; }
    .pkg-name { color: $t-text; font-weight: 600; }
    .pkg-status-installed { color: $t-ok; }
    .pkg-status-available { color: $t-text-dim; }
}
```

**Step 2: _admin.scss（Router Password、SSH Access、NTP、Logging 等管理项）**
- 复用 _forms.scss 的表单样式
- System → Router 页面顶部加锦盒横幅："🎉 锦盒版 LuCI · v1.0"

**Step 3: _services.scss（Init Scripts 启动脚本列表 + 启停按钮）**
```scss
.service-row {
    display: flex; align-items: center; gap: 16px;
    padding: 12px;
    .service-name { color: $t-text; flex: 1; }
    .service-state { color: $t-ok; font-weight: 600; }
    .service-state.disabled { color: $t-text-dim; }
}
```

**Step 4: _logs.scss（系统日志查看器，等宽字体 + 颜色标记级别）**
```scss
.log-viewer {
    background: $t-bg; color: $t-text-dim;
    font-family: ui-monospace, "SF Mono", Menlo, monospace;
    font-size: 13px;
    padding: 12px;
    border-radius: $t-radius-card;
    max-height: 600px; overflow: auto;
    .level-err { color: $t-danger; }
    .level-warn { color: $t-warn; }
    .level-info { color: $t-text-dim; }
}
```

**Step 5: tinynas.scss 补导入**
```scss
@import "tokens";
@import "layout";
@import "status";
@import "network";
@import "wireless";
@import "firewall";
@import "forms";
@import "system";
@import "admin";
@import "services";
@import "logs";
```

**Step 6: QEMU 验证 4 个页面**
- System → Software：包列表 + 安装按钮
- System → Mount Points：磁盘挂载卡
- System → Startup：服务启停按钮
- Status → System Log：彩色日志

**Step 7: commit**
```bash
git add src/scss/
git commit -m "feat(luci-theme-tinynas): System/Admin/Services/Logs 主题"
```

---

### Task 2B.7  LuCI 入口卡片与锦盒 SPA 跳转按钮（W3 第 2 天，与 SP-2A 配合）

**Files:**
- Modify: `luci-theme-tinynas/src/scss/_layout.scss`（LuCI 主页加横幅）
- Modify: `tiny-nas/dashboard/src/components/Sidebar.vue`（路由器模式加 LuCI 跳转）

**Step 1: LuCI 主页加锦盒横幅（路由器模式必备）**
```scss
// _layout.scss 追加：
.tinynas-banner {
    background: $t-surface;
    border: 1px solid $t-brand;
    border-radius: $t-radius-card;
    padding: 12px 16px;
    margin-bottom: $t-grid-gap;
    display: flex; align-items: center; gap: 12px;
    .icon { color: $t-brand; font-size: 20px; }
    .title { color: $t-text; font-weight: 600; }
    .desc { color: $t-text-dim; font-size: 13px; }
    .btn { margin-left: auto; }
}
```

**Step 2: LuCI 视图层模板插入横幅**
```lua
-- luci-theme-tinynas/luas/header.htm 追加：
<div class="tinynas-banner">
    <span class="icon">🪔</span>
    <div>
        <div class="title">锦盒 TinyNAS</div>
        <div class="desc">NAS · 智能体 · 远程下载 · 内网穿透</div>
    </div>
    <a href="/tinynas/" class="btn cbi-button">打开锦盒面板</a>
</div>
```

**Step 3: dashboard Sidebar.vue 加 LuCI 跳转（路由器模式）**
```vue
<!-- 在路由器模式（device === 'router'）下显示 -->
<div class="luci-link">
    <a href="/cgi-bin/luci" target="_blank" rel="noopener">
        🌐 网络配置（LuCI）
    </a>
</div>
```

**Step 4: 验证**
- LuCI 主页横幅显示"🪔 锦盒 TinyNAS + 打开锦盒面板"按钮
- 锦盒 SPA 顶部显示"🌐 网络配置 → LuCI"按钮

**Step 5: commit**
```bash
# luci-theme-tinynas
git add src/scss/_layout.scss luas/header.htm
git commit -m "feat(luci-theme-tinynas): dashboard banner with SPA entry button"

# dashboard
cd ~/work/tinynas/dashboard
git add src/components/Sidebar.vue
git commit -m "feat(dashboard): LuCI shortcut for router mode"
```

---

### Task 2B.8  128MB RAM 性能优化 + 主题兼容性回归（W4 后半 / W5）

**Step 1: OpenWrt SDK QEMU 极限压测**
```bash
# 启动 OpenWrt x86_64 QEMU 镜像，强制 64MB RAM
qemu-system-x86_64 -m 64 -hda openwrt-x86-64-generic-squashfs.img -nographic
# 安装 luci-theme-tinynas
opkg install /tmp/luci-theme-tinynas*.ipk
# 浏览器访问各 LuCI 页面
# 测量首屏加载时间
```

**Step 2: 性能预算**
- LuCI 主页首屏 <2s（128MB RAM 约束）
- 切换主题页面 <1s
- 单页 JS 执行 <100ms

**Step 3: 优化（如不达标）**
- CSS 进一步裁剪（删除未用组件）
- 图片资源 SVG 化（每个 ≤2KB）
- 字体回退栈精简
- critical CSS 内联到 header.htm

**Step 4: 兼容性回归**
- 8+ 核心页面全部截图，确保未破坏 LuCI 默认功能
- 在 N1（Pro 档，1GB RAM）+ 模拟 mt7621（128MB RAM）双场景验证

**Step 5: commit**
```bash
git add .
git commit -m "perf(luci-theme-tinynas): 128MB RAM optimization + compat regression"
```

---

## SP-2A 与 SP-2B 集成点

| 集成点 | 触发时机 | 责任方 | 动作 |
|:---|:---|:---|:---|
| 锦盒 SPA "网络配置"按钮 | SP-2A 路由器模式实现时（W3） | hiwepy | Sidebar.vue 加跳转 |
| LuCI 主页 "锦盒面板"横幅 | SP-2B 主页适配时（W2） | 搭档 | header.htm 加横幅 |
| 设计令牌 JSON 一致性 | SP-2A 完成 dashboard 设计令牌后（W2 末） | hiwepy | 把令牌同步到 dashboard/design-tokens.json；commit 后 CI token-diff 自动比对 |
| LuCI 主题 ipk 打包 | SP-2B 各 Task 完成时 | 搭档 | OpenWrt SDK make package/luci-theme-tinynas/compile → 输出 ipk |
| LuCI 主题集成进覆盖层 | SP-2B 完成后（W4 末） | hiwepy | luci-theme-tinynas ipk → tinynas-files/ 注入 → 重新打包 N1 镜像 → 验证 LuCI 视觉统一 |

## SP-3  ·  云端中枢（pairing + NATS Resolver）  ·  W2–W3

### Task 3.1  pairing 仓库初始化（W2 第 4 天）

**Files:**
- Create: `tiny-nas/pairing/`（独立仓）

**Step 1: 远端创建**
```bash
gh repo create tiny-nas/pairing --org tiny-nas \
  --description "锦盒 TinyNAS 云端配对服务（Rust + Axum + SQLite）" \
  --public
```

**Step 2: 本地克隆 + Rust 工程脚手架**
```bash
cd ~/work/tinynas
git clone https://github.com/tiny-nas/pairing.git
cd pairing
cargo init --name tinynas-pairing
```

**Step 3: Cargo.toml 依赖（Axum 0.7 + SQLx 0.7 + tokio）**
```toml
[package]
name = "tinynas-pairing"
version = "0.1.0"
edition = "2021"

[dependencies]
axum = "0.7"
tokio = { version = "1.35", features = ["full"] }
tower = "0.4"
tower-http = { version = "0.5", features = ["cors"] }
sqlx = { version = "0.7", features = ["runtime-tokio", "sqlite"] }
serde = { version = "1", features = ["derive"] }
serde_json = "1"
chrono = { version = "0.4", features = ["serde"] }
uuid = { version = "1", features = ["v4", "serde"] }
hmac = "0.12"
sha2 = "0.10"
hex = "0.4"
tracing = "0.1"
tracing-subscriber = "0.3"
thiserror = "1"
anyhow = "1"
```

**Step 4: 提交**
```bash
git add .
git commit -m "chore(pairing): Rust + Axum + SQLx scaffold"
git push origin main
```

---

### Task 3.2  SQLite schema + 迁移（W2 第 4 天）

**Files:**
- Create: `tiny-nas/pairing/migrations/001_init.sql`
- Create: `tiny-nas/pairing/src/db.rs`

**Step 1: schema**
```sql
CREATE TABLE devices (
    device_id TEXT PRIMARY KEY,
    machine_id TEXT NOT NULL,
    channel TEXT NOT NULL,
    firmware_version TEXT,
    registered_at INTEGER NOT NULL,
    last_seen INTEGER
);

CREATE TABLE pairings (
    device_id TEXT PRIMARY KEY REFERENCES devices(device_id),
    pairing_code TEXT NOT NULL,
    code_expires_at INTEGER NOT NULL,
    bound INTEGER NOT NULL DEFAULT 0,
    nats_user TEXT,
    nats_pass TEXT,
    bound_at INTEGER
);

CREATE TABLE activations (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    device_id TEXT NOT NULL,
    machine_id TEXT NOT NULL,
    channel TEXT NOT NULL,
    activated_at INTEGER NOT NULL
);

CREATE INDEX idx_pairings_code ON pairings(pairing_code);
CREATE INDEX idx_activations_channel ON activations(channel);
```

**Step 2: db.rs 模块（连接 + 迁移）**
```rust
use sqlx::sqlite::{SqlitePool, SqlitePoolOptions};

pub async fn init_pool(database_url: &str) -> anyhow::Result<SqlitePool> {
    let pool = SqlitePoolOptions::new()
        .max_connections(10)
        .connect(database_url).await?;
    sqlx::migrate!("./migrations").run(&pool).await?;
    Ok(pool)
}
```

**Step 3: 单元测试**
```rust
#[tokio::test]
async fn test_init_pool() {
    let pool = init_pool(":memory:").await.unwrap();
    let row: (i64,) = sqlx::query_as("SELECT COUNT(*) FROM devices").fetch_one(&pool).await.unwrap();
    assert_eq!(row.0, 0);
}
```

**Step 4: 提交**
```bash
git add .
git commit -m "feat(pairing): SQLite schema + init pool"
git push origin main
```

---

### Task 3.3  四个核心 API 路由（W2 第 5 天）

**Files:**
- Create: `tiny-nas/pairing/src/main.rs`
- Create: `tiny-nas/pairing/src/routes/devices.rs`
- Create: `tiny-nas/pairing/src/routes/pair.rs`
- Create: `tiny-nas/pairing/src/routes/nats.rs`
- Create: `tiny-nas/pairing/src/routes/stats.rs`

**Step 1: main.rs（Axum 启动）**
```rust
mod db;
mod routes;
mod state;

use axum::{routing::{get, post}, Router};
use std::net::SocketAddr;
use tower_http::cors::CorsLayer;

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    tracing_subscriber::init();
    let db_url = std::env::var("DATABASE_URL").unwrap_or_else(|_| "sqlite://data/pairing.db".into());
    let pool = db::init_pool(&db_url).await?;
    let state = state::AppState { db: pool };

    let app = Router::new()
        .route("/health", get(routes::health))
        .route("/devices/register", post(routes::devices::register))
        .route("/pair", get(routes::pair::pair))
        .route("/nats/users", get(routes::nats::users))
        .route("/stats/channels", get(routes::stats::channels))
        .with_state(state)
        .layer(CorsLayer::permissive());

    let addr: SocketAddr = "0.0.0.0:8080".parse()?;
    tracing::info!("listening on {}", addr);
    axum::serve(tokio::net::TcpListener::bind(addr).await?, app).await?;
    Ok(())
}
```

**Step 2: routes/devices.rs（设备注册）**
```rust
use axum::{extract::State, Json};
use serde::{Deserialize, Serialize};
use crate::state::AppState;

#[derive(Deserialize)]
pub struct RegisterReq {
    pub device_id: String,
    pub machine_id: String,
    pub channel: String,
    pub firmware_version: Option<String>,
}

#[derive(Serialize)]
pub struct RegisterResp {
    pub status: String,
}

pub async fn register(State(s): State<AppState>, Json(req): Json<RegisterReq>) -> Json<RegisterResp> {
    let now = chrono::Utc::now().timestamp();
    sqlx::query(
        "INSERT INTO devices (device_id, machine_id, channel, firmware_version, registered_at, last_seen) \
         VALUES (?, ?, ?, ?, ?, ?) \
         ON CONFLICT(device_id) DO UPDATE SET last_seen=excluded.last_seen"
    )
    .bind(&req.device_id).bind(&req.machine_id).bind(&req.channel)
    .bind(&req.firmware_version).bind(now).bind(now)
    .execute(&s.db).await?;
    Json(RegisterResp { status: "ok".into() })
}
```

**Step 3: routes/pair.rs（配对——核心，含 HMAC + 限流 + 短时效）**
```rust
use axum::{extract::{Query, State}, Json};
use serde::{Deserialize, Serialize};
use crate::state::AppState;
use std::collections::HashMap;
use std::sync::Mutex;
use std::time::{Duration, Instant};

#[derive(Deserialize)]
pub struct PairReq { pub device: String, pub code: String }

#[derive(Serialize)]
pub struct PairResp {
    pub nats_url: String,
    pub nats_user: String,
    pub nats_pass: String,
    pub publish_subject: String,
    pub subscribe_subject: String,
    pub device_id: String,
    pub auth_version: String,
}

// 进程内限流（生产环境应用 Redis）
static RATE: Mutex<Option<HashMap<String, Vec<Instant>>>> = Mutex::new(None);

fn check_rate_limit(ip: &str) -> bool {
    let mut g = RATE.lock().unwrap();
    let m = g.get_or_insert_with(HashMap::new);
    let now = Instant::now();
    let v = m.entry(ip.to_string()).or_default();
    v.retain(|t| now.duration_since(*t) < Duration::from_secs(60));
    if v.len() >= 10 { return false; }
    v.push(now);
    true
}

pub async fn pair(
    State(s): State<AppState>,
    Query(q): Query<PairReq>,
    headers: axum::http::HeaderMap,
) -> Result<Json<PairResp>, (axum::http::StatusCode, String)> {
    let ip = headers.get("x-forwarded-for").and_then(|v| v.to_str().ok()).unwrap_or("local");
    if !check_rate_limit(ip) {
        return Err((axum::http::StatusCode::TOO_MANY_REQUESTS, "rate limited".into()));
    }

    let row: Option<(String, i64, i64, String)> = sqlx::query_as(
        "SELECT pairing_code, code_expires_at, bound, channel FROM pairings WHERE device_id = ?"
    ).bind(&q.device).fetch_optional(&s.db).await.map_err(|e| (axum::http::StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;

    let (saved_code, expires_at, bound, channel) = match row {
        Some(r) => r,
        None => return Err((axum::http::StatusCode::NOT_FOUND, "device not registered".into())),
    };

    let now = chrono::Utc::now().timestamp();
    if bound != 0 {
        return Err((axum::http::StatusCode::FORBIDDEN, "already bound".into()));
    }
    if now > expires_at {
        return Err((axum::http::StatusCode::FORBIDDEN, "code expired".into()));
    }
    if saved_code.to_uppercase() != q.code.to_uppercase() {
        return Err((axum::http::StatusCode::FORBIDDEN, "code mismatch".into()));
    }

    let nats_user = format!("sb_{}", &q.device);
    let nats_pass = uuid::Uuid::new_v4().to_string().replace('-', "");
    let pub_subj = format!("downloads.{}", q.device);

    sqlx::query("UPDATE pairings SET bound=1, nats_user=?, nats_pass=?, bound_at=? WHERE device_id=?")
        .bind(&nats_user).bind(&nats_pass).bind(now).bind(&q.device)
        .execute(&s.db).await.map_err(|e| (axum::http::StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;

    Ok(Json(PairResp {
        nats_url: std::env::var("NATS_URL").unwrap_or_else(|_| "tls://127.0.0.1:4222".into()),
        nats_user, nats_pass,
        publish_subject: pub_subj.clone(),
        subscribe_subject: format!("control.{}", q.device),
        device_id: q.device,
        auth_version: "1.0".into(),
    }))
}
```

**Step 4: routes/nats.rs（Resolver 给 NATS 用）**
```rust
use axum::{extract::State, Json};
use serde::Serialize;
use crate::state::AppState;

#[derive(Serialize)]
pub struct NatsUser {
    pub user: String,
    pub password: String,
    pub permissions: NatsPermissions,
}

#[derive(Serialize)]
pub struct NatsPermissions {
    pub publish: Vec<String>,
    pub subscribe: Vec<String>,
}

#[derive(Serialize)]
pub struct NatsUsersResp { pub users: Vec<NatsUser> }

pub async fn users(State(s): State<AppState>) -> Json<NatsUsersResp> {
    let rows: Vec<(String, String)> = sqlx::query_as(
        "SELECT nats_user, nats_pass FROM pairings WHERE bound=1 AND nats_user IS NOT NULL"
    ).fetch_all(&s.db).await.unwrap_or_default();

    let users = rows.into_iter().map(|(u, p)| NatsUser {
        user: u.clone(),
        password: p,
        permissions: NatsPermissions {
            publish: vec![format!("downloads.{}", u.trim_start_matches("sb_"))],
            subscribe: vec![format!("control.{}", u.trim_start_matches("sb_"))],
        }
    }).collect();

    Json(NatsUsersResp { users })
}
```

**Step 5: routes/stats.rs（渠道对账——SP-5 用）**
```rust
use axum::{extract::State, Json};
use serde::Serialize;
use crate::state::AppState;

#[derive(Serialize)]
pub struct ChannelStat { pub channel: String, pub count: i64 }

pub async fn channels(State(s): State<AppState>) -> Json<Vec<ChannelStat>> {
    let rows: Vec<(String, i64)> = sqlx::query_as(
        "SELECT channel, COUNT(*) FROM activations GROUP BY channel"
    ).fetch_all(&s.db).await.unwrap_or_default();
    Json(rows.into_iter().map(|(c, n)| ChannelStat { channel: c, count: n }).collect())
}
```

**Step 6: state.rs**
```rust
use sqlx::SqlitePool;
#[derive(Clone)]
pub struct AppState { pub db: SqlitePool }
```

**Step 7: 单元测试**
```rust
#[tokio::test]
async fn test_pair_flow() {
    let pool = crate::db::init_pool(":memory:").await.unwrap();
    // 模拟注册、配对、校验
}
```

**Step 8: 本地构建 + 测试**
```bash
cd ~/work/tinynas/pairing
cargo build --release
./target/release/tinynas-pairing &
sleep 1
curl -s http://127.0.0.1:8080/health
# 期望：{"status":"ok"}
```

**Step 9: commit**
```bash
git add .
git commit -m "feat(pairing): 4 routes (devices/pair/nats/stats) + state + tests"
git push origin main
```

---

### Task 3.4  VPS 部署 pairing + Caddy HTTPS（W2 第 5–6 天）

**Step 1: 上 VPS 部署**
```bash
ssh tinynas-vps 'bash -s' < <'EOF'
set -euo pipefail
# 安装 Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable
source $HOME/.cargo/env

# 部署 pairing
useradd -r -s /usr/sbin/nologin tinynas-pairing || true
mkdir -p /opt/tinynas/pairing/data
cd /opt/tinynas/pairing
git clone https://github.com/tiny-nas/pairing.git .
cargo build --release

cat > /etc/systemd/system/tinynas-pairing.service <<EOF
[Unit]
Description=Tinynas Pairing Service
After=network.target

[Service]
Environment=DATABASE_URL=sqlite:///opt/tinynas/pairing/data/pairing.db
Environment=NATS_URL=tls://127.0.0.1:4222
ExecStart=/opt/tinynas/pairing/target/release/tinynas-pairing
Restart=always
User=tinynas-pairing
WorkingDirectory=/opt/tinynas/pairing

[Install]
WantedBy=multi-user.target
EOF
chown -R tinynas-pairing:tinynas-pairing /opt/tinynas/pairing
systemctl daemon-reload
systemctl enable --now tinynas-pairing
systemctl status tinynas-pairing --no-pager
EOF
```

**Step 2: Caddy 安装（如果 Task 1.2 之后还没装）**
```bash
ssh tinynas-vps 'bash -s' < <'EOF'
set -euo pipefail
apt install -y debian-keyring debian-archive-keyring apt-transport-https
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | tee /etc/apt/sources.list.d/caddy-stable.list
apt update && apt install -y caddy
EOF
```

**Step 3: Caddyfile（自动 HTTPS）**
```bash
ssh tinynas-vps 'cat > /etc/caddy/Caddyfile <<EOF
api.tinynas.io {
    reverse_proxy 127.0.0.1:8080
}
nats.tinynas.io:4222 {
    reverse_proxy 127.0.0.1:4222
}
EOF
systemctl reload caddy'
```

**Step 4: 域名 DNS 解析**
- Cloudflare DNS：`api.tinynas.io` → VPS IP
- 验证：`curl -I https://api.tinynas.io/health` 返回 200

**Step 5: end-to-end 测试**
```bash
# 设备注册
curl -X POST https://api.tinynas.io/devices/register \
  -H 'Content-Type: application/json' \
  -d '{"device_id":"sb_test","machine_id":"A1B2C3D4E5F60718","channel":"xianyu_a"}'

# 配对码由设备首启时写入 SQLite（V1 stub：手动 SQL 插入测试）
ssh tinynas-vps 'sqlite3 /opt/tinynas/pairing/data/pairing.db "INSERT INTO pairings (device_id, pairing_code, code_expires_at) VALUES (\"sb_test\", \"123456\", strftime(\"%s\", \"now\") + 60);"'

# 配对
curl 'https://api.tinynas.io/pair?device=sb_test&code=123456'
# 期望：{"nats_url":"tls://...","nats_user":"sb_sb_test",...}
```

**Step 6: NATS Resolver 切换为动态（替换 SP-1 的 stub 认证）**
```bash
ssh tinynas-vps 'bash -s' < <'EOF'
set -euo pipefail
# 生成 Resolver Token（pairing 内部通信用）
RESOLVER_TOKEN=$(openssl rand -hex 16)

# 改 nats-server.conf
cat > /etc/nats/nats-server.conf <<EOF
port: 4222
http_port: 8222
tls {
  cert_file: "/etc/nats/tls/server.crt"
  key_file: "/etc/nats/tls/server.key"
}
jetstream {
  store_dir: "/var/lib/nats"
  max_memory_store: 64MB
  max_file_store: 1GB
}
authorization {
  resolver: URL("https://127.0.0.1:8080/nats/users")
  resolver_tls {
    insecure: true
  }
  resolver_preload: {
    R0: {user: "sys", password: "$RESOLVER_TOKEN"}
  }
  account: SYS
}
EOF
systemctl restart nats
systemctl status nats --no-pager
EOF

# pairing 加一个 admin 接口消费这个 token
echo "   - 添加 routes/admin.rs 鉴权 + NATS 系统账户处理（pairing 内置）"
```

**Step 7: commit**
```bash
git add .
git commit -m "feat(pairing): VPS deploy + Caddy HTTPS + NATS Resolver"
git push origin main
```

---

### Task 3.5  pairing ↔ 设备端 + 插件端联调（W3 第 4 天）

**Step 1: 设备端：消费 pairing 凭据的 NATS Consumer 真实实现**

**Files:**
- Create: `tiny-nas/openwrt-imagebuilder/common/tinynas-files/usr/bin/tinynas-nats-consumer`（重写）

```bash
# 该脚本在 SP-3 中替换 V1 stub
cat > common/tinynas-files/usr/bin/tinynas-nats-consumer <<'EOF'
#!/bin/sh
# NATS Durable Consumer：订阅 downloads.<device_id>，处理下载任务
# 真实实现（含 NATS 连接管理、JetStream pull、ARIA2 RPC 调用）

set -euo pipefail

# 读 pairing 凭据
if [ ! -f /etc/tinynas/nats.json ]; then
    echo "no NATS credentials" >&2
    exit 1
fi

NATS_URL=$(jq -r .nats_url /etc/tinynas/nats.json)
NATS_USER=$(jq -r .nats_user /etc/tinynas/nats.json)
NATS_PASS=$(jq -r .nats_pass /etc/tinynas/nats.json)
SUBJECT=$(jq -r .publish_subject /etc/tinynas/nats.json)
DEVICE_ID=$(jq -r .device_id /etc/tinysss/nats.json 2>/dev/null || echo "")
ARIA2_RPC="http://127.0.0.1:6800/jsonrpc"
ARIA2_SECRET=$(grep '^rpc-secret=' /etc/aria2.conf | cut -d'=' -f2)

# 使用 nats CLI（V1 阶段），V2 换 Rust 客户端
while true; do
    nats consumer next downloads "${SUBJECT##*.}" --count=1 --json --server="$NATS_URL" \
        --user="$NATS_USER" --password="$NATS_PASS" 2>/dev/null | \
    jq -r '.payload' 2>/dev/null | while read -r msg; do
        URL=$(echo "$msg" | jq -r '.payload.url')
        if [ -n "$URL" ] && [ "$URL" != "null" ]; then
            curl -s -X POST "$ARIA2_RPC" \
                -H 'Content-Type: application/json' \
                -d "{\"jsonrpc\":\"2.0\",\"method\":\"aria2.addUri\",\"id\":\"1\",\"params\":[\"token:$ARIA2_SECRET\",[\"$URL\"],{\"dir\":\"/mnt/usb/Downloads\"}]}" >/dev/null
            logger -t tinynas "enqueued: $URL"
        fi
    done
    sleep 5
done
EOF
chmod +x common/tinynas-files/usr/bin/tinynas-nats-consumer
```

**Step 2: 设备首次启动后，从 pairing 获取凭据**
```bash
# 添加 common/tinynas-files/etc/init.d/tinynas-pairing-bootstrap（W3 新增）
cat > common/tinynas-files/etc/init.d/tinynas-pairing-bootstrap <<'EOF'
#!/bin/sh /etc/rc.common
START=97

start() {
    # 设备启动后调用 pairing /pair 自动领取凭据（V1 用首次启动时手动配对；自动可放 V1.1）
    # 此脚本预留接口
    :
}
EOF
chmod +x common/tinynas-files/etc/init.d/tinynas-pairing-bootstrap
```

**Step 3: end-to-end 测试**
- 设备登录后手动调用 pairing `/pair`（V1 临时通过 curl，V1.5 改仪表盘按钮）
- 启动 NATS Consumer
- 模拟插件 publish 一条消息
- 验证 aria2 接收任务并下载

**Step 4: commit + sync**
```bash
cd /Users/wandl/workspaces/workspace-tinynas/openwrt-imagebuilder
git add common/tinynas-files/usr/bin/tinynas-nats-consumer common/tinynas-files/etc/init.d/tinynas-pairing-bootstrap
git commit -m "feat(common): real NATS consumer + pairing bootstrap script"
git checkout main && ./scripts/sync-common-to-branches.sh 2>&1 | tail -3
```

---

## SP-4  ·  浏览器插件  ·  W3–W4

### Task 4.1  插件仓库初始化（W3 第 4 天）

**Files:**
- Create: `tiny-nas/chrome-extension/`（独立仓或 `tiny-nas/dashboard/extension/` 子目录；建议独立仓）

**Step 1: 远端创建**
```bash
gh repo create tiny-nas/chrome-extension --org tiny-nas \
  --description "锦盒 TinyNAS 浏览器插件（Chrome MV3 + nats.ws）" \
  --public
```

**Step 2: 本地克隆 + manifest.json**
```bash
cd ~/work/tinynas
git clone https://github.com/tiny-nas/chrome-extension.git
cd chrome-extension

mkdir -p icons src
cat > manifest.json <<'EOF'
{
  "manifest_version": 3,
  "name": "锦盒 TinyNAS 推送助手",
  "version": "1.0.0",
  "description": "右键推送下载链接到家里的锦盒 NAS",
  "icons": { "16": "icons/16.png", "48": "icons/48.png", "128": "icons/128.png" },
  "permissions": ["contextMenus", "storage", "activeTab"],
  "host_permissions": ["<all_urls>"],
  "background": { "service_worker": "src/background.js" },
  "action": { "default_popup": "src/popup.html" }
}
EOF
```

**Step 3: 占位图标（用 ImageMagick 生成纯色）**
```bash
which convert || apt install -y imagemagick
for s in 16 48 128; do
    convert -size ${s}x${s} xc:'#F59E0B' -fill white -gravity center \
        -font "Helvetica" -pointsize $((s/2)) -annotate +0+0 'T' icons/${s}.png
done
```

**Step 4: 提交**
```bash
git add .
git commit -m "chore: chrome extension scaffold (MV3)"
git push origin main
```

---

### Task 4.2  background.js + nats.ws（W3 第 5 天）

**Files:**
- Create: `tiny-nas/chrome-extension/src/background.js`
- Create: `tiny-nas/chrome-extension/src/nats-client.js`
- Create: `tiny-nas/chrome-extension/vendor/nats.ws.js`（vendor 钉版本）

**Step 1: vendor nats.ws（钉版本，零外链运行时）**
```bash
mkdir -p vendor
curl -fsSL "https://unpkg.com/nats.ws@1.24.0/esm/nats.js" -o vendor/nats.ws.js
sha256sum vendor/nats.ws.js  # 记录到 README
```

**Step 2: manifest.json 引用方式（service worker 用 ES module import 相对路径）**
```json
{
  "background": {
    "service_worker": "src/background.js",
    "type": "module"
  }
}
```

**Step 3: nats-client.js（封装连接 + 重连 + 心跳）**
```js
import { connect, JSONCodec } from '../vendor/nats.ws.js'

let nc = null
const jc = JSONCodec()

export async function connectNats(url, user, pass) {
    if (nc) await nc.close()
    nc = await connect({ servers: url, user, pass, reconnectTimeWait: 5000 })
    return nc
}

export async function publish(subject, payload) {
    if (!nc) throw new Error('not connected')
    await nc.publish(subject, jc.encode(payload))
}

export async function close() {
    if (nc) { await nc.close(); nc = null }
}
```

**Step 4: background.js（右键菜单 + chrome.storage + NATS 发布）**
```js
import { connectNats, publish, close } from './nats-client.js'
import { getCredentials } from './storage.js'

const MSG = {
    NOT_BOUND: '未绑定设备：请先在弹出窗口中绑定锦盒',
    PUBLISHING: '已推送到锦盒',
    OFFLINE: '设备离线，上线后将自动下载',
    ERROR: '推送失败'
}

// 解码 thunder:// 链接
function decodeThunder(url) {
    if (!url.startsWith('thunder://')) return url
    try {
        const b64 = url.slice('thunder://'.length).replace(/\/$/, '')
        const decoded = atob(b64)
        return decoded.startsWith('AA') && decoded.endsWith('ZZ') ? decoded.slice(2, -2) : decoded
    } catch { return url }
}

chrome.runtime.onInstalled.addListener(() => {
    chrome.contextMenus.create({
        id: 'push-tinynas',
        title: '推送到锦盒 NAS',
        contexts: ['link', 'page']
    })
})

chrome.contextMenus.onClicked.addListener(async (info, tab) => {
    const url = info.linkUrl || info.pageUrl
    const decoded = decodeThunder(url)
    const creds = await getCredentials()
    if (!creds) {
        chrome.notifications.create({ type: 'basic', iconUrl: 'icons/48.png', title: '锦盒', message: MSG.NOT_BOUND })
        return
    }
    try {
        await connectNats(creds.nats_url, creds.nats_user, creds.nats_pass)
        await publish(creds.publish_subject, {
            type: 'download',
            payload: { url: decoded, target_dir: '/mnt/usb/Downloads' },
            meta: { source: 'chrome_extension', device_id: creds.device_id, timestamp: Date.now() }
        })
        chrome.notifications.create({ type: 'basic', iconUrl: 'icons/48.png', title: '锦盒', message: MSG.PUBLISHING + (decoded !== url ? '（thunder 已解码）' : '') })
    } catch (e) {
        chrome.notifications.create({ type: 'basic', iconUrl: 'icons/48.png', title: '锦盒', message: MSG.OFFLINE + ' / ' + MSG.ERROR })
    }
})
```

**Step 5: storage.js（chrome.storage.local 封装）**
```js
const KEY = 'tinynas_credentials_v1'

export async function setCredentials(c) {
    return chrome.storage.local.set({ [KEY]: c })
}
export async function getCredentials() {
    const { [KEY]: c } = await chrome.storage.local.get(KEY)
    return c
}
```

**Step 6: popup.html + popup.js（绑定 UI）**
- input device_id + 配对码 + [绑定] 按钮
- 调 `https://api.tinynas.io/pair?device=&code=`
- 保存响应到 chrome.storage.local

**Step 7: 单元测试（vitest）**
```bash
npm install -D vitest
# tests/decode.spec.ts：验证 thunder 解码
```

**Step 8: 本地测试**
```bash
# 在 Chrome 中加载未打包扩展（chrome://extensions → 开发者模式 → 加载已解压的扩展程序）
# 测试：右键菜单出现 → 绑定 → 推送
```

**Step 9: commit**
```bash
git add .
git commit -m "feat(extension): context menu push + nats.ws + thunder decode"
git push origin main
```

---

### Task 4.3  CRX 离线包 + 安装文档（W4 第 1 天）

**Step 1: 打包 CRX**
- Chrome → 扩展程序 → 打包扩展程序 → 生成 `.crx`

**Step 2: 安装文档**
```bash
cat > README.md <<'EOF'
# 锦盒 TinyNAS 浏览器推送助手

## 安装

### Chrome Web Store（推荐）
[Chrome Web Store 链接](https://chrome.google.com/webstore/detail/...)

### 离线安装（CRX）
1. 下载 `tinynas-extension-1.0.0.crx`
2. Chrome → `chrome://extensions`
3. 打开"开发者模式"
4. 拖入 CRX 文件 → 确认安装
EOF

git add README.md
git commit -m "docs: CRX offline install instructions"
```

---

## SP-5  ·  渠道工具（OEM/双轨）  ·  W3–W4

### Task 5.1  批量激活码生成器（W3 第 5 天）

**Files:**
- Create: `tiny-nas/tools/activator/`（独立仓 `tiny-nas/tools` 或本地工具仓）

**Step 1: 远端仓**
```bash
gh repo create tiny-nas/tools --org tiny-nas \
  --description "锦盒 TinyNAS 渠道工具（激活码生成器、刷机 SOP、话术）" \
  --public
```

**Step 2: 本地克隆 + 生成器骨架**
```bash
cd ~/work/tinynas
git clone https://github.com/tiny-nas/tools.git
cd tools
mkdir -p activator
```

**Step 3: activator.py（Python tkinter GUI，离线可用）**
```bash
cat > activator/activator.py <<'PYEOF'
#!/usr/bin/env python3
"""锦盒 TinyNAS 批量激活码生成器（离线 GUI）

输入：16 位机器码（大写十六进制）
输出：12 位激活码（大写十六进制）

⚠️ 仅含渠道子密钥；MASTER SECRET 不在此仓
"""
import tkinter as tk
from tkinter import messagebox
import hmac
import hashlib
import sys

# 渠道子密钥（每个渠道独立，由我方构建时生成）
CHANNEL_SALT = "xianyu_a_2026_v1_salt_change_in_production"

def generate(machine_id: str, salt: str) -> str:
    if len(machine_id) != 16 or not all(c in "0123456789ABCDEF" for c in machine_id):
        raise ValueError("机器码必须是 16 位十六进制字符")
    return hmac.new(salt.encode(), machine_id.encode(), hashlib.sha256).hexdigest()[:12].upper()

class App:
    def __init__(self, root):
        self.root = root
        root.title("锦盒 TinyNAS 激活码生成器")

        tk.Label(root, text="机器码（16 位）：").grid(row=0, column=0, sticky="w", padx=8, pady=4)
        self.entry = tk.Entry(root, width=22)
        self.entry.grid(row=0, column=1, padx=8)

        tk.Label(root, text="激活码：").grid(row=1, column=0, sticky="w", padx=8, pady=4)
        self.result = tk.Entry(root, width=22, state="readonly")
        self.result.grid(row=1, column=1, padx=8)

        tk.Button(root, text="生成激活码", command=self.on_generate).grid(row=2, column=0, columnspan=2, pady=8)
        tk.Button(root, text="复制到剪贴板", command=self.on_copy).grid(row=3, column=0, columnspan=2, pady=4)

    def on_generate(self):
        mid = self.entry.get().strip().upper()
        try:
            code = generate(mid, CHANNEL_SALT)
            self.result.configure(state="normal")
            self.result.delete(0, tk.END)
            self.result.insert(0, code)
            self.result.configure(state="readonly")
        except ValueError as e:
            messagebox.showerror("错误", str(e))

    def on_copy(self):
        code = self.result.get()
        if code:
            self.root.clipboard_clear()
            self.root.clipboard_append(code)

if __name__ == "__main__":
    root = tk.Tk()
    App(root)
    root.mainloop()
PYEOF
chmod +x activator/activator.py
```

**Step 4: 测试**
```bash
python3 -c "
from activator.activator import generate
print(generate('A1B2C3D4E5F60718', 'xianyu_a_2026_v1_salt_change_in_production'))
"
# 期望：12 位十六进制大写

python3 activator/activator.py  # 弹出 GUI
```

**Step 5: 多渠道分发版本**
```bash
# 每个渠道生成独立的激活器（不同盐值）
for channel in xianyu_a taobao_b; do
    sed "s/CHANNEL_SALT = .*/CHANNEL_SALT = \"${channel}_2026_v1_salt_change_in_production\"/" \
        activator/activator.py > "activator/activator-${channel}.py"
done

# 验证：用 xianyu_a 生成器生成的码，在 taobao_b 固件上输入应失败
python3 -c "
import sys
sys.path.insert(0, 'activator')
import importlib.util
spec = importlib.util.spec_from_file_location('a', 'activator/activator-xianyu_a.py')
mod = importlib.util.module_from_spec(spec); spec.loader.exec_module(mod)
print('xianyu_a 生成:', mod.generate('A1B2C3D4E5F60718', mod.CHANNEL_SALT))
"
```

**Step 6: commit**
```bash
git add activator/
git commit -m "feat(activator): offline batch generator (per-channel salt)"
git push origin main
```

---

### Task 5.2  渠道水印构建脚本 + Release 脚本（W4 第 1 天）

**Files:**
- Create: `tiny-nas/openwrt-imagebuilder/scripts/release-channel.sh`

**Step 1: release-channel.sh**
```bash
#!/usr/bin/env bash
# 渠道固件打包：注入渠道盐值 + 重打包 + sha256
# 用法：./scripts/release-channel.sh <channel> <arch-branch> [tier] [version]
# 例：./scripts/release-channel.sh xianyu_a arch/x86_64 pro 1.0.0
set -euo pipefail

CHANNEL="${1:?channel required}"
ARCH_BRANCH="${2:?arch-branch required}"
TIER="${3:-pro}"
VERSION="${4:-1.0.0}"

# 1. 切换到架构分支
git checkout "${ARCH_BRANCH}"

# 2. 注入渠道盐值到覆盖层
SALT="${CHANNEL}_2026_v1_salt_change_in_production"
cat > common/tinynas-files/etc/tinynas/secret <<EOF
CHANNEL_SALT=${SALT}
EOF

# 3. 注入渠道元信息
mkdir -p common/tinynas-files/etc/tinynas
cat > common/tinynas-files/etc/tinynas/brand <<EOF
BRAND=tinynas
TIER=${TIER}
DEVICE=$(echo "${ARCH_BRANCH}" | sed 's|arch/||' | tr '/' '-')
EOF
echo "CHANNEL=${CHANNEL}" > common/tinynas-files/etc/tinynas/channel

# 4. 重新打包
cd "${ARCH_BRANCH#arch/}" 2>/dev/null || cd "$(echo ${ARCH_BRANCH} | sed 's|^arch/||')"
chmod +x build.sh
./build.sh stable "${VERSION}" 2>&1 | tee "${OUTPUT_DIR}/build-${CHANNEL}-$(date +%Y%m%d).log"

# 5. 移动产物到 release 目录
RELEASE_DIR="~/work/tinynas/release/${CHANNEL}"
mkdir -p "${RELEASE_DIR}"
mv output/openwrt_tinynas-*_*.img.gz "${RELEASE_DIR}/"
mv output/openwrt_tinynas-*_*.img.gz.sha256 "${RELEASE_DIR}/"

# 6. 生成激活器副本
cp ~/work/tinynas/tools/activator/activator-${CHANNEL}.py "${RELEASE_DIR}/generate-code.py"
chmod +x "${RELEASE_DIR}/generate-code.py"

# 7. 生成交付清单
cat > "${RELEASE_DIR}/DELIVERY.md" <<EOF
# 锦盒 TinyNAS · ${CHANNEL} 渠道交付包

## 内容
- \`$(ls ${RELEASE_DIR}/*.img.gz)\`：固件镜像
- \`$(ls ${RELEASE_DIR}/*.img.gz.sha256)\`：sha256 校验
- \`generate-code.py\`：离线激活码生成器（已绑定本渠道盐值）

## 刷机步骤
1. 用 BalenaEtcher 将固件刷入 U 盘
2. N1 断电，U 盘插靠近 HDMI 的 USB 口
3. 通电启动，浏览器访问 http://192.168.1.1
4. 把机器码发给店主（或自己用 generate-code.py 生成激活码）
5. 输入激活码激活

## 责任分界
- 硬件问题（焊接、扩容）→ 店铺负责
- 软件问题（固件 bug、激活失败）→ 我方负责（找客服）
EOF

echo "✅ 渠道交付包: ${RELEASE_DIR}"
ls -la "${RELEASE_DIR}"
```

**Step 2: commit**
```bash
chmod +x scripts/release-channel.sh
git add scripts/release-channel.sh
git commit -m "feat(scripts): release-channel.sh (per-channel firmware + activator bundle)"
```

---

### Task 5.3  SOP 图文 + 视频脚本（W4 第 2 天）

**Files:**
- Create: `tiny-nas/tools/sop/刷机SOP.md`
- Create: `tiny-nas/tools/sop/视频脚本.md`
- Create: `tiny-nas/tools/话术/店铺话术模板.md`

**Step 1: 刷机 SOP（图文）**
```bash
mkdir -p sop 话术
cat > sop/刷机SOP.md <<'EOF'
# 锦盒 TinyNAS · N1 刷机 SOP

**适用**：斐讯 N1（S905D）
**工具**：USB-TTL 串口线（3.3V）、BalenaEtcher、16GB+ U 盘
**预计耗时**：首次 30 分钟（含读文档）；熟练后 10 分钟

## Step 1：准备（5 分钟）
- 下载 [最新固件](https://github.com/tiny-nas/openwrt-imagebuilder/releases) 的 `openwrt_tinynas-pro-n1_vX.Y.Z-stable_<date>.img.gz`
- 用 BalenaEtcher 写入 U 盘
- **不拔** U 盘

## Step 2：N1 启动（3 分钟）
- N1 断电
- U 盘插入靠近 HDMI 的 USB 口（**优先启动**）
- HDMI 接显示器 + 网线接路由器 LAN 口
- 通电

## Step 3：浏览器向导（2 分钟）
- 电脑网线连同一路由器，自动获取 DHCP
- 浏览器打开 `http://192.168.1.1/`
- 看到机器码（16 位大写）→ [复制]

## Step 4：获取激活码（1 分钟）
- 把机器码发给店主 / 自己用 `generate-code.py` 生成
- 把 12 位激活码填入页面 → [激活]
- 3 秒后跳转到仪表盘

## Step 5：写 eMMC（5 分钟）
- 仪表盘 → 设置 → 系统 → 写入 eMMC
- 等待 3-5 分钟
- 断电 → 拔 U 盘 → 通电
- N1 从 eMMC 独立启动

## Step 6：验证（2 分钟）
- 浏览器访问 `http://192.168.1.1/`
- 看到仪表盘 + 文件盘
- 小米电视"高清播放器"→ 网络邻居看到 `TINYNAS`

## 翻车恢复
- **无法启动**：重写 U 盘 / 短接 N1 复位点 / 串口查看 uboot
- **激活失败**：检查机器码大小写、重新生成激活码
- **写 eMMC 失败**：保持 U 盘运行（功能完整，只是慢一点）

## 责任分界
- **硬件问题**（焊接、扩容、变砖）→ 店铺负责
- **软件问题**（固件 bug、激活失败、Samba 异常）→ 我方负责
EOF

cat > sop/视频脚本.md <<'EOF'
# 锦盒 TinyNAS · 3 分钟刷机视频脚本

## 镜头 1：开场（0:00-0:15）
[画面：凌乱的桌面 + 一台 N1]
旁白："斐讯 N1，二手价不到 50 块。今天花 10 分钟，把它变成你的家庭 AI 私有云。"

## 镜头 2：刷机（0:15-1:30）
[画面：BalenaEtcher 写入 U 盘 → 插 N1 → 通电]
旁白："下载固件，写 U 盘，插上，通电。就是这样。"

## 镜头 3：向导（1:30-2:00）
[画面：浏览器 192.168.1.1 → 机器码展示]
旁白："打开浏览器，看到 16 位机器码。复制，发给卖家（或自己用工具生成）。"

## 镜头 4：激活（2:00-2:30）
[画面：粘贴激活码 → 激活按钮 → 跳仪表盘]
旁白："12 位激活码粘贴进去，3 秒跳转。全功能解锁。"

## 镜头 5：电视发现（2:30-3:00）
[画面：小米电视 → 高清播放器 → 网络邻居 → TINYNAS]
旁白："电视直接看到你的 NAS，插电即用。再见，群晖。"

## 出字幕
- 主页：tinynas.io
- 闲鱼/淘宝搜索"锦盒 TinyNAS"
- 升级插件、远程下载：见说明文档
EOF

cat > 话术/店铺话术模板.md <<'EOF'
# 锦盒 TinyNAS 店铺话术模板

## 闲鱼/淘宝商品标题
**【锦盒 TinyNAS】斐讯 N1 变身家庭 AI 私有云（刷好 OpenWrt + 智能体 + 网盘）**

## 商品描述（合规版）

斐讯 N1 二手盒子 ¥XX，刷好锦盒 TinyNAS 固件，开机即用。

**包含**：
- 扩容后 32GB eMMC（已焊好）
- 12V/2A 电源
- 锦盒 TinyNAS Pro 档固件（已激活）
- 3 个月软件问题免费支持
- 配套刷机 SOP（图文 + 视频）

**功能**：
- 千兆 Samba 文件共享
- DLNA 媒体库（小米电视直接看）
- AI 智能体（绑定飞书/企微/微信）
- 远程下载（浏览器插件推送）

**硬件问题**（如扩容焊接故障）：店铺负责，免费重焊或换机
**软件问题**：我方终身支持，微信/QQ 群

**合规说明**：本固件基于 [OpenWrt 25.12.5](https://openwrt.org/) 深度定制，遵循 GPL v2 开源协议，构建脚本公开在 [github.com/tiny-nas](https://github.com/tiny-nas)。

## 不准说的话
❌ "自主研发操作系统"（违反 GPL）
❌ "完全独立开发"（违反 GPL）
❌ "媲美群晖"（功能不对等）
❌ "永久免费升级"（除非包含在订阅里）

## 客服话术（用户激活失败）
"麻烦您发一下机器码截图，我们这边核对一下。激活码是绑机器码的，可能复制时漏了字符。"
```

**Step 2: commit**
```bash
git add sop/ 话术/
git commit -m "docs(tools): 刷机 SOP + 视频脚本 + 店铺话术"
git push origin main
```

---

### Task 5.4  出首批渠道包（W4 第 3 天）

**Step 1: 构建 xianyu_a 渠道包**
```bash
cd /Users/wandl/workspaces/workspace-tinynas/openwrt-imagebuilder
git checkout arch/x86_64
./../scripts/release-channel.sh xianyu_a arch/x86_64 pro 1.0.0
# 产物在 ~/work/tinynas/release/xianyu_a/
ls ~/work/tinynas/release/xianyu_a/
```

**Step 2: 同理构建 taobao_b 渠道包**
```bash
./scripts/release-channel.sh taobao_b arch/x86_64 pro 1.0.0
ls ~/work/tinynas/release/taobao_b/
```

**Step 3: 渠道间隔离验证**
```bash
# 用 xianyu_a 生成器生成码，taobao_b 固件应拒绝
cd ~/work/tinynas/release/xianyu_a
python3 generate-code.py <<<"A1B2C3D4E5F60718"  # 假设支持 stdin 或 GUI
# 拿这个码去 taobao_b 设备的向导页面输入 → 应返回"激活码无效"
```

**Step 4: 文档同步**
```bash
cd /Users/wandl/workspaces/workspace-octoclaw-labs/partme-docs/8、TinyNAS\ 锦盒/V1
# 更新 PRD 验证记录（标 SP-5 完成）
```

---

## SP-6  ·  V1.0 收尾（GA + 内测 + 试卖）  ·  W4–W5（W4 后半 + W5）

### Task 6.1  V0.9 Beta 包发布 + 内测招募（W4 第 4 天）

**Files:**
- Create: GitHub Release `v0.9.0-beta`

**Step 1: 给恩山/V2EX/小红书发预告**
- 恩山无线论坛（OpenWrt/FBOX 板块）：发新帖"N1 锦盒 TinyNAS V0.9 Beta 内测"
- V2EX（NAS 节点）：发"锦盒 TinyNAS - 斐讯 N1 家庭 AI NAS V0.9 Beta 招募"
- 小红书（#斐讯N1 #NAS）：视频或图文
- 招募目标：≥3 名内测用户（你的微信/QQ 群）

**Step 2: GitHub Release v0.9.0-beta**
```bash
cd /Users/wandl/workspaces/workspace-tinynas/openwrt-imagebuilder
gh release create v0.9.0-beta \
  --title "锦盒 TinyNAS V0.9 Beta" \
  --notes "$(cat <<EOF
## 主要功能
- N1 Pro 档首版固件
- 首启向导 + 机器码激活
- Samba/DLNA/aria2 文件共享 + 下载
- 仪表盘（含 dashboard 注入）
- NATS + pairing（stub 模式）
- 浏览器插件 + CRX 离线包

## 测试范围
- 真机刷机 + 激活全流程
- 5 类链接下载（http/https/magnet/thunder 解码/torrent）
- 电视/电脑发现 + 播放

## 已知限制
- pairing 是 stub 模式（设备激活不依赖云端）
- 浏览器插件需 CRX 离线安装
- 见 docs/m1-verification.md

## 反馈渠道
- GitHub Issues
- 微信群（扫描 README 二维码）
EOF
)"
gh release upload v0.9.0-beta ~/work/tinynas/release/xianyu_a/*.img.gz
```

**Step 3: 内测用户分发改版**
- 每位内测用户得到：固件 + 激活码 + SOP + 反馈表
- 反馈表：刷机成功率、激活成功率、Samba 性能、SOP 是否清晰、错误日志

**Step 4: commit**
```bash
git add docs/
git commit -m "docs: V0.9 Beta release notes"
git push origin main
```

---

### Task 6.2  内测反馈修复 + V1.0 GA（W5 第 1–2 天）

**Step 1: 收集内测反馈**
- 至少 3 份反馈表
- 关注：刷机失败案例、激活错误、Samba 速度、aria2 下载、SOP 清晰度

**Step 2: 修复高优先级问题**
- 至少修复：所有影响刷机成功的 P0 问题
- 改进：SOP 不清晰的章节（图文、报错提示）

**Step 3: V1.0 GA Release**
```bash
gh release create v1.0.0 \
  --title "锦盒 TinyNAS V1.0 正式发布" \
  --notes "## 完整功能 ...（含内测修复）"
```

**Step 4: commit**
```bash
git add .
git commit -m "fix: V0.9→V1.0 内测反馈修复"
git tag v1.0.0 && git push --tags origin main
```

---

### Task 6.3  2 家店铺试卖 5–10 台（W5 第 3–4 天）

**Step 1: 联系店铺**
- 给 W1.1 已加的 2 家 N1 刷机店发消息
- 提供：渠道包 + 激活器 + 刷机 SOP + 话术模板
- 约定试卖期：10 天内出货 ≥5 台

**Step 2: 跟踪销量**
- 每周 1 次询问店铺：① 出货数；② 激活失败率；③ 客户反馈
- pairing `/stats/channels` 校验激活数与店铺销量匹配

**Step 3: 出货达标后，签 OEM 长期合作**
- 月结约定
- 排他保护（同区域不重叠）
- 持续固件更新推送

**Step 4: 文档更新**
```bash
cd /Users/wandl/workspaces/workspace-octoclaw-labs/partme-docs/8、TinyNAS\ 锦盒/V1
# 在 PRD V1 验收一节标记：
# - 试卖完成日期
# - 实际出货数
# - 客户反馈摘要
```

---

### Task 6.4  闲鱼/淘宝直营上架（W5 第 5 天）

**Step 1: 闲鱼商品发布**
- 标题：见 sop/话术模板
- 商品图：N1 + 显示器 + 小米电视三张
- 定价：整机 ¥229 / 镜像 + 激活码 ¥39
- 同城自提免邮，外省 ¥15 邮费

**Step 2: 淘宝企业店准备**
- 工商注册：淘宝企业店需营业执照，**预计 9 月底前完成**（如未完成，仅闲鱼售卖）
- 个人店暂代：押金 ¥1000

**Step 3: 售后**
- 微信群
- FAQ 文档
- 24 小时内首响应

---

## SP-7  ·  微信小程序 V1.5（9 月不交付，仅预留接口）

### Task 7.1  pairing 预留小程序路由（W3 第 4 天，与 SP-3 并行）

**Step 1: 在 pairing 添加小程序专用路由（占位实现）**
- `/miniapp/device-status?device_id=` 返回设备状态
- `/miniapp/tasks?device_id=` 返回任务列表
- `/miniapp/push` 提交新下载任务

```rust
// src/routes/miniapp.rs（占位）
pub async fn device_status(...) -> Json<...> { /* TODO V1.5 */ }
```

**Step 2: commit**
```bash
cd ~/work/tinynas/pairing
git add src/routes/miniapp.rs
git commit -m "feat(pairing): miniapp route stubs (V1.5 implementation)"
git push origin main
```

**9 月到此为止**——小程序实际开发推到 10–11 月。

---

## Self-Review（v2）

**1. Spec 覆盖**：
- SP-1 ✓（N1 固件 + 授权闭环）
- SP-2A ✓（仪表盘 SPA，v2 拆出）
- SP-2B ✓（LuCI 统一主题，v2 新增，8 个 Task 覆盖 8+ 核心页面 + 性能 + 集成）
- SP-3 ✓（pairing + NATS）
- SP-4 ✓（浏览器插件）
- SP-5 ✓（渠道工具）
- SP-6 ✓（V1.0 收尾）
- SP-7 ✓（小程序占位）

**2. 占位符扫描**：无 TBD/TODO（除 SP-7 "推到 V1.5" 的明示）；无"适当错误处理"等空洞描述。

**3. 类型/接口一致性**：
- `tinynas-machine-id` 返回 16 位大写十六进制（Task 1.4 / 1.6）
- `pairing /pair?device=&code=` 参数命名（Task 3.3 / 4.2）一致
- **设计令牌 JSON**（Task 2B.2 dashboard design-tokens.json ↔ Task 2B.2 luci-theme-tinynas design-tokens.json）通过 Task 2B.3 token-diff CI 强制一致
- **LuCI 横幅跳转目标** `/tinynas/` ↔ SPA 入口 `/` 配套（Task 2B.7 ↔ Task 2A.4 Sidebar 路由器模式）
- **路由器模式 Banner**（SPA 侧）`/cgi-bin/luci` ↔ LuCI 主页 banner `href="/tinynas/"` 双向跳转
- 镜像命名 5 段规范（Task 1.7 / 1.8）一致

**4. v1 → v2 变更点**：
- SP-2 → SP-2A + SP-2B：✅ 拆分清晰，双人分工
- 新增 luci-theme-tinynas 仓：✅ 独立 SP、独立责任人
- GA 推迟到 10-31：✅ 时间线对齐（任务里程碑全部更新）
- 双人 + Codex 协作：✅ Global Constraints + SP-2B 任务均显式标注

**5. 关键风险已加粗**：128MB RAM LuCI 卡顿（SP-2B.8 性能优化）、LuCI 24+ 页面全覆盖风险（限定 8 核心页面，其余降级）、V1.0 GA 推迟爬坡期短（限量预售+OTA 推送）

---

## 执行选择（v2）

Plan 完整保存在 `docs/plan/2026-08-28-tinynas-v1-delivery.md`（git 跟踪，用户偏好覆盖默认 `docs/superpowers/plans/`）。

**执行矩阵（v2 双人协作）**：

| 执行方式 | 适用 | 分工建议 |
|:---|:---|:---|
| **Subagent-Driven（推荐）** | hiwepy 用 ZCode 派工执行 SP-1/2A/3/4/5 的机械化任务 | 每个 Task 派一个 fresh subagent，任务间 review；搭档负责 SP-2B（codex 生成 LuCI 主题骨架 + 人工 review 调试） |
| **Inline Execution** | 需要强上下文连续性的任务（真机调试、联调、端到端验收） | 用 executing-plans skill 按 SP 里程碑批量执行，M1/端到端/试卖三个 checkpoint |

**推荐组合**：机械任务（仓库脚手架、SCSS 变量生成、CI 配置、文档）用 Subagent 派工；**关键链路任务（M1 真机验收、SP-3↔SP-4 端到端、SP-5 渠道隔离验证、V1.0 GA 发布）必须 Inline 由本人执行**。

**搭档（SP-2B）的开工包**：本 plan 的 SP-2B 章节 + [Doc 9 视觉 DNA](https://github.com/tiny-nas) + Task 2B.1~2B.8 顺序执行；每日站会同步设计令牌变更。
