# TinyNAS 覆盖层 V1（S1）Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 实现 `common/tinynas-files/` 覆盖层全部 14 项交付物（V1/3 §3 权威清单）+ build-template.sh 五项变更，打通"刷机→向导→激活→仪表盘"链路的固件侧全部代码。

**Architecture:** 单源覆盖层（92+Amlogic 共享），经 IB `FILES=` 注入。激活采用 Ed25519 离线许可证（信封格式+openssl pkeyutl 验证），机器身份五要素 `machine_digest`，激活状态机由 `tinynas-license-check`(S98) + `tinynas-boot`(S99) 承载，uHTTPd index 劫持实现未激活向导。**权威口径以 partme-docs 最终文档库为准**（旧报告的 HMAC/secret/fstab/三要素已废弃）。

**Tech Stack:** POSIX sh（busybox 兼容）、openssl-util（pkeyutl/dgst）、uci、UCI 配置文件、无依赖单文件 HTML（设计令牌内联）。宿主测试策略：脚本支持 `TINYNAS_SYSINFO_ROOT` / `TINYNAS_PROC_ROOT` 环境注入 fixture，可在 macOS 上做真实行为测试；Ed25519 测试用例在宿主 openssl 不支持时 SKIP，真实验证门禁为 POC P7（目标机）。

**验证总门禁:** `tests/run-lint.sh` 全绿（8 条军规静态门禁）+ 行为测试通过 + `sh -n` 全部通过。POC P1（IB 出 rootfs.tar.gz）与 P2（FILES= 注入）需 Docker/CI，标记为 S1.5 待验。

---

### Task 1: 分支与目录骨架

**Files:**
- Create: 分支 `feat/overlay-v1`（基于 main）
- Create: `common/tinynas-files/tests/fixtures/sysinfo/`（machine-id fixture 树）

**Step 1: 建分支**

```bash
cd /Users/wandl/workspaces/workspace-tinynas/openwrt-imagebuilder
git checkout main && git pull --ff-only 2>/dev/null; git checkout -b feat/overlay-v1
```

**Step 2: 建 fixture 树**（machine-id 测试用，模拟目标机 sysfs）

```bash
F=common/tinynas-files/tests/fixtures/sysinfo
mkdir -p $F/tmp/sysinfo $F/proc/device-tree $F/sys/block/mmcblk0/device $F/sys/class/net/eth0
printf 'phicomm_n1' > $F/tmp/sysinfo/board_name
printf 'Phicomm N1\\0' | tr -d '\\\\0' > /dev/null; printf 'Phicomm N1' > $F/proc/device-tree/model
printf 'amlogic,gxl\\0phicomm,n1\\0' > $F/proc/device-tree/compatible   # 保留 \\0 分隔符
printf '0000000000001234' > $F/sys/block/mmcblk0/device/cid
printf 'Serial\\t: 0000000000000000' > $F/proc/cpuinfo
printf 'aa:bb:cc:dd:ee:ff\\n' > $F/sys/class/net/eth0/address
```

**Step 3: Commit**

```bash
git add -A && git commit -m "chore(overlay): feat branch + sysinfo fixture tree"
```

---

### Task 2: `usr/bin/tinynas-machine-id`（TDD：先写期望值）

**Files:**
- Create: `common/tinynas-files/usr/bin/tinynas-machine-id`
- Test: `common/tinynas-files/tests/test-machine-id.sh`

**Step 1: 用 python3 独立计算期望值（防自证）**

```bash
python3 - <<'PY'
import hashlib
def enc(s): b=s.encode(); return f"{len(b):04x}".encode()+b
fields=[b"phicomm_n1", b"0000000000001234", b"0000000000000000", b"aabbccddeeff", b"amlogic,gxl"]
payload=b"v1"+b"".join(enc(f) for f in fields)
d=hashlib.sha256(payload).hexdigest()
print("digest",d); print("display",d[:16].upper()); print("device","tn_"+d[:24])
PY
```

