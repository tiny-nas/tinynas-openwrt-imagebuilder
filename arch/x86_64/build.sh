#!/usr/bin/env bash
# TinyNAS 锦盒 - x86_64 架构打包入口
# 调用 common/build-template.sh，传入 x86_64 专属参数
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE="${SCRIPT_DIR}/../../common/build-template.sh"

[ -x "${TEMPLATE}" ] || { echo "未找到 ${TEMPLATE}"; exit 1; }

# x86_64 在 OpenWrt 23.05.3 上的 target 路径为 x86_64
# PROFILE 默认 generic（适合大多数 x86_64 迷你主机：NUC、迷你PC、工控机）
exec "${TEMPLATE}" \
    "x86_64" \
    "23.05.3" \
    "generic" \
    "x86_64" \
    "${1:-stable}" \
    "${2:-1.0.0}"