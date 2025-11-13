# Phase 2: Kernel Compilation

## Overview
Compile and configure the Linux LTS kernel with desktop-friendly features, security hardening, and encryption support.

## Target Kernel Version
- **Linux 6.6 LTS** (Long-Term Support)
- Released: December 2023
- Support Until: December 2026
- Source: https://kernel.org

## Prerequisites
- Phase 1 completed (toolchain installed)
- Source downloaded in `sources/kernel/`
- ~15GB free space for kernel build

## Download Kernel Source

```bash
cd sources/kernel
wget https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-6.6.tar.xz
wget https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-6.6.tar.sign

# Verify signature (optional but recommended)
xz -cd linux-6.6.tar.xz | gpg --verify linux-6.6.tar.sign -

# Extract
tar -xf linux-6.6.tar.xz
cd linux-6.6
```

## Kernel Configuration

### Base Configuration
Start with a distribution config or use `make defconfig`:

```bash
# Option 1: Use host system config as base
cp /boot/config-$(uname -r) .config
make olddefconfig

# Option 2: Start from default
make defconfig

# Option 3: Use menuconfig (interactive)
make menuconfig
```

### Essential Configuration Options

#### 1. Processor and Architecture
```
CONFIG_X86_64=y
CONFIG_64BIT=y
CONFIG_SMP=y  # Symmetric multiprocessing
CONFIG_NR_CPUS=256  # Support up to 256 CPUs
```

#### 2. Filesystem Support
```
CONFIG_EXT4_FS=y
CONFIG_EXT4_FS_POSIX_ACL=y
CONFIG_EXT4_FS_SECURITY=y
CONFIG_EXT4_ENCRYPTION=y

# FUSE for user-space filesystems
CONFIG_FUSE_FS=y

# ISO9660 for CD/DVD
CONFIG_ISO9660_FS=y
CONFIG_JOLIET=y
CONFIG_ZISOFS=y

# FAT for USB drives and UEFI
CONFIG_VFAT_FS=y
CONFIG_FAT_DEFAULT_CODEPAGE=437
CONFIG_FAT_DEFAULT_IOCHARSET="iso8859-1"

# NTFS read/write support
CONFIG_NTFS3_FS=y
CONFIG_NTFS3_LZX_XPRESS=y
```

#### 3. Encryption Support (LUKS)
```
CONFIG_BLK_DEV_DM=y
CONFIG_DM_CRYPT=y
CONFIG_CRYPTO=y
CONFIG_CRYPTO_AES=y
CONFIG_CRYPTO_AES_X86_64=y
CONFIG_CRYPTO_XTS=y
CONFIG_CRYPTO_SHA256=y
CONFIG_CRYPTO_USER_API_HASH=y
CONFIG_CRYPTO_USER_API_SKCIPHER=y
```

#### 4. Device Drivers

**USB Support:**
```
CONFIG_USB_SUPPORT=y
CONFIG_USB=y
CONFIG_USB_XHCI_HCD=y  # USB 3.0
CONFIG_USB_EHCI_HCD=y  # USB 2.0
CONFIG_USB_STORAGE=y
CONFIG_USB_UAS=y  # USB Attached SCSI
```

**Graphics (GPU):**
```
CONFIG_DRM=y
CONFIG_DRM_I915=m  # Intel
CONFIG_DRM_AMDGPU=m  # AMD
CONFIG_DRM_NOUVEAU=m  # NVIDIA open-source
CONFIG_FB=y
CONFIG_FB_EFI=y
```

**Audio:**
```
CONFIG_SOUND=y
CONFIG_SND=y
CONFIG_SND_HDA_INTEL=y
CONFIG_SND_HDA_CODEC_REALTEK=y
CONFIG_SND_HDA_CODEC_HDMI=y
CONFIG_SND_USB_AUDIO=y
```

