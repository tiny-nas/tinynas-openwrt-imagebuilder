#!/usr/bin/env bash
# TinyNAS 简盒 - Realtek RTL838x/RTL839x 交换机 (realtek-rtl931x) 打包入口
# 调用 common/build-template.sh，传入 realtek-rtl931x 专属参数
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE="${SCRIPT_DIR}/../../common/build-template.sh"

[ -x "${TEMPLATE}" ] || { echo "未找到 ${TEMPLATE}"; exit 1; }

# OpenWrt 25.12.5 上的 target 路径: realtek-rtl931x
# PROFILE 默认: generic
exec "${TEMPLATE}" \
    "realtek-rtl931x" \
    "25.12.5" \
    "generic" \
    "realtek-rtl931x" \
    "${1:-stable}" \
    "${2:-1.0.0}"
