#!/usr/bin/env bash
# TinyNAS 锦盒 - Microchip AT91 SAM9/SAMA5/SAMA7 (at91-sama7) 打包入口
# 调用 common/build-template.sh，传入 at91-sama7 专属参数
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE="${SCRIPT_DIR}/../../common/build-template.sh"

[ -x "${TEMPLATE}" ] || { echo "未找到 ${TEMPLATE}"; exit 1; }

# OpenWrt 25.12.5 上的 target 路径: at91-sama7
# PROFILE 默认: generic
exec "${TEMPLATE}" \
    "at91-sama7" \
    "25.12.5" \
    "generic" \
    "at91-sama7" \
    "${1:-stable}" \
    "${2:-1.0.0}"