记录输出的 display/device（fixture 期望值，写入测试脚本）。

**Step 2: 写测试** `tests/test-machine-id.sh`

```sh
#!/bin/sh
# 行为测试：fixture 注入 + 期望值断言（期望值由 python3 独立生成，见文件头注释）
HERE=$(cd "$(dirname "$0")" && pwd)
export TINYNAS_SYSINFO_ROOT="$HERE/fixtures/sysinfo"
M="$HERE/../usr/bin/tinynas-machine-id"
[ -x "$M" ] || { echo "FAIL: machine-id not executable"; exit 1; }
OUT=$("$M" --display)
DIG=$("$M" --digest)
DEV=$("$M" --device)
echo "$DIG" | grep -qE '^[0-9a-f]{64}$' || { echo "FAIL digest format: $DIG"; exit 1; }
echo "$OUT" | grep -qE '^[0-9A-F]{16}$' || { echo "FAIL display format: $OUT"; exit 1; }
case "$DEV" in tn_[0-9a-f]{24}) :;; *) echo "FAIL device: $DEV"; exit 1;; esac
# 期望值（Task 2 Step 1 生成；如算法实现与此不符必须查原因，不许改期望值凑）
EXPECT_DISPLAY="%%EXPECTED_DISPLAY%%"
EXPECT_DEVICE="%%EXPECTED_DEVICE%%"
[ "$OUT" = "$EXPECT_DISPLAY" ] || { echo "FAIL display=$OUT want=$EXPECT_DISPLAY"; exit 1; }
[ "$DEV" = "$EXPECT_DEVICE" ] || { echo "FAIL device=$DEV want=$EXPECT_DEVICE"; exit 1; }
echo "PASS test-machine-id"
```

运行确认 **FAIL**（脚本尚不存在）。

**Step 3: 实现** `usr/bin/tinynas-machine-id`

```sh
#!/bin/sh
# tinynas-machine-id — 设备机器身份（v1 闭环规格）
# machine_digest = SHA256(versioned_length_prefixed(board_model, emmc_cid, cpu_serial, lan_mac, board_compatible))
# display_machine_id = digest[0..16].upper();  device_id = "tn_" + digest[0..24].lower()
# 测试: TINYNAS_SYSINFO_ROOT=<fixture> 注入虚拟 sysfs

SYS="${TINYNAS_SYSINFO_ROOT:-}"
CACHE_DIR="${TINYNAS_STATE_DIR:-/etc/tinynas}"

rd() { # $1=绝对路径 $2=缺省占位符  — 去除 \0 与首尾空白
    f="${SYS}$1"
    if [ -r "$f" ]; then tr -d '\000' < "$f" | awk '{$1=$1};1' | awk 'NR==1{print}'; else printf '%s' "$2"; fi
}

board=$(rd /tmp/sysinfo/board_name "no-board")
[ -n "$board" ] || board="no-board"
cid=$(rd /sys/block/mmcblk0/device/cid "no-cid"); [ -n "$cid" ] || cid="no-cid"
serial=$(awk '/^Serial/{print $3; exit}' "${SYS}/proc/cpuinfo" 2>/dev/null)
[ -n "$serial" ] || serial="no-serial"
mac=$(rd /sys/class/net/eth0/address "no-mac" | tr -d ':')
[ -n "$mac" ] || mac="no-mac"
compat=$(rd /proc/device-tree/compatible "no-compat" | sed 's/^[^,]*,//')  # 取第一个 compatible 的第二段（厂商,型号 的型号段）
[ -n "$compat" ] || compat="no-compat"

enc() { p="$1"; n=$(printf '%s' "$p" | wc -c | tr -d ' '); printf '%04x%s' "$n" "$p"; }
payload="v1$(enc "$board")$(enc "$cid")$(enc "$serial")$(enc "$mac")$(enc "$compat")"
digest=$(printf '%s' "$payload" | openssl dgst -sha256 | sed 's/^.*= //')

case "$1" in
    --digest) printf '%s\n' "$digest"; exit 0 ;;
    --device) printf 'tn_%s\n' "$(printf '%s' "$digest" | cut -c1-24)"; exit 0 ;;
    --payload) printf '%s\n' "$payload"; exit 0 ;;
esac

display=$(printf '%s' "$digest" | cut -c1-16 | tr 'a-f' 'A-F')
if [ -w "$CACHE_DIR" ] || mkdir -p "$CACHE_DIR" 2>/dev/null; then
    printf '%s\n' "$display" > "$CACHE_DIR/.machine_id" 2>/dev/null || :
fi
printf '%s\n' "$display"
```

