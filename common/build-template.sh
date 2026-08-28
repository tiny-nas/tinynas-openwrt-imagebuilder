#!/usr/bin/env bash
# 锦盒 TinyNAS - OpenWrt Image Builder 打包模板
# 由各 arch/<name>/build.sh 调用，传入：
#   $1 = OPENWRT_TARGET_DIR  (例如 "x86_64" / "ramips/mt7621" / "armvirt/64")
#   $2 = OPENWRT_VERSION     (例如 "25.12.5")
#   $3 = PROFILE             (例如 "generic" / "xiaomi_router_ac2100")
#   $4 = DEVICE_TAG          (用于产物名，如 "x86_64" / "ramips-mt7621")
#   $5 = CHANNEL             (默认 "stable")
#   $6 = VERSION             (默认 "1.0.0")
#   $7 = TIER                (默认 "pro"；或用环境变量 TIER=lite 覆盖)
#
# 产物命名：openwrt_tinynas-${TIER}-${DEVICE_TAG}_v${VERSION}-${CHANNEL}_${DATE}.img.gz
set -euo pipefail

# --------- 参数与默认值 ---------
TARGET_DIR="${1:-x86_64}"
OPENWRT_VERSION="${2:-23.05.3}"
PROFILE="${3:-generic}"
DEVICE_TAG="${4:-x86_64}"
CHANNEL="${5:-stable}"
VERSION="${6:-1.0.0}"
TIER="${7:-${TIER:-pro}}"
DATE=$(date +%Y.%m.%d)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# SCRIPT_DIR = common/ ; REPO_ROOT = ../
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
TINYNAS_FILES="${SCRIPT_DIR}/tinynas-files"
ARCH_DIR="${REPO_ROOT}/arch/${DEVICE_TAG}"
OUTPUT_DIR="${ARCH_DIR}/output"
IB_CACHE="${REPO_ROOT}/ib-cache"
IB_DIR="${IB_CACHE}/openwrt-imagebuilder-${OPENWRT_VERSION}-${DEVICE_TAG}"

# --------- 颜色输出 ---------
if [ -t 1 ]; then
    GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
else
    GREEN=''; YELLOW=''; RED=''; NC=''
fi

log()  { echo -e "${GREEN}[+]${NC} $*"; }
warn() { echo -e "${YELLOW}[!]${NC} $*"; }
fail() { echo -e "${RED}[x]${NC} $*" >&2; exit 1; }

# --------- 1. 前置检查 ---------
log "TinyNAS 锦盒 打包流程启动"
log "  档位         : ${TIER}（pro / edge / lite）"
log "  架构        : ${DEVICE_TAG}"
log "  OpenWrt 版本: ${OPENWRT_VERSION}"
log "  Image Builder: ${TARGET_DIR}"
log "  PROFILE      : ${PROFILE}"
log "  版本         : v${VERSION}"
log "  渠道         : ${CHANNEL}"
log "  日期         : ${DATE}"

[ -d "${TINYNAS_FILES}" ] || fail "未找到 ${TINYNAS_FILES}，请确认仓库完整"
[ -d "${ARCH_DIR}" ]      || fail "未找到 ${ARCH_DIR}，请先创建 arch/${DEVICE_TAG} 目录"
command -v curl >/dev/null  || fail "缺少 curl"
command -v tar >/dev/null   || fail "缺少 tar"
command -v make >/dev/null  || fail "缺少 make（Image Builder 依赖）"

# --------- 2. 下载并解压 Image Builder（按需缓存）---------
# OpenWrt 23.05 及更早版本 Image Builder 为 .tar.xz；24.10+ 改为 .tar.zst
# 两种都尝试，按实际存在的格式解压
IB_BASE="https://downloads.openwrt.org/releases/${OPENWRT_VERSION}/targets/${TARGET_DIR}/openwrt-imagebuilder-${OPENWRT_VERSION}-${TARGET_DIR//\//-}.Linux-x86_64"
IB_TAR_ZST="${IB_BASE}.tar.zst"
IB_TAR_XZ="${IB_BASE}.tar.xz"

if [ -d "${IB_DIR}" ] && [ -x "${IB_DIR}/make" ]; then
    log "复用 IB 缓存: ${IB_DIR}"
