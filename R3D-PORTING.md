# R3D（小米路由器 HD）移植立项评估 · DTS 移植工作清单

> 状态：**立项评估中**（2026-08-28）｜ 目标：让小米路由器 HD（R3D，内置 1TB SATA）进入锦盒 TinyNAS 管线
> 本文档是尽调结论 + 分阶段工作清单，供立项决策。

---

## 一、为什么这台机器值得

| 维度 | R3D 实际 | 对比 |
|------|---------|------|
| SoC | **Qualcomm IPQ8064**（双核 Krait @1.4GHz，ARMv7 cortex-a15/neon-vfpv4） | 单核性能与 N1（四核 A53）同代，**远强于 MT7621** |
| RAM | 512MB DDR3 | Edge 级（Pro 需 1GB+，轻度可用） |
| 存储 | **1× SATA 3.1 原生接口，内置 3.5" 1TB 硬盘** | **全管线最强存储规格**——N1 都得外接 USB 盘，它是原生 SATA |
| NAND | 256MB（系统盘） | 宽裕 |
| 网络 | 千兆 WAN + 3×LAN | 千兆 ✅ |
| USB | 1× USB 3.0 | 可再外接盘 |
| WiFi | QCA9984（5G 4T4R）+ QCA9980（2.4G 4T4R） | 双频 AC，ath10k 驱动 |
| 散热 | **内置风扇**（EMC2305 芯片，PR 含 fancontrol 服务） | 7×24 挂盘有主动散热 |
| 附加 | 硬盘温度监控（drivetemp） | NAS 气质拉满 |

**结论：存储、网络、散热全面 Pro 级；512MB RAM 使它实际定位"Pro 存储 + Edge 内存"。**

## 二、上游现状（2026-08-28 尽调）

