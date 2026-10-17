#!/bin/sh
# Pack kernel Image + Droidian initramfs + stock DTB into a boot.img the Samsung ABL accepts.
# usage: make-bootimg.sh <Image> <initrd.xz> <stock-dtb.img> <out-boot.img>
# Notes:
# - header v2, raw (uncompressed) Image; os_version/patch must match the stock firmware
#   (here 11.0.0 / 2025-10, firmware G781BXXSIHYJ2) or ABL refuses to boot.
# - BOOT partition is 64 MiB: keep the image below 67108864 bytes.
# - Write it with dd from a running system or TWRP. heimdall uploads of images smaller
#   than the partition end with "Failed to receive session end confirmation" and the
#   phone falls back to download mode (or pad the image to 64 MiB first).
set -eu
CMDLINE="console=tty0 androidboot.hardware=qcom androidboot.memcg=1 androidboot.usbcontroller=a600000.dwc3 firmware_class.path=/vendor/firmware_mnt/image loop.max_part=7 lpm_levels.sleep_disabled=1 msm_rtb.filter=0x237 printk.devkmsg=on service_locator.enable=1 swiotlb=2048 binder.global_pid_lookups=0 droidian.lvm.prefer"
mkbootimg --header_version 2 --pagesize 4096 --base 0x0 --kernel_offset 0x8000 \
  --ramdisk_offset 0x2000000 --tags_offset 0x1e00000 --dtb_offset 0x1f00000 \
  --os_version 11.0.0 --os_patch_level 2025-10 \
  --kernel "$1" --ramdisk "$2" --dtb "$3" --cmdline "$CMDLINE" -o "$4"
ls -la "$4"
[ "$(stat -c%s "$4" 2>/dev/null || stat -f%z "$4")" -lt 67108864 ] || { echo "too big for BOOT (64 MiB)"; exit 1; }
