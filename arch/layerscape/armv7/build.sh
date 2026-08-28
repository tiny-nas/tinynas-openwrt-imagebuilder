#!/usr/bin/env bash
# TinyNAS 锦盒 - NXP Layerscape 服务器级 ARM (layerscape-armv7) 打包入口
# 调用 common/build-template.sh，传入 layerscape-armv7 专属参数
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE="${SCRIPT_DIR}/../../common/build-template.sh"

[ -x "${TEMPLATE}" ] || { echo "未找到 ${TEMPLATE}"; exit 1; }

# OpenWrt 25.12.5 上的 target 路径: layerscape-armv7
# PROFILE 默认: generic
exec "${TEMPLATE}" \
    "layerscape-armv7" \
    "25.12.5" \
    "generic" \
    "layerscape-armv7" \
    "${1:-stable}" \
    "${2:-1.0.0}"
