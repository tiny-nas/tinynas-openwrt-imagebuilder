#!/usr/bin/env bash
# TinyNAS 简盒 - Atheros ath79 系列路由器 (ath79-mikrotik) 打包入口
# 调用 common/build-template.sh，传入 ath79-mikrotik 专属参数
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE="${SCRIPT_DIR}/../../common/build-template.sh"

[ -x "${TEMPLATE}" ] || { echo "未找到 ${TEMPLATE}"; exit 1; }

# OpenWrt 25.12.5 上的 target 路径: ath79-mikrotik
# PROFILE 默认: generic
exec "${TEMPLATE}" \
    "ath79-mikrotik" \
    "25.12.5" \
    "generic" \
    "ath79-mikrotik" \
    "${1:-stable}" \
    "${2:-1.0.0}"
