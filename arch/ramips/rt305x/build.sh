#!/usr/bin/env bash
# TinyNAS 简盒 - MediaTek MT7620/MT7621/MT76x8/RT305x/RT3883 路由器 (ramips-rt305x) 打包入口
# 调用 common/build-template.sh，传入 ramips-rt305x 专属参数
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE="${SCRIPT_DIR}/../../common/build-template.sh"

[ -x "${TEMPLATE}" ] || { echo "未找到 ${TEMPLATE}"; exit 1; }

# OpenWrt 25.12.5 上的 target 路径: ramips-rt305x
# PROFILE 默认: rt305x
exec "${TEMPLATE}" \
    "ramips-rt305x" \
    "25.12.5" \
    "rt305x" \
    "ramips-rt305x" \
    "${1:-stable}" \
    "${2:-1.0.0}"
