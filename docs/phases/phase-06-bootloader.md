# Phase 6: Bootloader (GRUB2)

## Overview
Install and configure GRUB2 bootloader with UEFI and Secure Boot support.

## Components
- **GRUB 2.06** - Bootloader
- **shim** - Secure Boot support
- **efibootmgr** - EFI boot manager
- **os-prober** - Detect other operating systems

## GRUB2 Build

### Download
```bash
cd sources/toolchain
wget https://ftp.gnu.org/gnu/grub/grub-2.06.tar.xz
tar -xf grub-2.06.tar.xz
cd grub-2.06
```

### Build for UEFI
```bash
./configure \
    --prefix=/usr \
    --sysconfdir=/etc \
    --disable-werror \
    --enable-grub-mkfont \
    --with-platform=efi \
    --target=x86_64 \
    --disable-efiemu

make -j$(nproc)
make install DESTDIR="${PROJECT_ROOT}/builds/grub"
```

### Build for BIOS (legacy support)
```bash
./configure \
    --prefix=/usr \
    --sysconfdir=/etc \
    --disable-werror \
    --with-platform=pc \
    --target=x86_64

make -j$(nproc)
make install DESTDIR="${PROJECT_ROOT}/builds/grub-bios"
```

## GRUB Configuration

### Default GRUB config

Create `configs/grub/grub.cfg`:

```bash
# GRUB Configuration
set timeout=5
set default=0

# Theme
set theme=/boot/grub/themes/custom/theme.txt

menuentry 'Custom Linux OS' --class os --class gnu-linux {
    load_video
    insmod gzio
    insmod part_gpt
    insmod ext2
    insmod cryptodisk
    insmod luks
    
    # Set root partition (will be updated during install)
    set root='hd0,gpt2'
    
    # Load encrypted root
    cryptomount -u <UUID>
    
    # Load kernel
    linux /boot/vmlinuz-6.6-custom root=/dev/mapper/cryptroot ro quiet splash
    
    # Load initramfs
    initrd /boot/initrd.img-6.6-custom
}

menuentry 'Custom Linux OS (Recovery Mode)' --class os {
    load_video
    insmod gzio
    insmod part_gpt
    insmod ext2
    insmod cryptodisk
    insmod luks
    
    set root='hd0,gpt2'
    cryptomount -u <UUID>
    
    linux /boot/vmlinuz-6.6-custom root=/dev/mapper/cryptroot ro single
    initrd /boot/initrd.img-6.6-custom
}
```

### GRUB defaults

Create `configs/grub/default`:

```bash
# /etc/default/grub
GRUB_DEFAULT=0
GRUB_TIMEOUT=5
GRUB_DISTRIBUTOR="Custom Linux OS"
GRUB_CMDLINE_LINUX_DEFAULT="quiet splash"
GRUB_CMDLINE_LINUX=""

# Uncomment to enable BadRAM filtering
#GRUB_BADRAM="0x01234567,0xfefefefe,0x89abcdef,0xefefefef"

# Uncomment to disable graphical terminal (grub-pc only)
#GRUB_TERMINAL=console

# Resolution for graphical mode
GRUB_GFXMODE=1920x1080
GRUB_GFXPAYLOAD_LINUX=keep

# Uncomment if you want GRUB to remember the last selection
GRUB_SAVEDEFAULT=false

# Preload both GPT and MBR modules
GRUB_PRELOAD_MODULES="part_gpt part_msdos"

# Enable cryptodisk support
GRUB_ENABLE_CRYPTODISK=y
```

## Secure Boot Support

### Shim bootloader
```bash
cd sources/toolchain
git clone --depth 1 https://github.com/rhboot/shim.git
cd shim

# Build shim
make VENDOR_CERT_FILE=/path/to/your/cert.der

# Install
cp shimx64.efi ${PROJECT_ROOT}/builds/grub/boot/efi/EFI/BOOT/BOOTX64.EFI
cp mmx64.efi ${PROJECT_ROOT}/builds/grub/boot/efi/EFI/BOOT/
```

### Signing GRUB with sbsign
```bash
# Generate keys (one-time)
openssl req -new -x509 -newkey rsa:2048 -keyout MOK.key -out MOK.crt -nodes -days 3650 -subj "/CN=My Signing Key/"
openssl x509 -in MOK.crt -outform DER -out MOK.cer

# Sign GRUB
sbsign --key MOK.key --cert MOK.crt --output grubx64.efi grubx64.efi

# Sign kernel
sbsign --key MOK.key --cert MOK.crt --output vmlinuz-6.6-custom.signed vmlinuz-6.6-custom
```

