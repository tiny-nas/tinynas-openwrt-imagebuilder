#!/usr/bin/env bash
# TinyNAS 锦盒 - Intel XScale IXP4xx (ixp4xx-generic) 打包入口
# 调用 common/build-template.sh，传入 ixp4xx-generic 专属参数
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE="${SCRIPT_DIR}/../../common/build-template.sh"

[ -x "${TEMPLATE}" ] || { echo "未找到 ${TEMPLATE}"; exit 1; }

# OpenWrt 25.12.5 上的 target 路径: ixp4xx-generic
# PROFILE 默认: generic
exec "${TEMPLATE}" \
    "ixp4xx-generic" \
    "25.12.5" \
    "generic" \
    "ixp4xx-generic" \
    "${1:-stable}" \
    "${2:-1.0.0}"
