#!/usr/bin/env bash
# TinyNAS 简盒 - Marvell ARMADA 38x/37x/70xx 路由器 (mvebu-cortexa9) 打包入口
# 调用 common/build-template.sh，传入 mvebu-cortexa9 专属参数
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE="${SCRIPT_DIR}/../../common/build-template.sh"

[ -x "${TEMPLATE}" ] || { echo "未找到 ${TEMPLATE}"; exit 1; }

# OpenWrt 25.12.5 上的 target 路径: mvebu-cortexa9
# PROFILE 默认: generic
exec "${TEMPLATE}" \
    "mvebu-cortexa9" \
    "25.12.5" \
    "generic" \
    "mvebu-cortexa9" \
    "${1:-stable}" \
    "${2:-1.0.0}"
