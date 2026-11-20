#!/bin/bash
set -euo pipefail

# DarkFox OS – Minimal bootable ISO Builder
# Kernel + BusyBox + Syslinux

KERNEL_VERSION="6.6.32"
BUSYBOX_VERSION="1.36.1"
SYSLINUX_VERSION="6.03"

WORKDIR=$(pwd)
BUILD_DIR="$WORKDIR/build"
ISO_DIR="$BUILD_DIR/iso"
ROOTFS_DIR="$BUILD_DIR/rootfs"

rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR" "$ISO_DIR" "$ROOTFS_DIR"/{bin,sbin,etc,proc,sys,dev,usr/bin,usr/sbin,tmp,root}

cd "$BUILD_DIR"

echo "=== Downloading sources ==="
wget -q --show-progress -O linux.tar.xz "https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-${KERNEL_VERSION}.tar.xz" || \
wget -q --show-progress -O linux.tar.xz "https://www.kernel.org/pub/linux/kernel/v6.x/linux-${KERNEL_VERSION}.tar.xz"

wget -q --show-progress -O busybox.tar.bz2 "https://busybox.net/downloads/busybox-${BUSYBOX_VERSION}.tar.bz2"

wget -q --show-progress -O syslinux.tar.xz "https://www.kernel.org/pub/linux/utils/boot/syslinux/syslinux-${SYSLINUX_VERSION}.tar.xz"

echo "=== Extracting ==="
tar -xf linux.tar.xz
tar -xf busybox.tar.bz2
tar -xf syslinux.tar.xz

echo "=== Building BusyBox (static) ==="
cd "busybox-${BUSYBOX_VERSION}"
make defconfig
sed -i 's/# CONFIG_STATIC is not set/CONFIG_STATIC=y/' .config
sed -i 's/CONFIG_TC=y/# CONFIG_TC is not set/' .config || true
make -j$(nproc) busybox
make install
cp -a _install/* "$ROOTFS_DIR/"
cd "$BUILD_DIR"

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
echo "          DarkFox OS  –  Minimal Live System"
echo "          by DarkFox Co."
echo ""
echo "  Type 'poweroff' or 'reboot' to exit."
echo ""

export PATH=/bin:/sbin:/usr/bin:/usr/sbin
export HOME=/root
export PS1="[\u@darkfox \\w]# "

exec /bin/sh
EOF
chmod +x "$ROOTFS_DIR/init"

echo "=== Creating initramfs ==="
cd "$ROOTFS_DIR"
find . | cpio -R root:root -H newc -o 2>/dev/null | gzip -9 > "$ISO_DIR/rootfs.gz"
cd "$BUILD_DIR"

echo "=== Building Kernel ==="
cd "linux-${KERNEL_VERSION}"
make defconfig
# Enable needed options for initrd + console
scripts/config --enable CONFIG_BLK_DEV_INITRD
scripts/config --enable CONFIG_DEVTMPFS
scripts/config --enable CONFIG_DEVTMPFS_MOUNT
scripts/config --enable CONFIG_BINFMT_SCRIPT
scripts/config --enable CONFIG_SERIAL_8250
scripts/config --enable CONFIG_SERIAL_8250_CONSOLE
scripts/config --enable CONFIG_TTY
scripts/config --enable CONFIG_VT
scripts/config --enable CONFIG_VT_CONSOLE
make olddefconfig
make -j$(nproc) bzImage
cp arch/x86/boot/bzImage "$ISO_DIR/kernel.gz"
cd "$BUILD_DIR"

echo "=== Preparing Syslinux ==="
cp "syslinux-${SYSLINUX_VERSION}/bios/core/isolinux.bin" "$ISO_DIR/"
cp "syslinux-${SYSLINUX_VERSION}/bios/com32/elflink/ldlinux/ldlinux.c32" "$ISO_DIR/"

cat > "$ISO_DIR/isolinux.cfg" << 'EOF'
DEFAULT darkfox
PROMPT 0
TIMEOUT 30

LABEL darkfox
    KERNEL kernel.gz
    APPEND initrd=rootfs.gz quiet
EOF

echo "=== Creating ISO ==="
cd "$ISO_DIR"
xorriso -as mkisofs \
  -o "$WORKDIR/darkfox-os.iso" \
  -b isolinux.bin \
  -c boot.cat \
  -no-emul-boot \
  -boot-load-size 4 \
  -boot-info-table \
  -V "DARKFOX_OS" \
  .

echo ""
echo "=== Fertig ==="
ls -lh "$WORKDIR/darkfox-os.iso"
echo "ISO liegt unter: $WORKDIR/darkfox-os.iso"
