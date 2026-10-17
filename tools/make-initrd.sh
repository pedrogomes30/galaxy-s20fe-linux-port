#!/bin/sh
# Build the initramfs from Droidian's linux-initramfs-halium-generic package,
# recompressed with xz (much smaller than gzip, needed to fit the 64 MiB BOOT partition).
# usage: make-initrd.sh linux-initramfs-halium-generic_*_arm64.deb initrd.xz
# (the kernel config enables CONFIG_RD_XZ; xz needs --check=crc32 for the kernel decompressor)
set -eu
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
dpkg-deb -x "$1" "$T/x"
IMG=$(find "$T/x" -name "initrd.img-halium-generic" | head -1)
zcat "$IMG" > "$T/initrd.cpio"
xz -9e --check=crc32 -T0 -c "$T/initrd.cpio" > "$2"
ls -la "$2"
