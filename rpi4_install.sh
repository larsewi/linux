#!/bin/bash

# Exit on error
set -e

if [ -z "$1" ]
then
    echo "Missing argument"
    [[ "$0" = "$BASH_SOURCE" ]] && exit 1 || return 1
fi

read -p "Are you sure you want to install on /dev/$1? " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    [[ "$0" = "$BASH_SOURCE" ]] && exit 1 || return 1
fi
echo "Okey, then... Let's do some dangerous stuff !"

# Rasberry Pi 4 config
KERNEL=kernel8
make -j12 ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- bcm2711_defconfig

# Build with config
make -j12 ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- Image modules dtbs

# Mount SD card
mkdir -p mnt/fat32
mkdir -p mnt/ext4
mount /dev/${1}1 mnt/fat32
mount /dev/${2}1 mnt/ext4

# Install kernel modules onto SD card
sudo env PATH=$PATH make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- INSTALL_MOD_PATH=mnt/ext4 modules_install

# Copy kernel and Device Tree blobs onto SD card
cp arch/arm64/boot/Image mnt/fat32/$KERNEL.img
cp arch/arm64/boot/dts/broadcom/*.dtb mnt/fat32/
cp arch/arm64/boot/dts/overlays/*.dtb* mnt/fat32/overlays/
cp arch/arm64/boot/dts/overlays/README mnt/fat32/overlays/

# Unmount SD card
umount mnt/fat32
umount mnt/ext4