> 注意 fixture 的 compatible 是 `amlogic,gxl\0phicomm,n1\0`（含真实 NUL），rd() 去掉 NUL 后 `sed 's/^[^,]*,//'` 取得 `n1`；**python 期望值计算必须用同样的变换后字段**（`amlogic,gxl` → `gxl`）。Step 1 生成期望值时 fields 应为变换后取值：board=`phicomm_n1`, cid, serial, mac, compat=`gxl`。

**Step 4: 重算期望值并回填测试**（用修正后字段跑 Step 1 python，替换 `%%EXPECTED_*%%`）

**Step 5: 运行测试 → PASS**

```bash
chmod +x usr/bin/tinynas-machine-id tests/test-machine-id.sh
tests/test-machine-id.sh
```

**Step 6: Commit** `git commit -m "feat(overlay): tinynas-machine-id 5-tuple identity + host fixture test"`

---

### Task 3: `etc/init.d/tinynas-license-check`（S98 指纹复核）

**Files:** Create: `etc/init.d/tinynas-license-check`

```sh
#!/bin/sh /etc/rc.common
# tinynas-license-check — 开机指纹复核（START=98，先于 tinynas-boot）
START=98
STOP=10

boot() { start; }

start() {
    [ -f /etc/tinynas/.activated ] || return 0
    M=/usr/bin/tinynas-machine-id
    [ -x "$M" ] || { logger -t tinynas -p daemon.err "machine-id tool missing"; return 1; }
    CURRENT=$($M --display)
    SAVED=$(awk -F= '/^machine_id=/{print $2}' /etc/tinynas/.activated 2>/dev/null)
    if [ -n "$SAVED" ] && [ "$SAVED" != "$CURRENT" ]; then
        rm -f /etc/tinynas/.activated
        logger -t tinynas -p daemon.warn "license fingerprint mismatch (saved=$SAVED current=$CURRENT) — activation revoked"
    fi
}
```

**Verify:** `sh -n`（shebang 行会被 sh 当注释，直接 `sh -n` 可解析）；grep 门禁：含 rc.common shebang、`START=98`、无 `/etc/rc.d/` 写操作。

```bash
sed -n '2p' etc/init.d/tinynas-license-check | grep -q '^START=98' && echo PASS
```

**Commit:** `feat(overlay): license-check boot fingerprint re-verification`

---

### Task 4: `etc/init.d/tinynas-boot`（S99 激活状态机）

**Files:** Create: `etc/init.d/tinynas-boot`；Create: `www/index.html`（激活后根路径跳转）

tinynas-boot:

```sh
#!/bin/sh /etc/rc.common
# tinynas-boot — 激活状态机（START=99，uHTTPd/fstab 之后）
START=99
STOP=90

apply_state() {
    mkdir -p /etc/tinynas
    if [ ! -f /etc/tinynas/.activated ]; then
        # 未激活：劫持根路径到向导 + Samba 只读
        uci set uhttpd.main.index_page='tinynas-wizard.html'
        uci -q set samba4.@samba[0].read_only='yes' 2>/dev/null
        uci commit uhttpd
        uci -q commit samba4
        /etc/init.d/uhttpd restart 2>/dev/null
        logger -t tinynas "unactivated: wizard hijack enabled"
    else
        uci set uhttpd.main.index_page='index.html'
        uci -q set samba4.@samba[0].read_only='no' 2>/dev/null
        uci commit uhttpd
        uci -q commit samba4
        /etc/init.d/samba4 restart 2>/dev/null
        /etc/init.d/minidlna restart 2>/dev/null
        /etc/init.d/aria2 restart 2>/dev/null
        # NATS consumer（S3 交付，存在才拉起）
        [ -x /usr/bin/tinynas-nats-consumer ] && [ -s /etc/tinynas/nats.creds ] && \
            /etc/init.d/tinynas-nats restart 2>/dev/null
        logger -t tinynas "activated: full service state applied"
    fi
}

boot() { apply_state; }
start() { apply_state; }
restart() { apply_state; }
```

