#!/usr/bin/env bash
# TinyNAS 锦盒 - Allwinner ARM9/A7/A8/A53 SBC (sunxi-cortexa53) 打包入口
# 调用 common/build-template.sh，传入 sunxi-cortexa53 专属参数
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE="${SCRIPT_DIR}/../../common/build-template.sh"

[ -x "${TEMPLATE}" ] || { echo "未找到 ${TEMPLATE}"; exit 1; }

# OpenWrt 25.12.5 上的 target 路径: sunxi-cortexa53
# PROFILE 默认: generic
exec "${TEMPLATE}" \
    "sunxi-cortexa53" \
    "25.12.5" \
    "generic" \
    "sunxi-cortexa53" \
    "${1:-stable}" \
    "${2:-1.0.0}"
