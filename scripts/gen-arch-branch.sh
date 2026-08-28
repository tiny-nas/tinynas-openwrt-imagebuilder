#!/usr/bin/env bash
# 批量为所有 OpenWrt 25.12.5 架构创建 arch/<name> 分支并填充模板
# 用法：./scripts/gen-arch-branch.sh <arch-name-list.txt>
set -euo pipefail

LIST="${1:-/tmp/openwrt-25.12.5-archs.txt}"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OPENWRT_VERSION="25.12.5"

# 必须已登录 gh
command -v gh >/dev/null || { echo "缺少 gh CLI"; exit 1; }
GH_TOKEN=$(gh auth token)

cd "${REPO_ROOT}"

# 把 armvirt 改名为 armvirt-64 这种例外
norm_branch() {
    local n="$1"
    case "$n" in
        ramips-rt305x) echo "ramips/rt305x" ;;
        ramips-rt3883) echo "ramips/rt3883" ;;
        ramips-mt7620) echo "ramips/mt7620" ;;
        ramips-mt7621) echo "ramips/mt7621" ;;
        ramips-mt76x8) echo "ramips/mt76x8" ;;
        mediatek-filogic) echo "mediatek/filogic" ;;
        mediatek-mt7622) echo "mediatek/mt7622" ;;
        mediatek-mt7623) echo "mediatek/mt7623" ;;
        mediatek-mt7629) echo "mediatek/mt7629" ;;
        bcm27xx-bcm2708) echo "bcm27xx/bcm2708" ;;
        bcm27xx-bcm2709) echo "bcm27xx/bcm2709" ;;
        bcm27xx-bcm2710) echo "bcm27xx/bcm2710" ;;
        bcm27xx-bcm2711) echo "bcm27xx/bcm2711" ;;
        bcm27xx-bcm2712) echo "bcm27xx/bcm2712" ;;
        ath79-mikrotik) echo "ath79/mikrotik" ;;
        ath79-nand) echo "ath79/nand" ;;
        ath79-tiny) echo "ath79/tiny" ;;
        ipq40xx-chromium) echo "ipq40xx/chromium" ;;
        ipq40xx-mikrotik) echo "ipq40xx/mikrotik" ;;
        ipq806x-chromium) echo "ipq806x/chromium" ;;
        sunxi-cortexa53) echo "sunxi/cortexa53" ;;
        sunxi-cortexa7) echo "sunxi/cortexa7" ;;
        sunxi-cortexa8) echo "sunxi/cortexa8" ;;
        sunxi-arm926ejs) echo "sunxi/arm926ejs" ;;
        realtek-rtl930x_nand) echo "realtek/rtl930x_nand" ;;
        realtek-rtl931x_nand) echo "realtek/rtl931x_nand" ;;
        armsr-armv7) echo "armsr/armv7" ;;
        armsr-armv8) echo "armsr/armv8" ;;
        layerscape-armv8_64b) echo "layerscape/armv8_64b" ;;
        layerscape-armv7) echo "layerscape/armv7" ;;
        *) echo "$n" ;;
    esac
}

# 把 arch/subarch 转为 Image Builder 下载 URL 中 target 路径
target_path() {
    local n="$1"
    case "$n" in
        x86_64) echo "x86/64" ;;
        armvirt-64) echo "armvirt/64" ;;
        *) echo "$n" ;;  # ramips/mt7621, bcm27xx/bcm2708 etc.
    esac
}

# 把 arch/subarch 转为 profile 名（多数为 generic，部分有别名）
profile_name() {
    local n="$1"
    case "$n" in
        ramips-rt305x) echo "rt305x" ;;
        ramips-rt3883) echo "rt3883" ;;
        *) echo "generic" ;;
    esac
}

