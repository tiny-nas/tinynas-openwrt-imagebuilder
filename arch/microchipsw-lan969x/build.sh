#!/usr/bin/env bash
# TinyNAS 锦盒 - Microchip LAN969x 交换机 (microchipsw-lan969x) 打包入口
# 调用 common/build-template.sh，传入 microchipsw-lan969x 专属参数
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE="${SCRIPT_DIR}/../../common/build-template.sh"

[ -x "${TEMPLATE}" ] || { echo "未找到 ${TEMPLATE}"; exit 1; }

# OpenWrt 25.12.5 上的 target 路径: microchipsw-lan969x
# PROFILE 默认: generic
exec "${TEMPLATE}" \
    "microchipsw-lan969x" \
    "25.12.5" \
    "generic" \
    "microchipsw-lan969x" \
    "${1:-stable}" \
    "${2:-1.0.0}"
