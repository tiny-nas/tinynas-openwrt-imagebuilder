#!/usr/bin/env bash
# TinyNAS 锦盒 - armvirt-64 架构打包入口
# 调用 common/build-template.sh，传入 armvirt-64 专属参数
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE="${SCRIPT_DIR}/../../common/build-template.sh"

[ -x "${TEMPLATE}" ] || { echo "未找到 ${TEMPLATE}"; exit 1; }

# armvirt-64 在 OpenWrt 23.05.3 上的 target 路径为 armvirt/64
# PROFILE 默认 generic（适合绝大多数 ARMv8 通用平台）
exec "${TEMPLATE}" \
    "armvirt/64" \
    "23.05.3" \
    "generic" \
    "armvirt-64" \
    "${1:-stable}" \
    "${2:-1.0.0}"