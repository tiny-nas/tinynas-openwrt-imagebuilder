#!/usr/bin/env bash
# TinyNAS 简盒 - NXP i.MX 6/7/8 SBC (imx-cortexa7) 打包入口
# 调用 common/build-template.sh，传入 imx-cortexa7 专属参数
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE="${SCRIPT_DIR}/../../common/build-template.sh"

[ -x "${TEMPLATE}" ] || { echo "未找到 ${TEMPLATE}"; exit 1; }

# OpenWrt 25.12.5 上的 target 路径: imx-cortexa7
# PROFILE 默认: generic
exec "${TEMPLATE}" \
    "imx-cortexa7" \
    "25.12.5" \
    "generic" \
    "imx-cortexa7" \
    "${1:-stable}" \
    "${2:-1.0.0}"
