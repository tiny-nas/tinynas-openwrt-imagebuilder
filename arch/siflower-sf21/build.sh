#!/usr/bin/env bash
# TinyNAS 简盒 - 矽力杰 SF21xx (siflower-sf21) 打包入口
# 调用 common/build-template.sh，传入 siflower-sf21 专属参数
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE="${SCRIPT_DIR}/../../common/build-template.sh"

[ -x "${TEMPLATE}" ] || { echo "未找到 ${TEMPLATE}"; exit 1; }

# OpenWrt 25.12.5 上的 target 路径: siflower-sf21
# PROFILE 默认: generic
exec "${TEMPLATE}" \
    "siflower-sf21" \
    "25.12.5" \
    "generic" \
    "siflower-sf21" \
    "${1:-stable}" \
    "${2:-1.0.0}"