# 架构元信息（架构族、典型设备）
arch_meta() {
    local n="$1"
    case "$n" in
        x86_64) echo "x86|x86_64 迷你主机/工控机/虚拟机" ;;
        armvirt-64) echo "armvirt|通用 ARMv8 主机（Amlogic 设备走 tinynas-labs/amlogic-s9xxx-openwrt）" ;;
        ath79-*) echo "ath79|Atheros ath79 系列路由器" ;;
        bcm27xx-*) echo "bcm27xx|树莓派 1-5（bcm2708/2709/2710/2711/2712）" ;;
        ramips-*) echo "ramips|MediaTek MT7620/MT7621/MT76x8/RT305x/RT3883 路由器" ;;
        mediatek-*) echo "mediatek|MediaTek Filogic/MT7622/MT7623/MT7629 路由器" ;;
        ipq40xx-*) echo "ipq40xx|高通 IPQ40xx 路由器" ;;
        ipq806x-*) echo "ipq806x|高通 IPQ806x 路由器" ;;
        qualcommax-*) echo "qualcommax|高通 IPQ50xx/60xx/807x 高端路由器" ;;
        lantiq-*) echo "lantiq|Lantiq xRX/xWAY DSL 路由器" ;;
        mvebu-*) echo "mvebu|Marvell ARMADA 38x/37x/70xx 路由器" ;;
        sunxi-*) echo "sunxi|Allwinner ARM9/A7/A8/A53 SBC" ;;
        realtek-*) echo "realtek|Realtek RTL838x/RTL839x 交换机" ;;
        rockchip-armv8) echo "rockchip|瑞芯微 RK3328/RK3399/RK3568 等 ARMv8 SBC" ;;
        bcm47xx-*) echo "bcm47xx|Broadcom BCM47xx 路由器" ;;
        bcm4908-*) echo "bcm4908|Broadcom BCM4908 路由器" ;;
        bcm53xx-*) echo "bcm53xx|Broadcom BCM53xx 路由器" ;;
        bmips-*) echo "bmips|Broadcom BMIPS（运营商光猫）" ;;
        armsr-armv7) echo "armsr|ARMv7 软路由（x86 类通用）" ;;
        armsr-armv8) echo "armsr|ARMv8 软路由（x86 类通用）" ;;
        apm821xx-*) echo "apm821xx|AMCC APM821xx NAS/路由器" ;;
        imx-*) echo "imx|NXP i.MX 6/7/8 SBC" ;;
        kirkwood-*) echo "kirkwood|Marvell Kirkwood NAS" ;;
        layerscape-*) echo "layerscape|NXP Layerscape 服务器级 ARM" ;;
        mpc85xx-*) echo "mpc85xx|Freescale P10xx/P20xx PowerPC" ;;
        octeon-*) echo "octeon|Cavium Octeon MIPS64" ;;
        qoriq-*) echo "qoriq|NXP QorIQ PowerPC" ;;
        gemini-*) echo "gemini|Cortina Systems Gemini" ;;
        loongarch64-*) echo "loongarch64|龙芯 LoongArch64" ;;
        malta-*) echo "malta|MIPS Malta 评估板" ;;
        sifiveu-*) echo "sifiveu|SiFive U54/U74 RISC-V" ;;
        siflower-*) echo "siflower|矽力杰 SF21xx" ;;
        starfive-*) echo "starfive|StarFive JH7100/VisionFive" ;;
        at91-*) echo "at91|Microchip AT91 SAM9/SAMA5/SAMA7" ;;
        d1-*) echo "d1|全志 D1 (RISC-V)" ;;
        ixp4xx-*) echo "ixp4xx|Intel XScale IXP4xx" ;;
        microchipsw-*) echo "microchipsw|Microchip LAN969x 交换机" ;;
        mxs-*) echo "mxs|Freescale i.MX28" ;;
        omap-*) echo "omap|TI OMAP" ;;
        pistachio-*) echo "pistachio|ImgTec Pistachio" ;;
        stm32-*) echo "stm32|STMicro STM32MP1" ;;
        tegra-*) echo "tegra|NVIDIA Tegra" ;;
        zynq-*) echo "zynq|Xilinx Zynq-7000" ;;
        *) echo "unknown|未知" ;;
    esac
}

