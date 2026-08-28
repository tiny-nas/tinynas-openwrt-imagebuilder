#!/usr/bin/env bash
# TinyNAS 锦盒 - StarFive JH7100/VisionFive (starfive-generic) 打包入口
# 调用 common/build-template.sh，传入 starfive-generic 专属参数
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE="${SCRIPT_DIR}/../../common/build-template.sh"

[ -x "${TEMPLATE}" ] || { echo "未找到 ${TEMPLATE}"; exit 1; }

# OpenWrt 25.12.5 上的 target 路径: starfive-generic
# PROFILE 默认: generic
exec "${TEMPLATE}" \
    "starfive-generic" \
    "25.12.5" \
    "generic" \
    "starfive-generic" \
    "${1:-stable}" \
    "${2:-1.0.0}"