**OpenWrt PR [#14373](https://github.com/openwrt/openwrt/pull/14373)**（作者 remittor，xmir-patcher 生态贡献者）：

| 项 | 状态 |
|---|---|
| 状态 | OPEN，2024-01 提交，最后提交 2025-01-07 |
| 规模 | **单 commit，7 文件，约 +620 行**（DTS 557 行 + 设备定义 21 行 + bootcount/fancontrol/network 等） |
| DTS 内核基线 | **6.6**（`files-6.6`，路径已是上游 `qcom/` 新结构） |
| 设备 ID | `xiaomi_r3d`，IMAGE_SIZE 86016k，产出 `factory.bin` |
| 维护信号 | ✅ ipq806x 维护者 robimarko 于 2025-10 请 qcom 维护者 Ansuel review——PR 活着，但 2024-01 至今未合 |
| 25.12.5 现状 | ipq806x 用 **kernel 6.12**，无此设备 → **官方 Image Builder 无法出 R3D 镜像** |
| 历史版本 | **均无支持**（2026-08-28 已核实：v19.07→v24.10 全部 release 的 ipq806x 设备定义中 r3d 命中为 0——PR #14373 从未合入，任何官方版本都没有 R3D） |

## 三、刷机与救砖路径（风险可控的关键）

R3D 的原厂系统本身是 OpenWrt 二次开发，小米**官方提供 root 解锁**（[xmir-patcher](https://github.com/openwrt-xiaomi/xmir-patcher) 或 OpenWRTInvasion）。PR 的安装流程基于原厂 uboot 的**双内核冗余**（kernel0/kernel1 + CRC 校验 + 失败自动切换）：

```bash
# SSH 解锁后：
nvram flag_boot_success=1; nvram flag_boot_rootfs=1; nvram flag_last_success=1
nvram flag_try_sys1_failed=0; nvram flag_try_sys2_failed=0; nvram commit
dd if=factory.bin bs=1M count=4 | mtd write - kernel0
dd if=factory.bin bs=1M count=4 | mtd write - kernel1
dd if=factory.bin bs=1M skip=4  | mtd write - rootfs0
reboot
```

**回原厂**：装 [facinstall.ipk](https://github.com/openwrt-xiaomi/facinstall/releases) 后在 LuCI 里刷原厂包即可，**有官方级回头路**。
**串口**：PCB 上有 4-pad UART（3.3V 115200-8-N-1），调试期必备。

## 四、与锦盒管线的差距（三项核心工作）

1. **内核 6.6 → 6.12 的 DTS 移植**（唯一技术不确定性）：qcom DTS 在 6.6→6.12 间有结构调整（binding/PHY/SATA 节点），需逐节点核对。PR 已用新目录结构，起点好。
2. **管线的源码构建路径**：未合入上游的设备不能走官方 Image Builder（预编译内核里没有它）。方案：源码构建自定义 IB（OpenWrt v25.12.5 + PR 补丁 → `make defconfig` 出 IB）→ 产物放入 `ib-cache/` → **现有 `build-template.sh` 的缓存检测会自动复用，零模板改动**。这是组织内第一条源码构建路径，做成后 Armbian 等其它源码型平台可复用。
3. **armv7 二进制**：IPQ8064 是 ARMv7——ZeroClaw/tinynas 二进制需要 `armv7-unknown-linux-musleabihf` 目标（现有 aarch64 产物不适用）。Rust 目标现成，属工具链配置工作。

## 五、分阶段工作清单

### P0 准备（半天，零风险）
- [ ] USB-TTL 串口线（3.3V，¥10），接 PCB UART 4-pad，确认能抓到 uboot 输出
- [ ] xmir-patcher 解锁 root SSH，**完整备份全 flash**（mtd 备份存档）
- [ ] 记录 MAC/序列号；下载原厂最新固件 + facinstall.ipk 备用
- [ ] `free`/`fdisk` 实测 RAM/存储参数，回填本文档

### P1 先让它启动（1–2 个周末）

**首选路径 = OpenWrt 24.10.x**：24.10 的 ipq806x 用 **kernel 6.6**，与 PR #14373 的 DTS 基线（`files-6.6`）完全一致——**DTS 零移植**，补丁近乎直接应用，先把硬件跑通。

- [ ] 本地源码构建：`openwrt v24.10.x`（kernel 6.6）+ cherry-pick PR #14373（预计基本免改）
- [ ] 出 `factory.bin` → 按 §三 流程刷入 → **串口盯首次启动**
- [ ] 验收：内核起、SATA 盘识别、双 WiFi 起千兆网通
- ✅ **里程碑 = 原生 OpenWrt 在 R3D 上跑通，此时已可决定去留（刷回原厂零成本）**

**P2 之后的长期版本策略（二选一，跑通后再定）**：
- **保守**：R3D 分支钉在 24.10.x（上一代稳定版，官方仍在维护窗口内），免维护补丁，等上游 PR 合入后直接跳 25.12+
- **进取**：把 DTS 移植到 6.12（预计 90% 直接可用；卡点大概率在 SATA/PHY/emc2305 节点），与主线版本齐头并进

### P2 融入锦盒管线（约 1 周）
- [ ] 本分支新增 `r3d/build-r3d-ib.sh`：源码构建自定义 IB → `ib-cache/`（带 GitHub Actions 缓存，首次 ~2h，后续增量）
- [ ] 本分支 `build.sh` 参数化（对齐 mt7621 分支做法），新增 `profiles/xiaomi_r3d.txt`
- [ ] 标准打包：`./build.sh stable 1.0.0 xiaomi_r3d edge` → factory.bin 命名规范产物 + sha256
- [ ] `tinynas-files/` 覆盖层 armv7 适配说明；ZeroClaw armv7 产物跟进（依赖 pairing/tinynas 二进制落地）
- [ ] README 更新支持机型表（R3D 从"不支持"移入"社区移植"）
- ✅ **里程碑 = `openwrt_tinynas-edge-ipq806x-generic_*-factory.bin` 在真机可用**

### P3 上游化（持续）
- [ ] 把 DTS 6.12 适配回馈 PR #14373（帮它过 review = 早日删掉我们的补丁维护）
- [ ] 跟踪合入状态；合入后删除源码构建路径，回归标准 IB 流程

## 六、风险表

| 风险 | 概率 | 影响 | 对策 |
|------|------|------|------|
| DTS 6.12 适配卡壳（qcom 结构大改） | 中 | 仅影响 P2 后的版本升级 | **P1 已绕开**——先在 24.10（kernel 6.6 = PR 基线）跑通；6.12 适配放到硬件验证之后，甚至等上游合入直接白嫖 |
| 变砖 | 低 | 设备损失 | 双内核冗余 + facinstall 官方回退 + UART 兜底；先做 P0 全量备份 |
| 上游 PR 长期不合 | 高 | 长期维护补丁 | 补丁仅 7 文件；P2 的自定义 IB 机制本就不依赖上游 |
| 512MB 跑 Pro 拥挤 | 高 | 体验 | R3D 默认 **Edge 档**；Pro 轻载可试但不承诺 |
| CI 源码构建时长 | 确定 | 首次 ~2h | Actions 缓存 + 仅 r3d 构建触发，不影响其余 92 分支 |

## 七、结论

工作量：**P0+P1 ≈ 2–3 个周末，P2 ≈ 1 周**——比"按周计"的悲观估计乐观，因为 PR 把 DTS 和刷机路径都趟平了。
收益：管线获得**第一条源码构建路径**（解锁未来所有未合入上游的设备）+ 全管线唯一原生 SATA 设备 + 唯一性产品（全网唯一能给 R3D 出维护固件的发行版）。
决策点：P1 里程碑后可无损退出（刷回原厂）。
