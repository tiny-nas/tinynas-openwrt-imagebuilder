#!/usr/bin/env bash
# 锦盒 TinyNAS - MediaTek MT7621 路由器 (ramips/mt7621) 打包入口
# 覆盖小米/红米等 MT7621 机型（见本目录 README.md 支持机型表）
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE="${SCRIPT_DIR}/../../common/build-template.sh"

[ -x "${TEMPLATE}" ] || { echo "未找到 ${TEMPLATE}"; exit 1; }

# 用法: ./build.sh [渠道] [版本] [PROFILE] [档位]
#   ./build.sh                                              # generic + lite
#   ./build.sh stable 1.0.0 xiaomi_mi-router-4a-gigabit lite
#   TIER=edge ./build.sh stable 1.0.0 xiaomi_mi-router-3g
#
# 可用 PROFILE 见 profiles/ 目录（与 OpenWrt 25.12.5 设备定义一致）
# 本分支默认档位 lite（路由器属 Lite 级硬件）
PROFILE="${3:-generic}"
TIER="${4:-${TIER:-lite}}"

case "${TIER}" in
  pro|edge|lite) ;;
  *) echo "非法档位: ${TIER}（仅 pro / edge / lite）"; exit 1 ;;
esac

exec "${TEMPLATE}" \
    "ramips/mt7621" \
    "25.12.5" \
    "${PROFILE}" \
    "ramips-mt7621" \
    "${1:-stable}" \
    "${2:-1.0.0}" \
    "${TIER}"
