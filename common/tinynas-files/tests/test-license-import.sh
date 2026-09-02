#!/bin/sh
# 行为测试：license-import Ed25519 全链路（宿主可跑，要求 openssl 支持 -rawin）
# 覆盖：正签名 ok / 篡改 payload → 签名失败 / 错误 machine_id → 不匹配 / 过期 → 有效期拒绝
HERE=$(cd "$(dirname "$0")" && pwd)
CGI="$HERE/../www/cgi-bin/license-import"
GEN="$HERE/gen-test-license.sh"
PUB="$HERE/fixtures/keys/ed25519-test-pub.pem"
MACHINE_ID=40F6598739D3B481
FAIL=0

if ! openssl pkeyutl -help 2>&1 | grep -q rawin; then
    echo "SKIP test-license-import (host openssl lacks -rawin; gate at POC P7)"; exit 0
fi
for f in "$CGI" "$GEN"; do [ -x "$f" ] || { echo "FAIL: $f missing"; exit 1; }; done

STATE=$(mktemp -d)
run_cgi() { # $1=body
    CONTENT_LENGTH=${#1} TINYNAS_PUB="$PUB" TINYNAS_MACHINE_ID="$HERE/../usr/bin/tinynas-machine-id" \
    TINYNAS_SYSINFO_ROOT="$HERE/fixtures/sysinfo" TINYNAS_STATE_DIR="$STATE" \
    sh "$CGI" <<< "$1" | sed '1,2d'
}

# 1) 正签名 → ok
BODY=$("$GEN" "$MACHINE_ID")
R=$(run_cgi "$BODY")
echo "$R" | grep -q '"status":"ok"' || { echo "FAIL valid license: $R"; FAIL=1; }
[ -f "$STATE/.activated" ] || { echo "FAIL .activated not written"; FAIL=1; }

# 2) 篡改 payload（保签名，仅改 b64 第 2 行末字符）→ 签名失败
L1=$(printf '%s\n' "$BODY" | sed -n 1p)
L2=$(printf '%s\n' "$BODY" | sed -n 2p | sed 's/.$/A/')
L3=$(printf '%s\n' "$BODY" | sed -n 3p)
TAMPER_BODY=$(printf '%s\n%s\n%s\n' "$L1" "$L2" "$L3")
R=$(run_cgi "$TAMPER_BODY")
echo "$R" | grep -q '签名验证失败' || { echo "FAIL tamper not rejected: $R"; FAIL=1; }

# 3) 错误 machine_id → 不匹配
R=$(run_cgi "$("$GEN" 00000000000000000000000000000000)")
echo "$R" | grep -q '不匹配' || { echo "FAIL wrong machine not rejected: $R"; FAIL=1; }

# 4) 过期 → 有效期拒绝
R=$(run_cgi "$("$GEN" "$MACHINE_ID" --expired)")
echo "$R" | grep -q '有效期' || { echo "FAIL expired not rejected: $R"; FAIL=1; }

rm -rf "$STATE"
[ $FAIL -eq 0 ] && echo "PASS test-license-import"
exit $FAIL
