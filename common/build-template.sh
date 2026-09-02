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

# 规范化 target 路径：OpenWrt 下载站路径恒为 arch/subarch（含一个斜杠）。
# 历史上批量生成的 build.sh 把设备名（如 ramips-mt7621）当 target 路径传入，
# 这里按规则归一：x86_64→x86/64；含斜杠原样；否则把第一个 - 替换为 /
case "${TARGET_DIR}" in
  x86_64)     TARGET_PATH="x86/64" ;;
  armvirt-64) TARGET_PATH="armvirt/64" ;;
  */*)        TARGET_PATH="${TARGET_DIR}" ;;
  *)          TARGET_PATH="${TARGET_DIR/-//}" ;;
esac

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
IB_BASE="https://downloads.openwrt.org/releases/${OPENWRT_VERSION}/targets/${TARGET_PATH}/openwrt-imagebuilder-${OPENWRT_VERSION}-${TARGET_PATH//\//-}.Linux-x86_64"
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

# --------- 3a. Ed25519 验证公钥注入（license-import 依赖）---------
if [ -n "${TINYNAS_ED25519_PUBKEY:-}" ] && [ -s "${TINYNAS_ED25519_PUBKEY}" ]; then
    cp "${TINYNAS_ED25519_PUBKEY}" files/etc/tinynas/ed25519-pub.key
    log "Ed25519 验证公钥已注入: ${TINYNAS_ED25519_PUBKEY}"
else
    cp "${SCRIPT_DIR}/tinynas-files/etc/tinynas/ed25519-pub.key.example" files/etc/tinynas/ed25519-pub.key 2>/dev/null || \
        warn "未找到公钥占位模板"
    warn "TINYNAS_ED25519_PUBKEY 未设置 —— 产物将无法通过许可证真实验证（仅体验固件可接受）"
fi

# --------- 3b. 可执行权限审计（FILES= 的 cp 保留权限位，源缺 +x 则镜像缺）---------
BAD_PERM=$(find files/etc/init.d files/etc/uci-defaults files/www/cgi-bin files/usr/bin files/etc/hotplug.d -type f 2>/dev/null | while read -r f; do
    case "$f" in
        */uci-defaults/*) : ;;  # uci-defaults 由 sh source，不需要 +x
        *) [ -x "$f" ] || echo "$f" ;;
    esac
done)
if [ -n "${BAD_PERM}" ]; then
    fail "以下文件缺少可执行位（IB cp -a 会保留源权限）:
${BAD_PERM}"
fi
log "可执行权限审计通过"

# --------- 3c. 军规门禁（V1-Arch §5.3）---------
LINT_FAIL=0
for f in files/etc/init.d/*; do
    [ -f "$f" ] || continue
    head -1 "$f" | grep -q '/etc/rc\.common' || { echo "[lint] 缺 rc.common shebang: $f"; LINT_FAIL=1; }
    grep -q '^START='        "$f" || { echo "[lint] 缺 START=: $f"; LINT_FAIL=1; }
done
if [ -d files/etc/rc.d ]; then
    echo "[lint] 覆盖层禁止手放 /etc/rc.d/（IB prepare_rootfs 自动 enable）"; LINT_FAIL=1
fi
for f in files/etc/uci-defaults/*; do
    [ -f "$f" ] || continue
    tail -1 "$f" | grep -q '^exit 0$' || { echo "[lint] uci-defaults 未以 exit 0 结尾: $f"; LINT_FAIL=1; }
done
if grep -rqE '(src|href)="https?://' files/www/ 2>/dev/null; then
    echo "[lint] 前端出现公网外链（零 CDN 军规）:"; grep -rlE '(src|href)="https?://' files/www/; LINT_FAIL=1
fi
[ "$LINT_FAIL" -eq 0 ] || fail "覆盖层军规门禁未通过"

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

# --------- 6. 收尾：收集产物 + 重命名 + sha256 ---------
mkdir -p "${OUTPUT_DIR}"
OUT_STEM="openwrt_tinynas-${TIER}-${DEVICE_TAG}_v${VERSION}-${CHANNEL}_${DATE}"

# 路由器 target 产出 .bin（factory/sysupgrade），x86/armsr 等产出 .img.gz，
# 统一收集并在文件名中保留产物类别（factory/sysupgrade/combined 等）
shopt -s nullglob
FOUND=0
for f in \
    "bin/targets/${TARGET_PATH}/"*.img.gz \
    "bin/targets/${TARGET_PATH}/"*-sysupgrade.bin \
    "bin/targets/${TARGET_PATH}/"*-factory.bin \
    "bin/targets/${TARGET_PATH}/"*-combined.img.gz \
    "bin/targets/${TARGET_PATH}/"*-combined-efi.img.gz \
    "bin/targets/${TARGET_PATH}/"*rootfs.tar.gz; do
    [ -f "$f" ] || continue
    base=$(basename "$f")
    kind=""
    case "$base" in
        *sysupgrade*)          kind="sysupgrade" ;;
        *factory*)             kind="factory" ;;
        *combined-efi*)        kind="combined-efi" ;;
        *combined*)            kind="combined" ;;
        *ext4*)                kind="ext4" ;;
        *squashfs-rootfs*|*rootfs*) kind="rootfs" ;;
    esac
    ext="${base##*.}"
    OUT_NAME="${OUT_STEM}"
    [ -n "$kind" ] && OUT_NAME="${OUT_STEM}-${kind}"
    OUT_NAME="${OUT_NAME}.${ext}"
    mv "$f" "${OUTPUT_DIR}/${OUT_NAME}"
    sha256sum "${OUTPUT_DIR}/${OUT_NAME}" > "${OUTPUT_DIR}/${OUT_NAME}.sha256"
    log "产物: ${base} → ${OUT_NAME}"
    FOUND=$((FOUND+1))
done
shopt -u nullglob

if [ "${FOUND}" -eq 0 ]; then
    fail "未找到 Image Builder 产物（bin/targets/${TARGET_PATH}/ 下无 .img.gz 或 .bin），请检查 build log"
fi

# 清理临时 log
[ -f "${OUTPUT_DIR}/build-${DATE}.log" ] && tail -50 "${OUTPUT_DIR}/build-${DATE}.log" > "${OUTPUT_DIR}/build-${DATE}.log.tailed" && mv "${OUTPUT_DIR}/build-${DATE}.log.tailed" "${OUTPUT_DIR}/build-${DATE}.log"

log "✅ 完成：共 ${FOUND} 个产物，位于 ${OUTPUT_DIR}/"
log "  命名前缀: ${OUT_STEM}"