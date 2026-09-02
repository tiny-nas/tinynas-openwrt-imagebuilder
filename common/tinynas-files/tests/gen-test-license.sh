#!/bin/sh
# gen-test-license.sh — 生成 Ed25519 测试许可证信封（仅测试用密钥，绝不用于生产）
# 用法: gen-test-license.sh <display_machine_id> [--expired]
# 注意: Ed25519 签名必须用 `pkeyutl -rawin`，不能用 `dgst -sha256 -sign`
KEY="$(cd "$(dirname "$0")" && pwd)/fixtures/keys/ed25519-test-priv.pem"
MID="${1:?usage: gen-test-license.sh <machine_id> [--expired]}"
NOW=$(date +%s)
if [ "$2" = "--expired" ]; then IAT=1000000000; SUP=1500000000; else IAT=$((NOW-86400)); SUP=$((NOW+31536000)); fi
PAYLOAD=$(printf '{"license_id":"test-001","machine_id":"%s","sku":"tinynas-pro","features":["local_files","download_push"],"partner_id":"test","channel":"stable","issued_at":%s,"support_until":%s,"license_version":1}' "$MID" "$IAT" "$SUP")
B64=$(printf '%s' "$PAYLOAD" | openssl base64 -A)
tmp=$(mktemp)
printf '%s' "$PAYLOAD" > "$tmp"
openssl pkeyutl -sign -inkey "$KEY" -rawin -in "$tmp" -out "$tmp.sig" 2>/dev/null || {
    rm -f "$tmp" "$tmp.sig"; echo "sign failed" >&2; exit 1; }
SIG=$(openssl base64 -A < "$tmp.sig")
rm -f "$tmp" "$tmp.sig"
printf 'TINYNAS-LICENSE-V1\n%s\n%s\n' "$B64" "$SIG"
