#!/usr/bin/env bash
# TinyNAS 简盒 - 瑞芯微 RK3328/RK3399/RK3568 等 ARMv8 SBC (rockchip-armv8) 打包入口
# 调用 common/build-template.sh，传入 rockchip-armv8 专属参数
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE="${SCRIPT_DIR}/../../common/build-template.sh"

[ -x "${TEMPLATE}" ] || { echo "未找到 ${TEMPLATE}"; exit 1; }

# OpenWrt 25.12.5 上的 target 路径: rockchip-armv8
# PROFILE 默认: generic
exec "${TEMPLATE}" \
    "rockchip-armv8" \
    "25.12.5" \
    "generic" \
    "rockchip-armv8" \
    "${1:-stable}" \
    "${2:-1.0.0}"
