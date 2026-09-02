# TinyNAS · OpenWrt Image Builder Integration Layer (English)

> [锦盒 TinyNAS](README.md) is a "lightweight NAS + AI assistant" gateway firmware for repurposed Phicomm N1 units, mini hosts, and home routers. This repository is the multi-architecture integration layer on the **official OpenWrt Image Builder**.
>
> The Chinese README is the authoritative, full version: [README.md](README.md).

## Supported architectures (OpenWrt 25.12.5, 92 branches)

Based on the full [OpenWrt 25.12.5 targets list](https://downloads.openwrt.org/releases/25.12.5/targets/). Branch names follow `arch/<name>`; the complete per-device table is maintained in [README.md](README.md#支持的架构openwrt-25125共-92-个分支).

| Category | Branches | Notes |
| :--- | :--- | :--- |
| Amlogic S9xxx (N1 / MiBox 3) | — | **Not here** — these use the ophub toolchain: [`tiny-nas/amlogic-s9xxx-openwrt`](https://github.com/tiny-nas/amlogic-s9xxx-openwrt) |
| Generic ARM / ARMv8 | `armvirt-64`, `armsr/armv7`, `armsr/armv8`, `rockchip-armv8` | `armsr/armv8` is also the rootfs source for the N1 pipeline |
| Raspberry Pi | `bcm27xx/bcm2708…bcm2712` | Pi 1 → Pi 5 |
| Qualcomm | `ipq40xx*`, `ipq806x*`, `qualcommax*` | 8 branches |
| MediaTek | `mediatek/*`, `ramips/*` | incl. `ramips/mt7621` (Mi Router 4A, Redmi AC2100) |
| Atheros | `ath79/*` | 4 branches |
| x86 | `x86_64` | mini hosts / industrial PCs / KVM |
| Broadcom / Lantiq / Marvell / NXP / sunxi / Realtek | `bcm47xx*`, `bmips*`, `lantiq*`, `mvebu*`, `apm821xx*`, `kirkwood`, `imx*`, `layerscape*`, `mpc85xx*`, `qoriq`, `sunxi/*`, `realtek*` | 30+ branches |
| MIPS / RISC-V / domestic | `octeon`, `gemini`, `malta*`, `loongarch64`, `sifiveu`, `siflower`, `starfive`, `d1` | incl. Loongson & RISC-V |
| Others | `microchipsw`, `at91*`, `mxs`, `omap`, `pistachio`, `stm32`, `tegra`, `zynq`, `ixp4xx` | 9 branches |

## Repository layout (single repo, many branches)

```
tiny-nas/tinynas-openwrt-imagebuilder
├── README.md / README.en.md      ← entry points
├── CONTRIBUTING.md
├── .github/workflows/            ← lint.yml (shellcheck + structure) · build.yml (per-arch build)
├── scripts/gen-arch-branch.sh    ← batch-generate arch branches
├── common/                       ← shared by ALL arches
│   ├── build-template.sh         ← packaging template (invoked by each arch/build.sh)
│   ├── packages.common.txt       ← shared package list
│   ├── packages.tier-{pro,edge,lite}.txt
│   └── tinynas-files/            ← rootfs overlay — source of truth for all firmwares
└── arch/<name>/                  ← per-arch config on its own branch (build.sh, packages.txt)
```

## Branch conventions

| Branch | Purpose | CI |
| :--- | :--- | :--- |
| `main` | docs, templates, `common/`, scripts | lint |
| `arch/<name>` | per-arch packaging config | build & emit images |

## Image naming

```
openwrt_tinynas-<tier>-<device>_v<SemVer>-<channel>_<YYYY.MM.DD>.img.gz
e.g. openwrt_tinynas-pro-x86_64_v1.0.0-stable_2026.10.31.img.gz
```

## Tiers (Pro / Edge / Lite)

Packages stack in three layers: `packages.common.txt` + `packages.tier-<tier>.txt` + `arch/<name>/packages.txt`.

| Tier | Target hardware | RAM | Delta |
| :--- | :--- | :--- | :--- |
| Pro | N1-class, 1-2GB | 1-2GB | full: Alist + FileBrowser + ZeroClaw AI |
| Edge | MiBox 3-class, USB boot | 1GB | no Alist/FileBrowser (CGI files), keeps AI |
| Lite | routers | 128-256MB | no AI either; ksmbd recommended over samba4 |

```bash
TIER=lite ./build.sh stable 1.0.0
```

The tier is written to `/etc/tinynas/tier` at build time; the dashboard hides unavailable modules accordingly.

## Quick start

```bash
git checkout arch/x86_64
cd arch/x86_64
./build.sh                     # downloads the official IB on demand, injects common/tinynas-files/
ls output/openwrt_tinynas-x86_64_v*.img.gz
```

> `build.sh` runs on a Linux host (or Docker). For N1 firmware, take the `*-rootfs.tar.gz` produced here and feed it to [`tiny-nas/amlogic-s9xxx-openwrt`](https://github.com/tiny-nas/amlogic-s9xxx-openwrt) (`sudo ./remake -b s905d`).

## Related repositories

| Repo | Purpose |
| :--- | :--- |
| [`tiny-nas/amlogic-s9xxx-openwrt`](https://github.com/tiny-nas/amlogic-s9xxx-openwrt) | Amlogic devices (ophub fork, zero commits) |
| this repo | 92 official OpenWrt arches |
| `tiny-nas/dashboard` | Vue3 SPA (vendored, zero CDN) |
| `tiny-nas/pairing` | pairing service (Rust + Axum + SQLite) |
| `tiny-nas/luci-theme-tinynas` | unified LuCI theme |

All firmwares share `common/tinynas-files/`: one change applies everywhere.

## License

Scripts and the overlay in this repo: Apache-2.0. Upstream Image Builder artifacts remain under OpenWrt's own licenses.