else
    log "下载 Image Builder ..."
    mkdir -p "${IB_CACHE}"
    TAR_DECOMPRESS=()
    TMP_TAR="${IB_CACHE}/$(basename "${IB_TAR_ZST}")"
    if curl -fsSL --retry 3 -o "${TMP_TAR}" "${IB_TAR_ZST}"; then
        command -v zstd >/dev/null || fail "解压 .tar.zst 需要 zstd，请先安装（Ubuntu: sudo apt-get install -y zstd）"
        TAR_DECOMPRESS=(--zstd)
    else
        rm -f "${TMP_TAR}"
        log ".tar.zst 不存在（旧版本 OpenWrt），回退 .tar.xz ..."
        TMP_TAR="${IB_CACHE}/$(basename "${IB_TAR_XZ}")"
        curl -fsSL --retry 3 -o "${TMP_TAR}" "${IB_TAR_XZ}"
        TAR_DECOMPRESS=(-J)
    fi
    log "解压到 ${IB_DIR} ..."
    mkdir -p "${IB_DIR}"
    tar "${TAR_DECOMPRESS[@]}" -xf "${TMP_TAR}" -C "${IB_DIR}" --strip-components=1
fi

cd "${IB_DIR}"
log "IB 工作目录: $(pwd)"

# --------- 3. 注入 tinynas-files/ 覆盖层 ---------
log "注入覆盖层 ${TINYNAS_FILES} ..."
rm -rf files
mkdir -p files
cp -a "${TINYNAS_FILES}/." files/

# 让 arch 专属文件能覆盖通用文件
if [ -d "${ARCH_DIR}/files-overlay" ]; then
    log "注入架构专属覆盖层 ${ARCH_DIR}/files-overlay ..."
    cp -a "${ARCH_DIR}/files-overlay/." files/
fi

# 写入运行时档位/版本标识（dashboard 读取 /etc/tinynas/tier 隐藏不可用模块）
mkdir -p files/etc/tinynas
echo "BRAND=tinynas"    > files/etc/tinynas/brand
echo "TIER=${TIER}"     > files/etc/tinynas/tier
echo "DEVICE=${DEVICE_TAG}" > files/etc/tinynas/device
echo "VERSION=v${VERSION}"  > files/etc/tinynas/version
echo "CHANNEL=${CHANNEL}"   > files/etc/tinynas/channel
echo "BUILD=${DATE}"        > files/etc/tinynas/build

# --------- 4. 拼装 PACKAGES（common + tier + arch 三层叠加）---------
COMMON_PKGS=$(grep -v '^#' "${SCRIPT_DIR}/packages.common.txt" | tr '\n' ' ')
TIER_PKGS_FILE="${SCRIPT_DIR}/packages.tier-${TIER}.txt"
[ -f "${TIER_PKGS_FILE}" ] || fail "未找到档位包列表 ${TIER_PKGS_FILE}（合法档位：pro / edge / lite）"
TIER_PKGS=$(grep -v '^#' "${TIER_PKGS_FILE}" | tr '\n' ' ')
ARCH_PKGS=""
if [ -f "${ARCH_DIR}/packages.txt" ]; then
    ARCH_PKGS=$(grep -v '^#' "${ARCH_DIR}/packages.txt" | tr '\n' ' ')
fi
PACKAGES="${COMMON_PKGS} ${TIER_PKGS} ${ARCH_PKGS}"
log "预装包（共 $(echo ${PACKAGES} | wc -w | tr -d ' ') 个）: ${PACKAGES}"

# --------- 5. 跑 Image Builder ---------
log "调用 make image PROFILE=${PROFILE} ..."
make image \
    PROFILE="${PROFILE}" \
    PACKAGES="${PACKAGES}" \
    FILES="${IB_DIR}/files" \
    2>&1 | tee "${OUTPUT_DIR}/build-${DATE}.log"

# --------- 6. 收尾：重命名 + sha256 ---------
mkdir -p "${OUTPUT_DIR}"
OUT_NAME="openwrt_tinynas-${TIER}-${DEVICE_TAG}_v${VERSION}-${CHANNEL}_${DATE}.img.gz"
PRODUCED_RAW=$(ls -t bin/targets/${TARGET_DIR}/openwrt-*${DEVICE_TAG}*.img.gz 2>/dev/null | head -n1)

if [ -z "${PRODUCED_RAW:-}" ]; then
    fail "未找到 Image Builder 产物，请检查 build log"
fi

log "产物: ${PRODUCED_RAW} → ${OUT_NAME}"
mv "${PRODUCED_RAW}" "${OUTPUT_DIR}/${OUT_NAME}"
sha256sum "${OUTPUT_DIR}/${OUT_NAME}" | tee "${OUTPUT_DIR}/${OUT_NAME}.sha256"

# 清理临时 log
[ -f "${OUTPUT_DIR}/build-${DATE}.log" ] && tail -50 "${OUTPUT_DIR}/build-${DATE}.log" > "${OUTPUT_DIR}/build-${DATE}.log.tailed" && mv "${OUTPUT_DIR}/build-${DATE}.log.tailed" "${OUTPUT_DIR}/build-${DATE}.log"

log "✅ 完成: ${OUTPUT_DIR}/${OUT_NAME}"
log "  sha256: $(cat ${OUTPUT_DIR}/${OUT_NAME}.sha256 | awk '{print $1}')"