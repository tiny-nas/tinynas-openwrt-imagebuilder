#!/usr/bin/env bash
# TinyNAS 简盒 - Freescale P10xx/P20xx PowerPC (mpc85xx-p1010) 打包入口
# 调用 common/build-template.sh，传入 mpc85xx-p1010 专属参数
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE="${SCRIPT_DIR}/../../common/build-template.sh"

[ -x "${TEMPLATE}" ] || { echo "未找到 ${TEMPLATE}"; exit 1; }

# OpenWrt 25.12.5 上的 target 路径: mpc85xx-p1010
# PROFILE 默认: generic
exec "${TEMPLATE}" \
    "mpc85xx-p1010" \
    "25.12.5" \
    "generic" \
    "mpc85xx-p1010" \
    "${1:-stable}" \
    "${2:-1.0.0}"