**Network:**
```
CONFIG_NETDEVICES=y
CONFIG_ETHERNET=y
CONFIG_E1000E=y  # Intel
CONFIG_R8169=y  # Realtek
CONFIG_ATH9K=m  # Atheros WiFi
CONFIG_IWLWIFI=m  # Intel WiFi
CONFIG_RTL8192CE=m  # Realtek WiFi
```

**Input Devices:**
```
CONFIG_INPUT_KEYBOARD=y
CONFIG_INPUT_MOUSE=y
CONFIG_INPUT_TOUCHSCREEN=y
CONFIG_INPUT_TABLET=y
```

#### 5. Power Management (ACPI, TLP)
```
CONFIG_PM=y
CONFIG_ACPI=y
CONFIG_ACPI_BUTTON=y
CONFIG_ACPI_FAN=y
CONFIG_ACPI_THERMAL=y
CONFIG_CPU_FREQ=y
CONFIG_CPU_FREQ_GOV_ONDEMAND=y
CONFIG_CPU_FREQ_GOV_POWERSAVE=y
CONFIG_CPU_IDLE=y
CONFIG_SUSPEND=y
CONFIG_HIBERNATION=y
```

#### 6. Security Hardening
```
# Address Space Layout Randomization
CONFIG_RANDOMIZE_BASE=y
CONFIG_RANDOMIZE_MEMORY=y

# Stack Protection
CONFIG_STACKPROTECTOR=y
CONFIG_STACKPROTECTOR_STRONG=y

# Hardware hardening
CONFIG_X86_SMAP=y  # Supervisor Mode Access Prevention
CONFIG_X86_SMEP=y  # Supervisor Mode Execution Prevention

# Kernel hardening
CONFIG_HARDENED_USERCOPY=y
CONFIG_FORTIFY_SOURCE=y
CONFIG_INIT_ON_ALLOC_DEFAULT_ON=y
CONFIG_INIT_ON_FREE_DEFAULT_ON=y

# AppArmor support
CONFIG_SECURITY=y
CONFIG_SECURITY_APPARMOR=y
CONFIG_DEFAULT_SECURITY_APPARMOR=y
```

#### 7. Systemd Requirements
```
CONFIG_DEVTMPFS=y
CONFIG_CGROUPS=y
CONFIG_INOTIFY_USER=y
CONFIG_SIGNALFD=y
CONFIG_TIMERFD=y
CONFIG_EPOLL=y
CONFIG_NET=y
CONFIG_SYSFS=y
CONFIG_PROC_FS=y
CONFIG_FHANDLE=y
CONFIG_TMPFS_POSIX_ACL=y
CONFIG_TMPFS_XATTR=y
```

#### 8. Additional Desktop Features
```
# Bluetooth
CONFIG_BT=y
CONFIG_BT_RFCOMM=y
CONFIG_BT_HCIBTUSB=y

# Webcam support
CONFIG_MEDIA_SUPPORT=y
CONFIG_MEDIA_CAMERA_SUPPORT=y
CONFIG_USB_VIDEO_CLASS=y

# LED support (for keyboard backlights)
CONFIG_NEW_LEDS=y
CONFIG_LEDS_CLASS=y
```

### Kernel Configuration Script

Create `configs/kernel/desktop-config.sh`:

```bash
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
scripts/config --enable CONFIG_DM_CRYPT
scripts/config --enable CONFIG_CRYPTO_AES
scripts/config --enable CONFIG_CRYPTO_XTS
scripts/config --enable CONFIG_USB_STORAGE
scripts/config --enable CONFIG_DRM
scripts/config --module CONFIG_DRM_I915
scripts/config --module CONFIG_DRM_AMDGPU
scripts/config --enable CONFIG_SND_HDA_INTEL
scripts/config --enable CONFIG_ACPI
scripts/config --enable CONFIG_CPU_FREQ
scripts/config --enable CONFIG_SECURITY_APPARMOR
scripts/config --enable CONFIG_RANDOMIZE_BASE
scripts/config --enable CONFIG_STACKPROTECTOR_STRONG

# Finalize config
make olddefconfig

echo "Kernel configuration applied!"
```

