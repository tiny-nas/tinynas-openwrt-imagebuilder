#!/usr/bin/env bash
# TinyNAS 锦盒 - MIPS Malta 评估板 (malta-le) 打包入口
# 调用 common/build-template.sh，传入 malta-le 专属参数
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE="${SCRIPT_DIR}/../../common/build-template.sh"

[ -x "${TEMPLATE}" ] || { echo "未找到 ${TEMPLATE}"; exit 1; }

# OpenWrt 25.12.5 上的 target 路径: malta-le
# PROFILE 默认: generic
exec "${TEMPLATE}" \
    "malta-le" \
    "25.12.5" \
    "generic" \
    "malta-le" \
    "${1:-stable}" \
    "${2:-1.0.0}"
