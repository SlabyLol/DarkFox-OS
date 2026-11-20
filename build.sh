#!/bin/bash
set -euo pipefail

# DarkFox OS – Minimal bootable ISO Builder
# Kernel + BusyBox + Syslinux

KERNEL_VERSION="6.6.32"
BUSYBOX_VERSION="1.36.1"

WORKDIR=$(pwd)
BUILD_DIR="$WORKDIR/build"
ISO_DIR="$BUILD_DIR/iso"
ROOTFS_DIR="$BUILD_DIR/rootfs"

echo "=== Installing build dependencies ==="
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y --no-install-recommends \
    wget ca-certificates xz-utils bzip2 gzip cpio tar \
    build-essential bc flex bison libssl-dev libelf-dev libncurses-dev \
    perl python3 rsync kmod \
    xorriso mtools dosfstools grub-common grub-pc-bin grub-efi-amd64-bin

rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR" "$ISO_DIR" "$ROOTFS_DIR"/{bin,sbin,etc,proc,sys,dev,usr/bin,usr/sbin,tmp,root}

cd "$BUILD_DIR"

echo "=== Downloading sources ==="
download() { # download <output> <url> [<fallback-url>...]
    local out="$1"; shift
    for url in "$@"; do
        if wget -q --tries=3 --timeout=60 -O "$out" "$url"; then
            echo "  OK: $url"
            return 0
        fi
        echo "  failed: $url"
    done
    echo "ERROR: could not download $out" >&2
    return 1
}

download linux.tar.xz \
    "https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-${KERNEL_VERSION}.tar.xz" \
    "https://www.kernel.org/pub/linux/kernel/v6.x/linux-${KERNEL_VERSION}.tar.xz"

download busybox.tar.bz2 \
    "https://busybox.net/downloads/busybox-${BUSYBOX_VERSION}.tar.bz2" \
    "https://sources.buildroot.net/busybox/busybox-${BUSYBOX_VERSION}.tar.bz2"

echo "=== Extracting ==="
tar -xf linux.tar.xz
tar -xf busybox.tar.bz2

echo "=== Building BusyBox (static) ==="
cd "busybox-${BUSYBOX_VERSION}"
make defconfig
sed -i 's/^# CONFIG_STATIC is not set/CONFIG_STATIC=y/' .config
# 'tc' fails to build against newer kernel headers
sed -i 's/^CONFIG_TC=y/# CONFIG_TC is not set/' .config
make -j"$(nproc)" busybox
make CONFIG_PREFIX="$BUILD_DIR/busybox-install" install
cp -a "$BUILD_DIR/busybox-install/." "$ROOTFS_DIR/"
cd "$BUILD_DIR"

echo "=== Creating device nodes ==="
mknod -m 600 "$ROOTFS_DIR/dev/console" c 5 1
mknod -m 666 "$ROOTFS_DIR/dev/null"    c 1 3

echo "=== Creating init ==="
cat > "$ROOTFS_DIR/init" << 'EOF'
#!/bin/sh
mount -t devtmpfs none /dev 2>/dev/null || true
mount -t proc none /proc
mount -t sysfs none /sys
mount -t tmpfs none /tmp

clear
echo ""
echo "  ██████╗  █████╗ ██████╗ ██╗  ██╗███████╗ ██████╗ ██╗  ██╗"
echo "  ██╔══██╗██╔══██╗██╔══██╗██║ ██╔╝██╔════╝██╔═══██╗╚██╗██╔╝"
echo "  ██║  ██║███████║██████╔╝█████╔╝ █████╗  ██║   ██║ ╚███╔╝ "
echo "  ██║  ██║██╔══██║██╔══██╗██╔═██╗ ██╔══╝  ██║   ██║ ██╔██╗ "
echo "  ██████╔╝██║  ██║██║  ██║██║  ██╗██║     ╚██████╔╝██╔╝ ██╗"
echo "  ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝      ╚═════╝ ╚═╝  ╚═╝"
echo ""
echo "          DarkFox OS  -  Minimal Live System"
echo "          by DarkFox Co."
echo ""
echo "  Type 'poweroff' or 'reboot' to exit."
echo ""

export PATH=/bin:/sbin:/usr/bin:/usr/sbin
export HOME=/root
export PS1='[\u@darkfox \w]# '

exec setsid cttyhack /bin/sh
EOF
chmod +x "$ROOTFS_DIR/init"

echo "=== Creating initramfs ==="
cd "$ROOTFS_DIR"
find . | cpio -R root:root -H newc -o 2>/dev/null | gzip -9 > "$ISO_DIR/rootfs.gz"
cd "$BUILD_DIR"

echo "=== Building Kernel ==="
cd "linux-${KERNEL_VERSION}"
make defconfig
scripts/config --enable CONFIG_BLK_DEV_INITRD
scripts/config --enable CONFIG_DEVTMPFS
scripts/config --enable CONFIG_DEVTMPFS_MOUNT
scripts/config --enable CONFIG_BINFMT_SCRIPT
scripts/config --enable CONFIG_SERIAL_8250
scripts/config --enable CONFIG_SERIAL_8250_CONSOLE
scripts/config --enable CONFIG_TTY
scripts/config --enable CONFIG_VT
scripts/config --enable CONFIG_VT_CONSOLE
# UEFI boot + graphics console on laptops
scripts/config --enable CONFIG_EFI
scripts/config --enable CONFIG_EFI_STUB
scripts/config --enable CONFIG_FB
scripts/config --enable CONFIG_FB_EFI
scripts/config --enable CONFIG_FB_SIMPLE
scripts/config --enable CONFIG_SYSFB_SIMPLEFB
scripts/config --enable CONFIG_DRM
scripts/config --enable CONFIG_DRM_SIMPLEDRM
scripts/config --enable CONFIG_FRAMEBUFFER_CONSOLE
# Keyboards: PS/2 laptop keyboards + USB keyboards
scripts/config --enable CONFIG_INPUT_KEYBOARD
scripts/config --enable CONFIG_KEYBOARD_ATKBD
scripts/config --enable CONFIG_SERIO_I8042
scripts/config --enable CONFIG_HID
scripts/config --enable CONFIG_HID_GENERIC
scripts/config --enable CONFIG_USB_HID
scripts/config --enable CONFIG_USB_XHCI_HCD
scripts/config --enable CONFIG_USB_EHCI_HCD
make olddefconfig
make -j"$(nproc)" bzImage
cp arch/x86/boot/bzImage "$ISO_DIR/kernel.gz"
cd "$BUILD_DIR"

echo "=== Preparing GRUB (BIOS + UEFI) ==="
mkdir -p "$ISO_DIR/boot/grub"
mv "$ISO_DIR/kernel.gz" "$ISO_DIR/boot/kernel"
mv "$ISO_DIR/rootfs.gz" "$ISO_DIR/boot/rootfs.gz"

cat > "$ISO_DIR/boot/grub/grub.cfg" << 'EOF'
set default=0
set timeout=3

menuentry "DarkFox OS" {
    linux /boot/kernel console=tty0
    initrd /boot/rootfs.gz
}

menuentry "DarkFox OS (safe graphics: nomodeset)" {
    linux /boot/kernel console=tty0 nomodeset
    initrd /boot/rootfs.gz
}
EOF

echo "=== Creating hybrid ISO (BIOS + UEFI, USB-bootable) ==="
grub-mkrescue -o "$WORKDIR/darkfox-os.iso" "$ISO_DIR" -volid "DARKFOX_OS"

echo ""
echo "=== Fertig ==="
ls -lh "$WORKDIR/darkfox-os.iso"
