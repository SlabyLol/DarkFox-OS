#!/bin/bash
# DarkFox OS - Debian live-build (XFCE desktop, BIOS + UEFI hybrid ISO)
# Must run as root inside Debian bookworm (the GitHub workflow does this).
set -euo pipefail
cd "$(dirname "$0")"

if [ "$(id -u)" -ne 0 ]; then
    echo "Please run as root (sudo ./build.sh) on Debian bookworm" >&2
    exit 1
fi

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y --no-install-recommends \
    live-build debootstrap squashfs-tools xorriso cpio \
    syslinux syslinux-common syslinux-utils isolinux \
    grub-pc-bin grub-efi-amd64-bin grub-common mtools dosfstools \
    debian-archive-keyring gnupg ca-certificates

chmod +x auto/* config/hooks/live/* 2>/dev/null || true

lb clean || true
lb config
lb build

mv live-image-*.iso darkfox-os.iso
ls -lh darkfox-os.iso