www/index.html（激活后根路径元跳转，先于 SPA 子目录）:

```html
<!DOCTYPE html><html><head><meta charset="utf-8"><meta http-equiv="refresh" content="0;url=/tinynas/"><title>锦盒 TinyNAS</title></head><body><a href="/tinynas/">锦盒 TinyNAS</a></body></html>
```

**Verify:** lint 门禁（shebang/START=99/无 rc.d/uci-defaults 结尾 exit 0 不适用此文件）；`sh -n`。

**Commit:** `feat(overlay): activation state machine boot script + root redirect`

---

### Task 5: `etc/uci-defaults/50-tinynas-uhttpd`（幂等首启配置）

**Files:** Create: `etc/uci-defaults/50-tinynas-uhttpd`

```sh
#!/bin/sh
# 幂等：仅补缺失项，绝不覆盖 boot 脚本管理的 index_page
[ -f /etc/config/uhttpd ] || exit 0
uci -q get uhttpd.main.rfc1918_filter >/dev/null || uci set uhttpd.main.rfc1918_filter='1'
uci -q get uhttpd.main.cgi_prefix >/dev/null || uci set uhttpd.main.cgi_prefix='/cgi-bin'
uci commit uhttpd
exit 0
```

**Verify:** `sh -n`；尾行 `exit 0`（军规 3）；`grep -c 'uci set' ≤3`（只补缺不覆盖）。

**Commit:** `feat(overlay): idempotent uhttpd uci-defaults`

---

### Task 6: `etc/config/samba4` + `etc/config/minidlna`（预置配置）

**Files:** Create: `etc/config/samba4`、`etc/config/minidlna`

samba4（UCI 格式，NetBIOS 广播 + SMB2/3，电视可识别）:

```
config samba
	option workgroup 'WORKGROUP'
	option server_string 'TinyNAS'
	option netbios_name 'TinyNAS'
	option name_resolve_order 'bcast host'
	option server_min_protocol 'SMB2'
	option server_max_protocol 'SMB3'
	option discoverable 'yes'
	option read_only 'yes'

config sambashare
	option name 'share'
	option path '/mnt/usb/share'
	option read_only 'no'
	option guest_ok 'yes'
	option create_mask '0666'
	option dir_mask '0777'
```

minidlna:

```
config minidlna 'config'
	option enabled '1'
	option friendly_name '锦盒-媒体库'
	option media_dir 'V,/mnt/usb/share/Movies'
	option media_dir 'A,/mnt/usb/share/Music'
	option db_dir '/etc/tinynas/minidlna'
	option inotify '1'
	option notify_interval '60'
	option port '8200'
```

**Verify:** `awk` 配对检查 config 节语法；`grep -q "friendly_name '锦盒-媒体库'"`。

**Commit:** `feat(overlay): samba4 + minidlna preset configs (TV discovery)`

---

### Task 7: `www/cgi-bin/machine-id`（宿主可真实运行）

**Files:** Create: `www/cgi-bin/machine-id`

