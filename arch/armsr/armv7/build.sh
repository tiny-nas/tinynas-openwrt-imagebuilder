#!/usr/bin/env bash
# TinyNAS 简盒 - ARMv7 软路由（x86 类通用） (armsr-armv7) 打包入口
# 调用 common/build-template.sh，传入 armsr-armv7 专属参数
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE="${SCRIPT_DIR}/../../common/build-template.sh"

[ -x "${TEMPLATE}" ] || { echo "未找到 ${TEMPLATE}"; exit 1; }

# OpenWrt 25.12.5 上的 target 路径: armsr-armv7
# PROFILE 默认: generic
exec "${TEMPLATE}" \
    "armsr-armv7" \
    "25.12.5" \
    "generic" \
    "armsr-armv7" \
    "${1:-stable}" \
    "${2:-1.0.0}"
