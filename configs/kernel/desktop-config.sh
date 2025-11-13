#!/bin/bash
# Apply desktop-optimized kernel configuration

KERNEL_DIR="../../sources/kernel/linux-6.6"

if [ ! -d "$KERNEL_DIR" ]; then
    echo "Kernel source not found at $KERNEL_DIR"
    exit 1
fi

cd "$KERNEL_DIR"

# Start with defconfig
make defconfig

# Enable required features using scripts/config
scripts/config --enable CONFIG_EXT4_FS
scripts/config --enable CONFIG_EXT4_FS_POSIX_ACL
scripts/config --enable CONFIG_EXT4_FS_SECURITY
scripts/config --enable CONFIG_DM_CRYPT
scripts/config --enable CONFIG_CRYPTO_AES
scripts/config --enable CONFIG_CRYPTO_AES_X86_64
scripts/config --enable CONFIG_CRYPTO_XTS
scripts/config --enable CONFIG_CRYPTO_SHA256
scripts/config --enable CONFIG_USB_STORAGE
scripts/config --enable CONFIG_DRM
scripts/config --module CONFIG_DRM_I915
scripts/config --module CONFIG_DRM_AMDGPU
scripts/config --module CONFIG_DRM_NOUVEAU
scripts/config --enable CONFIG_SND_HDA_INTEL
scripts/config --enable CONFIG_ACPI
scripts/config --enable CONFIG_CPU_FREQ
scripts/config --enable CONFIG_CPU_FREQ_GOV_ONDEMAND
scripts/config --enable CONFIG_SECURITY_APPARMOR
scripts/config --enable CONFIG_DEFAULT_SECURITY_APPARMOR
scripts/config --enable CONFIG_RANDOMIZE_BASE
scripts/config --enable CONFIG_STACKPROTECTOR_STRONG
scripts/config --enable CONFIG_HARDENED_USERCOPY
scripts/config --enable CONFIG_BT
scripts/config --enable CONFIG_MEDIA_CAMERA_SUPPORT

# Finalize config
make olddefconfig

echo "Kernel configuration applied!"
echo "Review with: make menuconfig"
