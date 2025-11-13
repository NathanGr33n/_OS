# Phase 5: Filesystem & Encryption

## Overview
Configure ext4 filesystem support, LUKS encryption, and Timeshift for system snapshots.

## Components
- **ext4** - Root filesystem
- **LUKS** (cryptsetup) - Full disk encryption
- **Timeshift** - System snapshot and restore
- **LVM** (optional) - Logical Volume Management

## Filesystem Layout

### Partition Scheme (UEFI)
```
/dev/sda1  512MB   EFI System Partition (FAT32)
/dev/sda2  Remaining space  LUKS encrypted (ext4 inside)
```

### Directory Structure
```
/           Root filesystem (ext4)
/boot       Boot partition (on EFI partition)
/home       User directories
/var        Variable data
/tmp        Temporary files
/opt        Optional software
```

## LUKS Encryption Setup

### Install cryptsetup
```bash
cd sources/toolchain
wget https://www.kernel.org/pub/linux/utils/cryptsetup/v2.6/cryptsetup-2.6.1.tar.xz
tar -xf cryptsetup-2.6.1.tar.xz
cd cryptsetup-2.6.1

./configure --prefix=/usr
make -j$(nproc)
make install DESTDIR="${PROJECT_ROOT}/builds/cryptsetup"
```

### LUKS Encryption Process

During installation (handled by Calamares):

```bash
# Create LUKS container
cryptsetup luksFormat /dev/sda2

# Open encrypted partition
cryptsetup open /dev/sda2 cryptroot

# Create filesystem
mkfs.ext4 /dev/mapper/cryptroot

# Mount
mount /dev/mapper/cryptroot /mnt
```

### initramfs Configuration

The kernel needs to unlock LUKS at boot. Configure in `/etc/crypttab`:

```
# /etc/crypttab
cryptroot UUID=<partition-uuid> none luks,discard
```

Update `/etc/fstab`:
```
# /etc/fstab
/dev/mapper/cryptroot  /  ext4  defaults,noatime  0  1
UUID=<efi-uuid>  /boot/efi  vfat  umask=0077  0  2
```

## Timeshift Installation

### Build from source
```bash
cd sources/apps
git clone --depth 1 https://github.com/linuxmint/timeshift.git
cd timeshift

# Dependencies
sudo apt install -y \
    libgee-0.8-dev \
    libjson-glib-dev \
    libvte-2.91-dev \
    valac

make
make install DESTDIR="${PROJECT_ROOT}/builds/timeshift"
```

### Timeshift Configuration

Create default config in `configs/timeshift/timeshift.json`:

```json
{
  "backup_device_uuid": "",
  "parent_device_uuid": "",
  "do_first_run": true,
  "btrfs_mode": false,
  "include_btrfs_home_for_backup": false,
  "include_btrfs_home_for_restore": false,
  "stop_cron_emails": true,
  "schedule_monthly": false,
  "schedule_weekly": true,
  "schedule_daily": false,
  "schedule_hourly": false,
  "schedule_boot": true,
  "count_monthly": 2,
  "count_weekly": 3,
  "count_daily": 5,
  "count_hourly": 6,
  "count_boot": 3,
  "snapshot_size": 0,
  "snapshot_count": 0,
  "date_format": "%Y-%m-%d %H:%M:%S",
  "exclude": [
    "/home/**",
    "/root/**",
    "/tmp/**",
    "/var/tmp/**"
  ],
  "exclude-apps": []
}
```

### Automatic Snapshots

Create systemd service for automatic snapshots:

```ini
# configs/systemd/services/timeshift-boot.service
[Unit]
Description=Timeshift Boot Snapshot
ConditionPathExists=/usr/bin/timeshift

[Service]
Type=oneshot
ExecStart=/usr/bin/timeshift --create --comments "Boot snapshot" --tags B

[Install]
WantedBy=multi-user.target
```

## ext4 Tuning

Optimize ext4 for desktop use:

```bash
# Mount options in /etc/fstab
defaults,noatime,discard,errors=remount-ro

# Tune filesystem
tune2fs -o journal_data_writeback /dev/mapper/cryptroot
tune2fs -O ^has_journal /dev/mapper/cryptroot  # Disable journal (optional, risky)
```

## Build Script

Create `scripts/build/04-build-filesystem-tools.sh`:

```bash
#!/bin/bash
set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

echo "=== Building filesystem and encryption tools ==="

# Build cryptsetup
echo "Building cryptsetup..."
cd "${PROJECT_ROOT}/sources/toolchain/cryptsetup-2.6.1"
./configure --prefix=/usr
make -j$(nproc)
make install DESTDIR="${PROJECT_ROOT}/builds/cryptsetup"

# Build e2fsprogs (ext4 tools)
echo "Building e2fsprogs..."
cd "${PROJECT_ROOT}/sources/toolchain"
wget -nc https://www.kernel.org/pub/linux/kernel/people/tytso/e2fsprogs/v1.47.0/e2fsprogs-1.47.0.tar.xz
tar -xf e2fsprogs-1.47.0.tar.xz
cd e2fsprogs-1.47.0
./configure --prefix=/usr
make -j$(nproc)
make install DESTDIR="${PROJECT_ROOT}/builds/e2fsprogs"

echo "Filesystem tools build complete"
```

## Security Considerations

1. **Strong passphrase**: Minimum 20 characters for LUKS encryption
2. **Key file backup**: Store recovery key separately
3. **TPM integration**: Consider TPM 2.0 for automatic unlocking
4. **Secure boot**: Verify boot chain integrity

## Testing

Test encryption workflow in VM:
```bash
# Create test image
dd if=/dev/zero of=test.img bs=1G count=10

# Set up loop device
losetup /dev/loop0 test.img

# Test LUKS
cryptsetup luksFormat /dev/loop0
cryptsetup open /dev/loop0 test
mkfs.ext4 /dev/mapper/test
```

## Next Steps

Proceed to **Phase 6: Bootloader (GRUB2)**.

## References
- LUKS Documentation: https://gitlab.com/cryptsetup/cryptsetup
- ext4 Documentation: https://ext4.wiki.kernel.org/
- Timeshift: https://github.com/linuxmint/timeshift