## initramfs Generation

Create initramfs with LUKS support:

```bash
# Build dracut
cd sources/toolchain
git clone --depth 1 https://github.com/dracutdevs/dracut.git
cd dracut

./configure --prefix=/usr --sysconfdir=/etc
make -j$(nproc)
make install DESTDIR="${PROJECT_ROOT}/builds/dracut"
```

### Generate initramfs
```bash
dracut --force \
    --add crypt \
    --add lvm \
    --kver 6.6.0 \
    /boot/initrd.img-6.6-custom
```

### Dracut configuration

Create `configs/dracut/dracut.conf`:

```bash
# /etc/dracut.conf.d/custom.conf
add_dracutmodules+=" crypt dm rootfs-block "
compress="xz"
hostonly="yes"
hostonly_cmdline="no"
```

## GRUB Theme

Create custom GRUB theme in `configs/grub/theme/`:

```bash
# theme.txt
title-text: "Custom Linux OS"
title-color: "#FFFFFF"
title-font: "Sans Bold 24"
desktop-image: "background.png"
terminal-box: "terminal_box_*.png"
terminal-font: "Sans Regular 14"

+ boot_menu {
    left = 15%
    width = 70%
    top = 30%
    height = 40%
    item_color = "#CCCCCC"
    selected_item_color = "#FFFFFF"
    item_height = 32
    item_padding = 10
    item_spacing = 5
    icon_width = 32
    icon_height = 32
}
```

## Installation Process

During ISO installation (Phase 12):

```bash
# Mount EFI partition
mount /dev/sda1 /boot/efi

# Install GRUB for UEFI
grub-install \
    --target=x86_64-efi \
    --efi-directory=/boot/efi \
    --bootloader-id=CustomLinuxOS \
    --recheck

# Generate GRUB config
grub-mkconfig -o /boot/grub/grub.cfg

# Register with efibootmgr
efibootmgr --create --disk /dev/sda --part 1 --label "Custom Linux OS" --loader '\EFI\CustomLinuxOS\grubx64.efi'
```

## Build Script

Create `scripts/build/05-build-grub.sh`:

```bash
#!/bin/bash
set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
GRUB_SRC="${PROJECT_ROOT}/sources/toolchain/grub-2.06"
BUILD_DIR="${PROJECT_ROOT}/builds/grub"

echo "=== Building GRUB2 ==="

if [ ! -d "${GRUB_SRC}" ]; then
    echo "Error: GRUB source not found"
    exit 1
fi

cd "${GRUB_SRC}"

# Build for UEFI
./configure \
    --prefix=/usr \
    --sysconfdir=/etc \
    --disable-werror \
    --enable-grub-mkfont \
    --with-platform=efi \
    --target=x86_64 \
    --disable-efiemu

make -j$(nproc)
make install DESTDIR="${BUILD_DIR}"

echo "GRUB2 build complete: ${BUILD_DIR}"
```

## Security Considerations

1. **Secure Boot enabled**: Verify chain of trust from firmware to kernel
2. **GRUB password**: Protect GRUB menu from unauthorized modifications
3. **Kernel parameters**: Avoid exposing sensitive info in boot parameters
4. **Boot logging**: Enable audit logging for boot process

### Set GRUB password
```bash
# Generate password hash
grub-mkpasswd-pbkdf2

# Add to /etc/grub.d/40_custom:
set superusers="admin"
password_pbkdf2 admin <hash>
```

## Verification

Test GRUB installation:
```bash
# Check GRUB files
ls builds/grub/usr/bin/grub-*

# Validate config
grub-script-check configs/grub/grub.cfg
```

## Troubleshooting

### Issue: GRUB not detecting kernel
**Solution**: Ensure kernel is in `/boot` and named correctly in grub.cfg

### Issue: LUKS password prompt not appearing
**Solution**: Check cryptodisk module is loaded: `insmod cryptodisk`

### Issue: Secure Boot prevents booting
**Solution**: Enroll MOK key or disable Secure Boot temporarily

## Next Steps

Proceed to **Phase 7: Package Management**.

## References
- GRUB Manual: https://www.gnu.org/software/grub/manual/
- Secure Boot: https://wiki.debian.org/SecureBoot
- dracut: https://dracut.wiki.kernel.org/
