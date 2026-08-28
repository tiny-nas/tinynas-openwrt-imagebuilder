# arch/armvirt-64

TinyNAS 简盒在通用 ARMv8（armvirt-64）架构下的打包配置。

> ⚠️ 重要说明：**本仓库 `arch/armvirt-64/` 仅作框架占位**。斐讯 N1、小米盒子3 等 Amlogic S9xxx 系列有专属打包工具（ophub），实际 N1 集成在 [`tinynas-labs/amlogic-s9xxx-openwrt`](https://github.com/tinynas-labs/amlogic-s9xxx-openwrt) 仓库。
>
> `armvirt-64` 适用于**非 Amlogic 的 ARMv8 通用平台**，例如：
> - 瑞芯微 RK3588/RK3568 设备（需要厂商自带 ATF/U-Boot）
> - 飞腾 S2500
> - 树莓派 4B/5（64 位内核）

## 适用硬件

| 平台 | 备注 |
|------|------|
| RK3588 通用 SBC | 需要厂商提供 ATF + U-Boot 引导链 |
| 树莓派 4B / 5 | 官方有 OpenWrt 适配，但请优先用树莓派官方仓库 |
| 飞腾 Phytium | 服务器级 ARMv8 平台 |

## 硬件能力要求

| 项目 | 最低 | 推荐 |
|------|------|------|
| CPU | ARMv8 四核 1.5GHz | 八核 2.0GHz+ |
| 内存 | 1 GB | 2 GB+ |
| 存储 | 8 GB | 16 GB+ |
| 网口 | 100 Mbps | 千兆 |

## 启动方式

armvirt-64 默认走 EFI 启动，要求硬件：
- 支持 UEFI 固件（部分 RK3588 板卡需要厂商自带 EFI stub）
- 提供 EFI System Partition（ESP）

## 当前状态

🧪 **框架就绪，待实际验证**。代码已就位（build.sh、packages.txt、profiles），但尚未在实际硬件上跑通。社区贡献者可在自己 SBC 上验证后报 Issue。

## 与 Amlogic 仓库的边界

| 项目 | Amlogic (N1/小米盒子3) | armvirt-64 |
|------|----------------------|------------|
| 打包工具 | ophub `make` | OpenWrt Image Builder |
| 启动 | U-Boot + eMMC 写入 | UEFI/GRUB |
| 内核 | 主线 + 厂商 DTB | 通用 armvirt DTB |
| 仓库 | `tinynas-labs/amlogic-s9xxx-openwrt` | 本仓库 `arch/armvirt-64/` |