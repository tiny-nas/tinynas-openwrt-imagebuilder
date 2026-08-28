#!/usr/bin/env bash
# TinyNAS 简盒 - 树莓派 1-5（bcm2708/2709/2710/2711/2712） (bcm27xx-bcm2712) 打包入口
# 调用 common/build-template.sh，传入 bcm27xx-bcm2712 专属参数
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE="${SCRIPT_DIR}/../../common/build-template.sh"

[ -x "${TEMPLATE}" ] || { echo "未找到 ${TEMPLATE}"; exit 1; }

# OpenWrt 25.12.5 上的 target 路径: bcm27xx-bcm2712
# PROFILE 默认: generic
exec "${TEMPLATE}" \
    "bcm27xx-bcm2712" \
    "25.12.5" \
    "generic" \
    "bcm27xx-bcm2712" \
    "${1:-stable}" \
    "${2:-1.0.0}"
