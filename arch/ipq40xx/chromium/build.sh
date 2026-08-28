#!/usr/bin/env bash
# TinyNAS 简盒 - 高通 IPQ40xx 路由器 (ipq40xx-chromium) 打包入口
# 调用 common/build-template.sh，传入 ipq40xx-chromium 专属参数
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE="${SCRIPT_DIR}/../../common/build-template.sh"

[ -x "${TEMPLATE}" ] || { echo "未找到 ${TEMPLATE}"; exit 1; }

# OpenWrt 25.12.5 上的 target 路径: ipq40xx-chromium
# PROFILE 默认: generic
exec "${TEMPLATE}" \
    "ipq40xx-chromium" \
    "25.12.5" \
    "generic" \
    "ipq40xx-chromium" \
    "${1:-stable}" \
    "${2:-1.0.0}"
