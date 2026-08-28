# arch/x86_64

TinyNAS 简盒在 x86_64 架构下的打包配置。

## 适用硬件

- 迷你主机（Intel NUC、联想小新、华擎 DeskMeet）
- 工控机（研华、研扬）
- 旧笔记本/台式机（改造为 NAS）
- KVM/QEMU 虚拟机

## 硬件能力要求

| 项目 | 最低 | 推荐 |
|------|------|------|
| CPU | x86_64 双核 1.5GHz | 四核 2.0GHz+ |
| 内存 | 1 GB | 2 GB+ |
| 存储 | 8 GB（系统盘） | 16 GB+ |
| 网口 | 100 Mbps | 千兆 |

## 启动方式

支持两种启动介质：
- **EFI 启动**：UEFI 固件（2010 年后主流设备）
- **Legacy BIOS 启动**：旧设备/虚拟机

Image Builder 会同时产出 EFI 与 BIOS 两种 squashfs 镜像，用户按需选用。

## 刷机 SOP

### 物理机/迷你主机

1. 下载 `openwrt_tinynas-x86_64_vX.Y.Z-stable_YYYY.MM.DD.img.gz`
2. 用 BalenaEtcher/Rufus 写入 U 盘
3. U 盘插入目标设备，从 U 盘启动（BIOS 选 U 盘优先）
4. 进入系统后通过浏览器访问 `192.168.1.1`，按首次启动向导激活

### 虚拟机

1. 解压 img.gz → 得到 `.img` 原始镜像
2. 用 `qemu-img convert -f raw -O qcow2 openwrt-...img openwrt-tinynas.qcow2` 转格式
3. 导入 Proxmox/vSphere/ESXi，配置虚拟网卡为 virtio

## 已验证机型

| 机型 | 状态 |
|------|------|
| Intel NUC8/10/12 | ✅ |
| 联想小新 Mini PC | 🧪 待验证 |
| 华擎 DeskMeet | 🧪 待验证 |

## 已知限制

- 不支持 32 位 x86（仅 x86_64）
- 不支持 U 盘热拔插（请先关机再拔 U 盘）
- mSATA / NVMe 启动需主板 BIOS 支持 EFI