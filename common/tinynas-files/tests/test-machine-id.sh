#!/bin/sh
# 行为测试：tinynas-machine-id fixture 注入 + 期望值断言
# 期望值由 python3 独立生成（2026-09-02，算法：v1 + 4hex-len-prefixed 五字段 SHA256）：
#   digest  40f6598739d3b481b088476cff9c2df3be9e114f626dcc12821a313ee5d729cc
#   display 40F6598739D3B481   device tn_40f6598739d3b481b088476c
# 字段: board=phicomm_n1 cid=0000000000001234 serial=0000000000000000 mac=aabbccddeeff compat=gxl
HERE=$(cd "$(dirname "$0")" && pwd)
export TINYNAS_SYSINFO_ROOT="$HERE/fixtures/sysinfo"
M="$HERE/../usr/bin/tinynas-machine-id"
[ -x "$M" ] || { echo "FAIL: machine-id missing or not executable"; exit 1; }
OUT=$("$M" --display)
DIG=$("$M" --digest)
DEV=$("$M" --device)
echo "$DIG" | grep -qE '^[0-9a-f]{64}$' || { echo "FAIL digest format: $DIG"; exit 1; }
echo "$OUT" | grep -qE '^[0-9A-F]{16}$' || { echo "FAIL display format: $OUT"; exit 1; }
case "$DEV" in tn_[0-9a-f]*) : ;; *) echo "FAIL device prefix: $DEV"; exit 1;; esac
[ "$OUT" = "40F6598739D3B481" ] || { echo "FAIL display=$OUT want=40F6598739D3B481"; exit 1; }
[ "$DEV" = "tn_40f6598739d3b481b088476c" ] || { echo "FAIL device=$DEV"; exit 1; }
echo "PASS test-machine-id"