```sh
#!/bin/sh
# CGI: GET machine-id → {display_machine_id, device_id, pairing_code}
# pairing_code = SHA256(display_machine_id + YYYYMMDDHH) 前 6 位大写（小时轮换，仅配对引导用）
printf 'Content-Type: application/json\r\n\r\n'
M=/usr/bin/tinynas-machine-id
[ -x "$M" ] || { printf '{"error":"not_ready"}'; exit 0; }
DISPLAY=$($M --display 2>/dev/null) || { printf '{"error":"not_ready"}'; exit 0; }
[ -n "$DISPLAY" ] || { printf '{"error":"not_ready"}'; exit 0; }
DEVICE=$($M --device)
HOUR=$(date +%Y%m%d%d 2>/dev/null; date +%H)
CODE=$(printf '%s%s' "$DISPLAY" "$(date +%Y%m%d%H)" | openssl dgst -sha256 | sed 's/^.*= //' | cut -c1-6 | tr 'a-f' 'A-F')
printf '{"display_machine_id":"%s","device_id":"%s","pairing_code":"%s"}' "$DISPLAY" "$DEVICE" "$CODE"
```

> （实现时删除示例中的 `HOUR=$(date +%Y%m%d%d...)` 残行，只保留 CODE 一行——计划评审点。）

**Verify（宿主真实运行）:**

```bash
export TINYNAS_SYSINFO_ROOT=$PWD/tests/fixtures/sysinfo
./www/cgi-bin/machine-id | grep -q '"display_machine_id"' && echo PASS
```

**Commit:** `feat(overlay): machine-id CGI with hourly pairing code`

---

### Task 8: `www/cgi-bin/status`（TINYNAS_PROC_ROOT 可测）

**Files:** Create: `www/cgi-bin/status`

```sh
#!/bin/sh
# CGI: GET status → 负载/内存/磁盘/服务/元信息（≤200ms，无外部依赖）
P="${TINYNAS_PROC_ROOT:-}"
printf 'Content-Type: application/json\r\n\r\n'
load=$(awk '{print $1}' "${P}/proc/loadavg" 2>/dev/null); load=${load:-0}
mem_total=$(awk '/MemTotal/{print $2}' "${P}/proc/meminfo" 2>/dev/null); mem_total=${mem_total:-0}
mem_avail=$(awk '/MemAvailable/{print $2}' "${P}/proc/meminfo" 2>/dev/null); mem_avail=${mem_avail:-0}
df_line=$(df -k /mnt/usb/share 2>/dev/null | awk 'END{print $2" "$3}')
disk_total=${df_line%% *}; disk_used=${df_line##* }
[ -n "$disk_total" ] || { disk_total=0; disk_used=0; }
svc() { pgrep -f "$1" >/dev/null 2>&1 && echo on || echo off; }
tier=$(cat /etc/tinynas/tier 2>/dev/null | cut -d= -f2); tier=${tier:-pro}
ver=$(cat /etc/tinynas/version 2>/dev/null | cut -d= -f2); ver=${ver:-unknown}
act=unactivated; [ -f /etc/tinynas/.activated ] && act=activated
printf '{"cpu_load":%s,"mem_total_kb":%s,"mem_avail_kb":%s,"disk_total_kb":%s,"disk_used_kb":%s,"services":{"samba":"%s","minidlna":"%s","aria2":"%s"},"tier":"%s","version":"%s","activation":"%s"}' \
  "$load" "$mem_total" "$mem_avail" "$disk_total" "$disk_used" \
  "$(svc samba4)" "$(svc minidlna)" "$(svc aria2)" "$tier" "$ver" "$act"
```

**Verify:** `TINYNAS_PROC_ROOT=$PWD/tests/fixtures/sysinfo ./www/cgi-bin/status | python3 -m json.tool` → 合法 JSON。pgrep 在 macOS 存在 ✓（svc 查不到进程 → off，预期）。

**Commit:** `feat(overlay): status CGI (5s polling budget)`

---

### Task 9: `www/cgi-bin/files`（路径白名单 + JSON 列表）

**Files:** Create: `www/cgi-bin/files`

