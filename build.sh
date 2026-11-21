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
lb bootstrap
lb chroot

# ------------------------------------------------------------------
# Boot without a menu (BIOS + UEFI).
# The real kernel file names are only known now, so the bootloader
# configs are generated here and copied over the defaults by
# live-build (config/includes.binary is applied after the bootloaders).
# ------------------------------------------------------------------
KERNEL=$(ls chroot/boot/vmlinuz-* | sort -V | tail -n1)
KVER=${KERNEL##*/vmlinuz-}
[ -e "chroot/boot/initrd.img-$KVER" ] || { echo "initrd for $KVER not found" >&2; exit 1; }
APPEND=$( . ./config/binary; printf '%s' "$LB_BOOTAPPEND_LIVE" )
[ -n "$APPEND" ] || { echo "LB_BOOTAPPEND_LIVE is empty" >&2; exit 1; }
echo "Kernel: $KVER"
echo "Boot options: $APPEND"

rm -rf config/includes.binary
mkdir -p config/includes.binary/isolinux config/includes.binary/boot/grub

# BIOS (syslinux): no menu; hold Shift at start and type "safe" for safe graphics
cat > config/includes.binary/isolinux/isolinux.cfg << CFG
default live
prompt 0
timeout 1

label live
    linux /live/vmlinuz-$KVER
    initrd /live/initrd.img-$KVER
    append $APPEND

label safe
    linux /live/vmlinuz-$KVER
    initrd /live/initrd.img-$KVER
    append $APPEND nomodeset
CFG

# UEFI (GRUB): boots after 1 second without a menu; press Esc for the menu
cat > config/includes.binary/boot/grub/grub.cfg << CFG
set default=0
set timeout=1
set timeout_style=hidden
search --no-floppy --set=root --file /live/filesystem.squashfs
set gfxpayload=keep

menuentry "DarkFox OS" {
    linux /live/vmlinuz-$KVER $APPEND
    initrd /live/initrd.img-$KVER
}

menuentry "DarkFox OS (safe graphics)" {
    linux /live/vmlinuz-$KVER $APPEND nomodeset
    initrd /live/initrd.img-$KVER
}
CFG

lb binary

mv live-image-*.iso darkfox-os.iso
ls -lh darkfox-os.iso
