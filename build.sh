#!/bin/bash
set -e

WORKSPACE=$(pwd)
TOOLCHAIN_DIR="$WORKSPACE/toolchain"
KERNEL_DIR="$WORKSPACE/Kernel"

echo "=== 1. Extracting Samsung Source Archives ==="
if [ -f "SM-G998U_15_Opensource_G998USQSJHZAA_G998U1UESJHZAA_G998WVLSJHZAA_G998U1UESJHZB1_G998USQSJHZB1.zip" ]; then
    unzip -o SM-G998U_15_Opensource_G998USQSJHZAA_G998U1UESJHZAA_G998WVLSJHZAA_G998U1UESJHZB1_G998USQSJHZB1.zip
fi

if [ -f "G998USQSJHZAA_kernel.tar.gz" ]; then
    tar -xzf G998USQSJHZAA_kernel.tar.gz
fi

cd "$KERNEL_DIR"

echo "=== 2. Cloning Clang Toolchain ==="
if [ ! -d "$TOOLCHAIN_DIR" ]; then
    git clone https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86 --depth=1 -b master-kernel-build-2022 "$TOOLCHAIN_DIR"
fi

echo "=== 3. Integrating KernelSU ==="
curl -LSs "https://raw.githubusercontent.com/tjfoc/KernelSU/main/kernel/setup.sh" | bash -

echo "=== 4. Setting Environment Variables ==="
export ARCH=arm64
export SUBARCH=arm64
export CC="$TOOLCHAIN_DIR/clang-r416183b/bin/clang"
export CROSS_COMPILE=aarch64-linux-android-
export CLANG_TRIPLE=aarch64-linux-gnu-
export PATH="$TOOLCHAIN_DIR/clang-r416183b/bin:$PATH"

echo "=== 5. Configuring and Compiling Kernel ==="
make O=out g998u1_defconfig

# Inject required KernelSU kernel configs
echo "CONFIG_KSU=y" >> out/.config
echo "CONFIG_OVERLAY_FS=y" >> out/.config
echo "CONFIG_KPROBES=y" >> out/.config

make -j$(nproc) O=out CC=$CC CROSS_COMPILE=$CROSS_COMPILE

echo "=== Build Complete! ==="
echo "Compiled Kernel Binary: $KERNEL_DIR/out/arch/arm64/boot/Image.gz-dtb"