```sh
#!/bin/sh
# CGI: GET files?path=/Movies → 目录列表（白名单根 /mnt/usb/share，防穿越）
ROOT="/mnt/usb/share"
printf 'Content-Type: application/json\r\n\r\n'
qs="$QUERY_STRING"
[ -n "$qs" ] || { printf '{"entries":[]}'; exit 0; }
sub=$(printf '%s' "$qs" | sed -n 's/^path=//p' | sed 's/+/%20/g')
sub=$(printf '%b' "${sub//%/\\x}")
case "$sub" in *".."*|/*) printf '{"error":"forbidden"}'; exit 0;; esac
dir="$ROOT${sub:+/$sub}"
[ -d "$dir" ] || { printf '{"error":"not_found"}'; exit 0; }
printf '{"entries":['
first=1
ls -A "$dir" 2>/dev/null | while IFS= read -r name; do
    esc=$(printf '%s' "$name" | sed 's/\\/\\\\/g; s/"/\\"/g')
    if [ -d "$dir/$name" ]; then t=dir; else t=file; fi
    sz=$(wc -c < "$dir/$name" 2>/dev/null | tr -d ' '); [ -n "$sz" ] || sz=0
    [ $first -eq 1 ] || printf ','
    printf '{"name":"%s","type":"%s","size":%s}' "$esc" "$t" "$sz"
    first=0
done
printf ']}'
```

> `while` 在管道子 shell 中 first 变化不影响外层——首个逗号逻辑改为一次性收集（实现时用临时文件或 `set -- $()` 收集；计划评审点：**必须修正子 shell 变量问题**，采用 `entries=$(ls -A ... | while ... ; done)` 后 printf）。

**Verify（宿主）:** fixture 目录 `tests/fixtures/share/Movies/a.mp4` → `QUERY_STRING='path=/Movies' ./www/cgi-bin/files` 输出含 `"name":"a.mp4"`；`path=/../etc` → `{"error":"forbidden"}`。

**Commit:** `feat(overlay): files CGI with whitelist root + traversal guard`

---

### Task 10: `www/cgi-bin/license-import`（Ed25519 验证，宿主真实测试）

**Files:**
- Create: `www/cgi-bin/license-import`
- Create: `tests/fixtures/keys/ed25519-test-pub.pem`（测试专用公钥）
- Create: `tests/gen-test-license.sh`（生成测试信封：openssl genpkey ed25519 → 签 payload）
- Test: `tests/test-license-import.sh`

信封格式（POST body，≤8KB）:

```
TINYNAS-LICENSE-V1
<base64(payload-json)>
<base64(signature)>
```

payload JSON（**时间用 epoch 整数**，规避 busybox date 解析；文档 V1/5 的 ISO 字段在实现注记中声明为序列化差异）:

```json
{"license_id":"...","machine_id":"A7B3C9D2E8F50147","sku":"tinynas-pro","features":["local_files","download_push"],"partner_id":"test","channel":"stable","issued_at":1725235200,"support_until":1893456000,"license_version":1}
```

license-import 核心:

