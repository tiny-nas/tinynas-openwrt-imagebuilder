#!/usr/bin/env bash
# TinyNAS 锦盒 - 高通 IPQ50xx/60xx/807x 高端路由器 (qualcommax-ipq807x) 打包入口
# 调用 common/build-template.sh，传入 qualcommax-ipq807x 专属参数
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE="${SCRIPT_DIR}/../../common/build-template.sh"

[ -x "${TEMPLATE}" ] || { echo "未找到 ${TEMPLATE}"; exit 1; }

# OpenWrt 25.12.5 上的 target 路径: qualcommax-ipq807x
# PROFILE 默认: generic
exec "${TEMPLATE}" \
    "qualcommax-ipq807x" \
    "25.12.5" \
    "generic" \
    "qualcommax-ipq807x" \
    "${1:-stable}" \
    "${2:-1.0.0}"
