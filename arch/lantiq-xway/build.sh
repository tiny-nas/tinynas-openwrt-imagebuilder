#!/usr/bin/env bash
# TinyNAS 简盒 - Lantiq xRX/xWAY DSL 路由器 (lantiq-xway) 打包入口
# 调用 common/build-template.sh，传入 lantiq-xway 专属参数
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE="${SCRIPT_DIR}/../../common/build-template.sh"

[ -x "${TEMPLATE}" ] || { echo "未找到 ${TEMPLATE}"; exit 1; }

# OpenWrt 25.12.5 上的 target 路径: lantiq-xway
# PROFILE 默认: generic
exec "${TEMPLATE}" \
    "lantiq-xway" \
    "25.12.5" \
    "generic" \
    "lantiq-xway" \
    "${1:-stable}" \
    "${2:-1.0.0}"