```sh
#!/bin/sh
printf 'Content-Type: application/json\r\n\r\n'
PUB=/etc/tinynas/ed25519-pub.key
M=/usr/bin/tinynas-machine-id
[ -x "$M" ] || { printf '{"status":"error","msg":"not ready · machine-id missing · retry"}'; exit 0; }
[ -s "$PUB" ] || { printf '{"status":"error","msg":"公钥缺失 · 联系发行方 · 重试"}'; exit 0; }
# 读 body（CONTENT_LENGTH 上限 8192）
n=${CONTENT_LENGTH:-0}; [ "$n" -gt 8192 ] && { printf '{"status":"error","msg":"许可证过大 · 检查文件 · 重试"}'; exit 0; }
body=$(head -c "$n" 2>/dev/null); [ -n "$body" ] || body=$(cat)
ok=$(printf '%s\n' "$body" | awk 'NR==1&&$0=="TINYNAS-LICENSE-V1"{f=1;next} NR==2{print $1; exit}')
sig=$(printf '%s\n' "$body" | awk 'NR==3{print $1; exit}')
echo_b64() printf '%s' "$1" | openssl base64 -d -A 2>/dev/null
[ "$ok" = "1" ] && [ -n "$sig" ] || { printf '{"status":"error","msg":"格式错误 · 需要 V1 信封 · 重试"}'; exit 0; }
tmp=$(mktemp)
echo_b64 "$ok" > "$tmp.payload" && echo_b64 "$sig" > "$tmp.sig" || { rm -f $tmp.*; printf '{"status":"error","msg":"base64 解码失败 · 重试"}'; exit 0; }
if openssl pkeyutl -verify -pubin -inkey "$PUB" -rawin -in "$tmp.payload" -sigfile "$tmp.sig" >/dev/null 2>&1; then
    machine_id=$($M --display)
    pm=$(jsonfilter -s "$(cat $tmp.payload)" -e '@.machine_id' 2>/dev/null)
    now=$(date +%s)
    iat=$(jsonfilter -s "$(cat $tmp.payload)" -e '@.issued_at' 2>/dev/null)
    sup=$(jsonfilter -s "$(cat $tmp.payload)" -e '@.support_until' 2>/dev/null)
    if [ "$pm" != "$machine_id" ]; then printf '{"status":"error","msg":"证书与本机不匹配 · 核对 machine_id · 重试"}'
    elif [ -z "$iat" ] || [ "$now" -lt "$iat" ] || { [ -n "$sup" ] && [ "$now" -gt "$sup" ]; }; then
        printf '{"status":"error","msg":"证书不在有效期 · 联系卖家 · 重试"}'
    else
        lid=$(jsonfilter -s "$(cat $tmp.payload)" -e '@.license_id' 2>/dev/null)
        printf 'machine_id=%s\nlicense_id=%s\nactivated_at=%s\n' "$machine_id" "$lid" "$now" > /etc/tinynas/.activated
        /etc/init.d/tinynas-boot start 2>/dev/null
        printf '{"status":"ok","machine_id":"%s"}' "$machine_id"
    fi
else
    printf '{"status":"error","msg":"签名验证失败 · 核对许可证 · 重试"}'
fi
rm -f "$tmp.payload" "$tmp.sig"
```

> jsonfilter 在宿主 macOS 不存在：实现时 jsonfilter 调用封装为 `payload_get() { jsonfilter ... } ` + 宿主 fallback（python3 -c json）由 `TINYNAS_JSONPARSE=python` 切换，保证宿主可测；目标机用 jsonfilter。**测试键仅测试用**，绝不用于生产。

**Verify:**

```bash
TINYNAS_SYSINFO_ROOT=... TINYNAS_PUB=$PWD/tests/fixtures/keys/ed25519-test-pub.pem TINYNAS_JSONPARSE=python \
  tests/test-license-import.sh   # 正签名 → status ok；篡改 payload 一字节 → 签名失败
```

**Commit:** `feat(overlay): Ed25519 license-import CGI + host testkit`

---

### Task 11: `www/tinynas-wizard.html`（≤50KB 零依赖）

**Files:** Create: `www/tinynas-wizard.html`

单文件：内联 CSS（设计令牌 `#0a8ba9/#113a45/#eef5f7/#163038/#087c59/#bd3e3e` 等来自 DNA §3）、内联 JS；三区块 = ①机器码+复制（QR 二维码**延后 S2**：需 vendor QR 编码库，先交"文本+复制"避免超预算）②配对码 ③许可证导入 textarea → POST /cgi-bin/license-import → 成功 3-2-1 跳 `/`；错误三段式文案；零外部资源。

**Verify:**

```bash
wc -c < www/tinynas-wizard.html   # ≤ 51200
grep -cE '(src|href)="https?://' www/tinynas-wizard.html   # 0
```

**Commit:** `feat(overlay): first-boot wizard (single-file, zero-external, token-compliant)`

---

