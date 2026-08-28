#!/usr/bin/env bash
# TinyNAS 锦盒 - MediaTek MT7620/MT7621/MT76x8/RT305x/RT3883 路由器 (ramips-mt7620) 打包入口
# 调用 common/build-template.sh，传入 ramips-mt7620 专属参数
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE="${SCRIPT_DIR}/../../common/build-template.sh"

[ -x "${TEMPLATE}" ] || { echo "未找到 ${TEMPLATE}"; exit 1; }

# OpenWrt 25.12.5 上的 target 路径: ramips-mt7620
# PROFILE 默认: generic
exec "${TEMPLATE}" \
    "ramips-mt7620" \
    "25.12.5" \
    "generic" \
    "ramips-mt7620" \
    "${1:-stable}" \
    "${2:-1.0.0}"