## Compilation

### Build the Kernel

```bash
cd sources/kernel/linux-6.6

# Use all available cores
make -j$(nproc)

# Build modules
make modules -j$(nproc)

# Build device tree blobs (if needed for ARM)
# make dtbs
```

Build time: **30-120 minutes** depending on hardware.

### Install Kernel

```bash
# Install modules to build directory (not system)
make INSTALL_MOD_PATH=../../../builds/kernel modules_install

# Copy kernel image
mkdir -p ../../../builds/kernel/boot
cp arch/x86/boot/bzImage ../../../builds/kernel/boot/vmlinuz-6.6-custom

# Copy System.map and config
cp System.map ../../../builds/kernel/boot/System.map-6.6-custom
cp .config ../../../builds/kernel/boot/config-6.6-custom
```

### Testing the Kernel (Optional)

To test on the host system before integration:

```bash
# Install to /boot (requires root)
sudo make modules_install
sudo make install

# Update bootloader
sudo update-grub  # Debian/Ubuntu
# OR
sudo grub-mkconfig -o /boot/grub/grub.cfg  # Manual

# Reboot and select new kernel
```

**Warning:** Only test if you have a backup and recovery plan.

## Build Script

Create `scripts/build/01-build-kernel.sh`:

```bash
#!/bin/bash
set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
KERNEL_VERSION="6.6"
KERNEL_SRC="${PROJECT_ROOT}/sources/kernel/linux-${KERNEL_VERSION}"
BUILD_DIR="${PROJECT_ROOT}/builds/kernel"

echo "Building Linux Kernel ${KERNEL_VERSION}..."

cd "${KERNEL_SRC}"

# Apply configuration
if [ -f "${PROJECT_ROOT}/configs/kernel/.config" ]; then
    cp "${PROJECT_ROOT}/configs/kernel/.config" .config
    make olddefconfig
else
    make defconfig
fi

# Build
make -j$(nproc)
make modules -j$(nproc)

# Install to build directory
make INSTALL_MOD_PATH="${BUILD_DIR}" modules_install

mkdir -p "${BUILD_DIR}/boot"
cp arch/x86/boot/bzImage "${BUILD_DIR}/boot/vmlinuz-${KERNEL_VERSION}-custom"
cp System.map "${BUILD_DIR}/boot/System.map-${KERNEL_VERSION}-custom"
cp .config "${BUILD_DIR}/boot/config-${KERNEL_VERSION}-custom"

echo "Kernel build complete!"
echo "Output: ${BUILD_DIR}"
```

## Verification

### Check Kernel Build
```bash
ls -lh builds/kernel/boot/
# Should show: vmlinuz-6.6-custom, System.map, config

ls builds/kernel/lib/modules/
# Should show: 6.6.0/
```

### Validate Configuration
```bash
grep -E "CONFIG_EXT4_FS|CONFIG_DM_CRYPT|CONFIG_CRYPTO_AES" \
    builds/kernel/boot/config-6.6-custom
```

## Common Issues

### Issue: Build fails with missing headers
**Solution:** Install kernel build dependencies: `sudo apt build-dep linux`

### Issue: Out of memory during compilation
**Solution:** Reduce parallel jobs: `make -j4` instead of `make -j$(nproc)`

### Issue: Modules not loading
**Solution:** Check module dependencies: `depmod -a`

## Next Steps

Proceed to **Phase 3: Toolchain & C Library (glibc)** to build the userland components.

## References
- Kernel Configuration Guide: https://www.kernel.org/doc/html/latest/admin-guide/README.html
- Kernel Hardening Guide: https://kernsec.org/wiki/index.php/Kernel_Self_Protection_Project
- systemd Requirements: https://github.com/systemd/systemd/blob/main/README