### Task 12: `etc/hotplug.d/block/50-tinynas-disk` + 清理 .gitkeep + README

**Files:** Create: `etc/hotplug.d/block/50-tinynas-disk`；Delete: 全部 `.gitkeep`；Modify: `common/tinynas-files/README.md`

hotplug（**不挂载**，只做附加动作，序号>10）:

```sh
#!/bin/sh
# 磁盘健康前置钩子：新机械盘触发快扫（tinynas-disk-check 属 P1，存在才调用）
[ "$ACTION" = "add" ] || exit 0
case "$DEVNAME" in sd[a-z]) :;; *) exit 0;; esac
[ "$(cat /sys/block/$DEVNAME/queue/rotational 2>/dev/null)" = "1" ] || exit 0
if [ -x /usr/bin/tinynas-disk-check ]; then
    logger -t tinynas "new HDD $DEVNAME — quick scan queued"
    (/usr/bin/tinynas-disk-check "/dev/$DEVNAME" quick >/dev/null 2>&1 &)
else
    logger -t tinynas "new HDD $DEVNAME detected (disk-check not installed)"
fi
```

README 重写为实际目录清单 + 军规引用（替换"空骨架"过时描述）。

**Verify:** `find . -name .gitkeep | wc -l` → 0。

**Commit:** `feat(overlay): disk hotplug hook + drop gitkeep + README refresh`

---

### Task 13: build-template.sh 五项变更

**Files:** Modify: `common/build-template.sh`

1. 产物收集 glob 追加 `"bin/targets/${TARGET_PATH}/"*rootfs.tar.gz`（kind=rootfs）
2. 覆盖层拷入后：`find files/etc/init.d files/www/cgi-bin files/usr/bin -type f ! -perm -u+x -print | grep . && fail`（权限审计）
3. 密钥注入：`${TINYNAS_ED25519_PUBKEY:+cp → files/etc/tinynas/ed25519-pub.key}`，缺省则拷 `ed25519-pub.key.example` + warn
4. 零外链门禁：`grep -rE '(src|href)="https?://' files/www/ && fail`
5. init.d lint：`for f in files/etc/init.d/*; do head -1 | grep -q rc.common || fail; sed -n 2p | grep -q '^START=' || fail; done`

**Verify:** `bash -n build-template.sh`；grep 断言五处变更存在。

**Commit:** `feat(build): rootfs.tar.gz collection + pubkey injection + 3 gates`

---

### Task 14: `tests/run-lint.sh` 总门禁 + 全量回归

**Files:** Create: `common/tinynas-files/tests/run-lint.sh`

门禁清单（8 军规静态化）：①init.d shebang+START ②无 /etc/rc.d 写入 ③uci-defaults 尾 exit 0 ④cgi-bin 全部 +x ⑤无外部 src/href ⑥无 shell 拼接特征（`$(...$` 白名单外）⑦wizard ≤51200B ⑧信封版本行存在。附带运行 test-machine-id / test-license-import / CGI 宿主行为测试。

**Verify:** `tests/run-lint.sh` → 全 PASS 退出码 0。

**Commit:** `test(overlay): consolidated lint + behavior gate (8 military rules)`

---

### 待验项（S1.5 收尾，需环境）

- POC P1：Docker 跑 `arch/x86_64` build.sh，确认 IB 产出 `*-rootfs.tar.gz` → 决定 Task 13.1 收集逻辑是否生效
- POC P2：镜像内存在 `/etc/rc.d/S99tinynas-boot` 与 `/www/tinynas-wizard.html`
- POC P7：目标机 Ed25519 真实验证（宿主 SKIP 场景的兜底）

## Execution Handoff

计划保存于 `docs/plan/2026-09-02-overlay-v1-implementation.md`。选择：**1. Subagent-Driven（本会话逐任务派发+评审）** 或 **2. 主会话直接 executing-plans 顺序执行**。鉴于任务间强共享上下文（fixture/期望值/军规门禁），**推荐 2**。
