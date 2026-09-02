#!/usr/bin/env bash
# 锦盒 TinyNAS - N1 链路端到端构建脚本
# 链路：IB (armsr/armv8) → rootfs.tar.gz → ophub remake -b s905d → N1 镜像
#
# 用法：sudo ./build-n1.sh [CHANNEL] [VERSION] [TIER] [KERNEL]
# 示例：sudo ./build-n1.sh stable 1.0.0 pro 6.12.y
#
# 前置条件：
#   1. Linux x86_64/aarch64 主机，root 权限
#   2. amlogic-s9xxx-openwrt 仓库已 clone 到本仓库同级目录
#   3. common/tinynas-files/ 覆盖层已就绪

set -euo pipefail

CHANNEL="${1:-stable}"
VERSION="${2:-1.0.0}"
TIER="${3:-pro}"
KERNEL="${4:-6.12.y}"
DATE=$(date +%Y.%m.%d)

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
OUTPUT_DIR="${REPO_ROOT}/output-n1"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
log()  { echo -e "${GREEN}[+]${NC} $*"; }
warn() { echo -e "${YELLOW}[!]${NC} $*"; }
fail() { echo -e "${RED}[x]${NC} $*" >&2; exit 1; }

log "TinyNAS N1 构建流程启动"
log "  档位: ${TIER} | 版本: ${VERSION} | 渠道: ${CHANNEL} | 内核: ${KERNEL}"

# ===================== Step 1: 前置检查 =====================
command -v make >/dev/null || fail "缺少 make（Image Builder 依赖）"
AMLOGIC_DIR="${REPO_ROOT}/../amlogic-s9xxx-openwrt"
[ -d "$AMLOGIC_DIR" ] || fail "未找到 amlogic-s9xxx-openwrt: ${AMLOGIC_DIR}"
[ -d "$AMLOGIC_DIR/openwrt-armsr" ] || mkdir -p "$AMLOGIC_DIR/openwrt-armsr"

# ===================== Step 2: IB 构建（arch/armsr-armv8） =====================
log "Step 2: 调用 build-template.sh 生成 rootfs.tar.gz..."
ARCH_BUILD_SH="${REPO_ROOT}/arch/armsr/armv8/build.sh"
[ -f "$ARCH_BUILD_SH" ] || fail "未找到 arch/armsr/armv8/build.sh（请先 checkout arch/armsr-armv8 分支）"

# 调用通用模板（TIER/VERSION/CHANNEL 通过环境变量传递）
cd "$REPO_ROOT/common"
TIER="$TIER" VERSION="$VERSION" CHANNEL="$CHANNEL" \
    bash build-template.sh "armsr/armv8" "25.12.5" "generic" "armsr-armv8" "$CHANNEL" "$VERSION" "$TIER"

# ===================== Step 3: 提取 rootfs.tar.gz =====================
IB_OUTPUT="${REPO_ROOT}/arch/armsr/armv8/output"
ROOTFS_GZ=$(find "$IB_OUTPUT" -name "*rootfs.tar.gz" ! -name "*targz*" | head -1)
[ -n "$ROOTFS_GZ" ] || fail "未找到 rootfs.tar.gz（IB 构建可能失败，请检查 ${IB_OUTPUT}/build-*.log）"

log "Step 3: 找到 rootfs.tar.gz: $(basename "$ROOTFS_GZ")"

# ===================== Step 4: 桥接到 ophub remake =====================
log "Step 4: 复制 rootfs.tar.gz 到 amlogic-s9xxx-openwrt/openwrt-armsr/..."
cp "$ROOTFS_GZ" "$AMLOGIC_DIR/openwrt-armsr/"
log "  已复制: $(basename "$ROOTFS_GZ")"

# ===================== Step 5: ophub remake =====================
log "Step 5: 执行 ophub remake -b s905d -k ${KERNEL}..."
cd "$AMLOGIC_DIR"
sudo ./remake -b s905d -k "$KERNEL"

# ===================== Step 6: 重命名为五段式命名 =====================
log "Step 6: 重命名产物..."
mkdir -p "$OUTPUT_DIR"
OPHUB_OUT=$(find "$AMLOGIC_DIR/openwrt/out" -name "openwrt_amlogic_s905d_k*.img.gz" | head -1)
[ -n "$OPHUB_OUT" ] || fail "未找到 ophub 产出（remake 可能失败）"

FINAL_NAME="openwrt_tinynas-${TIER}-n1_v${VERSION}-${CHANNEL}_${DATE}.img.gz"
cp "$OPHUB_OUT" "$OUTPUT_DIR/$FINAL_NAME"
sha256sum "$OUTPUT_DIR/$FINAL_NAME" > "$OUTPUT_DIR/${FINAL_NAME}.sha256"

log "✅ 完成: ${OUTPUT_DIR}/${FINAL_NAME}"
log "  sha256: $(cat "$OUTPUT_DIR/${FINAL_NAME}.sha256" | awk '{print $1}')"
