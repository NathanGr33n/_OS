#!/bin/bash
set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
KERNEL_VERSION="6.6"
KERNEL_SRC="${PROJECT_ROOT}/sources/kernel/linux-${KERNEL_VERSION}"
BUILD_DIR="${PROJECT_ROOT}/builds/kernel"

echo "=== Building Linux Kernel ${KERNEL_VERSION} ==="

if [ ! -d "${KERNEL_SRC}" ]; then
    echo "Error: Kernel source not found at ${KERNEL_SRC}"
    echo "Please download and extract the kernel source first"
    exit 1
fi

cd "${KERNEL_SRC}"

# Apply configuration
if [ -f "${PROJECT_ROOT}/configs/kernel/.config" ]; then
    echo "Using custom kernel config..."
    cp "${PROJECT_ROOT}/configs/kernel/.config" .config
    make olddefconfig
else
    echo "Using default config..."
    make defconfig
fi

# Build kernel
echo "Building kernel (this may take 30-120 minutes)..."
make -j$(nproc) || { echo "Kernel build failed!"; exit 1; }

# Build modules
echo "Building kernel modules..."
make modules -j$(nproc) || { echo "Module build failed!"; exit 1; }

# Install to build directory
echo "Installing kernel and modules to ${BUILD_DIR}..."
make INSTALL_MOD_PATH="${BUILD_DIR}" modules_install

mkdir -p "${BUILD_DIR}/boot"
cp arch/x86/boot/bzImage "${BUILD_DIR}/boot/vmlinuz-${KERNEL_VERSION}-custom"
cp System.map "${BUILD_DIR}/boot/System.map-${KERNEL_VERSION}-custom"
cp .config "${BUILD_DIR}/boot/config-${KERNEL_VERSION}-custom"

echo ""
echo "=== Kernel build complete! ==="
echo "Output directory: ${BUILD_DIR}"
echo "Kernel image: ${BUILD_DIR}/boot/vmlinuz-${KERNEL_VERSION}-custom"
echo "Modules: ${BUILD_DIR}/lib/modules/"