gen_branch() {
    local name="$1"
    local branch="arch/$(norm_branch "$name")"
    local target="$(target_path "$name")"
    local profile="$(profile_name "$name")"
    local meta="$(arch_meta "$name")"
    local arch_family="${meta%%|*}"
    local arch_desc="${meta##*|}"
    local ib_url="https://downloads.openwrt.org/releases/${OPENWRT_VERSION}/targets/${target}/openwrt-imagebuilder-${OPENWRT_VERSION}-${target//\//-}.Linux-x86_64.tar.xz"

    echo "=== 处理 $name → 分支 $branch ==="

    # 切回 main 准备基础
    git checkout main --quiet 2>/dev/null || git checkout --quiet main
    # 如果分支已存在，跳过
    if git show-ref --quiet "refs/heads/${branch}"; then
        echo "  ⚠️ 分支 $branch 已存在，跳过"
        return 0
    fi

    # 创建分支（基于 main）
    git checkout -b "${branch}" --quiet

    # 创建目录
    local arch_dir="arch/$(norm_branch "$name")"
    mkdir -p "${arch_dir}/profiles" "${arch_dir}/output"

    # build.sh
    cat > "${arch_dir}/build.sh" <<EOF
#!/usr/bin/env bash
# TinyNAS 简盒 - ${arch_desc} (${name}) 打包入口
# 调用 common/build-template.sh，传入 ${name} 专属参数
set -euo pipefail

SCRIPT_DIR="\$(cd "\$(dirname "\${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE="\${SCRIPT_DIR}/../../common/build-template.sh"

[ -x "\${TEMPLATE}" ] || { echo "未找到 \${TEMPLATE}"; exit 1; }

# OpenWrt ${OPENWRT_VERSION} 上的 target 路径: ${target}
# PROFILE 默认: ${profile}
exec "\${TEMPLATE}" \\
    "${target}" \\
    "${OPENWRT_VERSION}" \\
    "${profile}" \\
    "${name}" \\
    "\${1:-stable}" \\
    "\${2:-1.0.0}"
EOF
    chmod +x "${arch_dir}/build.sh"

    # profiles/<profile>.txt
    echo "${profile}" > "${arch_dir}/profiles/${profile}.txt"
    touch "${arch_dir}/output/.gitkeep"
    touch "${arch_dir}/profiles/.gitkeep"

    # packages.txt（占位，后续按需填充）
    cat > "${arch_dir}/packages.txt" <<EOF
# TinyNAS 简盒 - ${name} 架构专属包
# 在 common/packages.common.txt 基础上叠加
# （待验证后补充 NIC/SOC 专属驱动）
EOF

    # README.md
    cat > "${arch_dir}/README.md" <<EOF
# arch/$(norm_branch "$name")

TinyNAS 简盒在 **${arch_desc}**（${name}）架构下的打包配置。

## 基本信息

| 项 | 值 |
|---|---|
| OpenWrt 版本 | ${OPENWRT_VERSION} |
| target 路径 | \`${target}\` |
| 默认 PROFILE | \`${profile}\` |
| Image Builder | [下载链接](${ib_url}) |
| 架构族 | ${arch_family} |

## 典型硬件

${arch_desc}。

## 刷机

请先通过 OpenWrt 官网确认你的设备是否在 [Table of Hardware](https://openwrt.org/toh/start) 支持列表内：

- ✅ OpenWrt 支持 → 使用本分支打包的固件，按官方 wiki 刷机
- ❌ OpenWrt 不支持 → 检查设备是否在本仓其他分支或 [tinynas-labs/amlogic-s9xxx-openwrt](https://github.com/tinynas-labs/amlogic-s9xxx-openwrt) 的支持范围

## 已知限制

⚠️ **本仓库刚完成 25.12.5 全架构分支骨架填充**，实际打包验证待：
1. Image Builder tarball 下载链路通畅
2. 产物在真机/虚拟机上能正常启动
3. \`tinynas-files/\` 覆盖层实际内容就绪后做端到端测试

如发现本架构的 \`packages.txt\` 需要 SOC 专属驱动，欢迎提 PR。

## 相关链接

- Image Builder: ${ib_url}
- 通用打包模板: \`common/build-template.sh\`
- 通用包列表: \`common/packages.common.txt\`
- 覆盖层: \`common/tinynas-files/\`
EOF

    # 提交
    git add "${arch_dir}/" 2>/dev/null
    git -c commit.gpgsign=false commit -m "feat(arch/${name}): 初始化 ${arch_desc} 架构分支

- arch/${name}/build.sh: 调用 common/build-template.sh
- arch/${name}/packages.txt: 架构专属包占位
- arch/${name}/profiles/${profile}.txt: ${profile}
- arch/${name}/README.md: 硬件说明与刷机 SOP

OpenWrt 版本: ${OPENWRT_VERSION}
target 路径: ${target}" --quiet

    # push
    git push -u origin "${branch}" 2>&1 | tail -3
}

# 主循环
while IFS= read -r name; do
    [ -z "$name" ] && continue
    gen_branch "$name"
done < "${LIST}"

echo ""
echo "✅ 完成全部 $(wc -l < ${LIST}) 个架构分支"
git ls-remote --heads origin "refs/heads/arch/*" 2>&1 | wc -l