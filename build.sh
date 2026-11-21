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

# ------------------------------------------------------------------
# Remove the boot menu (BIOS + UEFI).
# This runs on the FINISHED binary tree, so it does not depend on the
# order live-build uses internally. Afterwards only the ISO image is
# rebuilt from the changed tree.
# ------------------------------------------------------------------
patch_boot() {
    local V I APPEND
    [ -f binary/boot/grub/grub.cfg ] || { echo "no binary/boot/grub/grub.cfg"; return 1; }
    [ -d binary/isolinux ]           || { echo "no binary/isolinux"; return 1; }

    V=$(ls binary/live/vmlinuz*    2>/dev/null | sort -V | tail -n1); V=${V##*/}
    I=$(ls binary/live/initrd.img* 2>/dev/null | sort -V | tail -n1); I=${I##*/}
    [ -n "$V" ] && [ -n "$I" ] || { echo "kernel/initrd not found in binary/live"; return 1; }

    APPEND=$( . ./config/binary; printf '%s' "$LB_BOOTAPPEND_LIVE" )
    [ -n "$APPEND" ] || { echo "LB_BOOTAPPEND_LIVE is empty"; return 1; }
    echo "Boot files: $V / $I"
    echo "Boot options: $APPEND"

    # BIOS (syslinux): no menu; hold Shift at start and type "safe" for safe graphics
    cat > binary/isolinux/isolinux.cfg << CFG
default live
prompt 0
timeout 1

label live
    linux /live/$V
    initrd /live/$I
    append $APPEND

label safe
    linux /live/$V
    initrd /live/$I
    append $APPEND nomodeset
CFG

    # UEFI (GRUB): boots after 1 second without a menu; press Esc for the menu
    cat > binary/boot/grub/grub.cfg << CFG
set default=0
set timeout=1
set timeout_style=hidden
search --no-floppy --set=root --file /live/filesystem.squashfs
set gfxpayload=keep

menuentry "DarkFox OS" {
    linux /live/$V $APPEND
    initrd /live/$I
}

menuentry "DarkFox OS (safe graphics)" {
    linux /live/$V $APPEND nomodeset
    initrd /live/$I
}
CFG
    return 0
}

lb clean || true
lb config
lb bootstrap
lb chroot
lb binary

if patch_boot; then
    echo "=== Boot menu removed, rebuilding ISO image ==="
    rm -f live-image-*.iso .build/binary_iso
    lb binary_iso
else
    echo "WARNING: could not remove the boot menu, ISO keeps the default menu"
fi

mv live-image-*.iso darkfox-os.iso
ls -lh darkfox-os.iso
