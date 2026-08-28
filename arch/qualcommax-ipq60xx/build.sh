#!/usr/bin/env bash
# TinyNAS 简盒 - 高通 IPQ50xx/60xx/807x 高端路由器 (qualcommax-ipq60xx) 打包入口
# 调用 common/build-template.sh，传入 qualcommax-ipq60xx 专属参数
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE="${SCRIPT_DIR}/../../common/build-template.sh"

[ -x "${TEMPLATE}" ] || { echo "未找到 ${TEMPLATE}"; exit 1; }

# OpenWrt 25.12.5 上的 target 路径: qualcommax-ipq60xx
# PROFILE 默认: generic
exec "${TEMPLATE}" \
    "qualcommax-ipq60xx" \
    "25.12.5" \
    "generic" \
    "qualcommax-ipq60xx" \
    "${1:-stable}" \
    "${2:-1.0.0}"
