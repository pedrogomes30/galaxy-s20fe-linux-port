#!/bin/sh
# Build the r8q (Galaxy S20 FE 5G, SM-G781B) Droidian kernel.
#
# Host: Debian trixie (arm64 or x86_64) with:
#   apt install git make bc bison flex libssl-dev libelf-dev python3 \
#               clang lld llvm cpio xz-utils mkbootimg
# Tested natively on arm64 (Docker debian:trixie on Apple Silicon) with clang 19.
set -eu
HERE=$(cd "$(dirname "$0")" && pwd)
SRC=${SRC:-$PWD/android_kernel_samsung_sm8250}
OUT=${OUT:-$PWD/kout}
COMMIT=50cffe6c51d966229ba80656e70210ce8c396655   # LineageOS lineage-24.0 (4.19.325-cip136)

if [ ! -d "$SRC/.git" ]; then
  git clone --branch lineage-24.0 https://github.com/LineageOS/android_kernel_samsung_sm8250.git "$SRC"
fi
cd "$SRC"
git checkout -q "$COMMIT"
for p in "$HERE"/patches/*.patch; do
  git apply --check "$p" 2>/dev/null && git apply "$p" && echo "applied $(basename "$p")" \
    || echo "skip (already applied?) $(basename "$p")"
done

mkdir -p "$OUT"
cp "$HERE/r8q-droidian.config" "$OUT/.config"
make O="$OUT" ARCH=arm64 LLVM=1 LLVM_IAS=1 olddefconfig
make O="$OUT" ARCH=arm64 LLVM=1 LLVM_IAS=1 -j"$(nproc)" Image
ls -la "$OUT/arch/arm64/boot/Image"
