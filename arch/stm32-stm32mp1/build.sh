#!/usr/bin/env bash
# TinyNAS 锦盒 - STMicro STM32MP1 (stm32-stm32mp1) 打包入口
# 调用 common/build-template.sh，传入 stm32-stm32mp1 专属参数
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE="${SCRIPT_DIR}/../../common/build-template.sh"

[ -x "${TEMPLATE}" ] || { echo "未找到 ${TEMPLATE}"; exit 1; }

# OpenWrt 25.12.5 上的 target 路径: stm32-stm32mp1
# PROFILE 默认: generic
exec "${TEMPLATE}" \
    "stm32-stm32mp1" \
    "25.12.5" \
    "generic" \
    "stm32-stm32mp1" \
    "${1:-stable}" \
    "${2:-1.0.0}"
