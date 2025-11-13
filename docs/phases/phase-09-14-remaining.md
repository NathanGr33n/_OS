# Phases 9-14: Networking, Multimedia, Power, ISO, Documentation & Release

## Phase 9: Networking & Security

### NetworkManager
```bash
cd sources/toolchain
git clone --depth 1 https://gitlab.freedesktop.org/NetworkManager/NetworkManager.git
cd NetworkManager

meson setup build --prefix=/usr
ninja -C build
ninja -C build install DESTDIR="${PROJECT_ROOT}/builds/networkmanager"
```

### UFW (Uncomplicated Firewall)
```bash
sudo apt install ufw
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw enable
```

### AppArmor Profiles
Create profiles in `configs/apparmor/`:

```
# /etc/apparmor.d/usr.bin.firefox
#include <tunables/global>

/usr/bin/firefox {
  #include <abstractions/base>
  #include <abstractions/nameservice>
  #include <abstractions/user-tmp>
  
  /usr/bin/firefox mr,
  /usr/lib/firefox/** mr,
  @{HOME}/.mozilla/** rw,
  
  deny /etc/shadow r,
  deny /root/** rw,
}
```

---

## Phase 10: Multimedia Support

### Codecs to Include
- **Audio**: MP3, AAC, FLAC, OGG Vorbis, Opus
- **Video**: H.264, H.265 (HEVC), VP8, VP9, AV1
- **Container formats**: MP4, MKV, WebM, AVI

### FFmpeg Build
```bash
cd sources/apps
git clone --depth 1 https://git.ffmpeg.org/ffmpeg.git
cd ffmpeg

./configure \
    --prefix=/usr \
    --enable-gpl \
    --enable-version3 \
    --enable-nonfree \
    --enable-shared \
    --enable-libmp3lame \
    --enable-libvorbis \
    --enable-libvpx \
    --enable-libx264 \
    --enable-libx265

make -j$(nproc)
make install DESTDIR="${PROJECT_ROOT}/builds/ffmpeg"
```

### GStreamer Plugins
```bash
# Good plugins (common formats)
sudo apt install gstreamer1.0-plugins-good

# Bad plugins (less common formats)
sudo apt install gstreamer1.0-plugins-bad

# Ugly plugins (patent-encumbered)
sudo apt install gstreamer1.0-plugins-ugly

# libav (FFmpeg wrapper)
sudo apt install gstreamer1.0-libav
```

---

## Phase 11: Power Management

### TLP Installation
```bash
cd sources/apps
git clone --depth 1 https://github.com/linrunner/TLP.git
cd TLP

make install DESTDIR="${PROJECT_ROOT}/builds/tlp"
```

### TLP Configuration
Create `configs/tlp/tlp.conf`:

```bash
# /etc/tlp.conf
TLP_ENABLE=1
TLP_DEFAULT_MODE=AC
TLP_PERSISTENT_DEFAULT=0

CPU_SCALING_GOVERNOR_ON_AC=performance
CPU_SCALING_GOVERNOR_ON_BAT=powersave

CPU_ENERGY_PERF_POLICY_ON_AC=performance
CPU_ENERGY_PERF_POLICY_ON_BAT=power

DISK_DEVICES="sda sdb"
DISK_APM_LEVEL_ON_AC="254 254"
DISK_APM_LEVEL_ON_BAT="128 128"

WIFI_PWR_ON_AC=off
WIFI_PWR_ON_BAT=on

RUNTIME_PM_ON_AC=on
RUNTIME_PM_ON_BAT=auto
```

### ACPI Events
```bash
# /etc/acpi/events/lid
event=button/lid.*
action=/etc/acpi/lid.sh

# /etc/acpi/lid.sh
#!/bin/bash
if grep -q closed /proc/acpi/button/lid/*/state; then
    systemctl suspend
fi
```

---

## Phase 12: ISO & Live Media Creation

### ISO Build Process

#### 1. Create filesystem structure
```bash
mkdir -p iso/{live,isolinux,boot/grub}
```

#### 2. Install system to squashfs
```bash
# Copy built system
rsync -av builds/ iso/live/rootfs/

# Create squashfs
mksquashfs iso/live/rootfs iso/live/filesystem.squashfs -comp xz
```

#### 3. Calamares Installer
```bash
cd sources/apps
git clone --depth 1 https://github.com/calamares/calamares.git
cd calamares

mkdir build && cd build
cmake .. \
    -DCMAKE_INSTALL_PREFIX=/usr \
    -DWITH_PYTHONQT=OFF

make -j$(nproc)
make install DESTDIR="${PROJECT_ROOT}/builds/calamares"
```

#### 4. Calamares Configuration
Create `configs/calamares/settings.conf`:

```yaml
modules-search: [ local ]

sequence:
- show:
  - welcome
  - locale
  - keyboard
  - partition
  - users
  - summary
- exec:
  - partition
  - mount
  - unpackfs
  - machineid
  - fstab
  - locale
  - keyboard
  - localecfg
  - users
  - displaymanager
  - networkcfg
  - hwclock
  - services-systemd
  - bootloader
  - grubcfg
  - umount
- show:
  - finished

branding: custom-linux-os

disable-cancel: false
disable-cancel-during-exec: true
quit-at-end: false
```

#### 5. Generate ISO
```bash
#!/bin/bash
# scripts/build/10-generate-iso.sh

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ISO_DIR="${PROJECT_ROOT}/iso"
OUTPUT_ISO="${PROJECT_ROOT}/custom-linux-os.iso"

# Create ISO with GRUB
grub-mkrescue -o "${OUTPUT_ISO}" "${ISO_DIR}"

# Make hybrid ISO (USB bootable)
isohybrid "${OUTPUT_ISO}"

echo "ISO created: ${OUTPUT_ISO}"
```

---

## Phase 13: Documentation & User Guides

### Create User Documentation

#### 1. Installation Guide
Create `docs/user-guides/installation.md`:

```markdown
# Installation Guide

## Requirements
- 64-bit x86 processor
- 4GB RAM minimum (8GB recommended)
- 25GB disk space
- UEFI firmware (BIOS legacy supported)

## Steps
1. Create bootable USB with Etcher/Rufus
2. Boot from USB
3. Run Calamares installer
4. Select language and timezone
5. Partition disk (automatic or manual)
6. Enable LUKS encryption (recommended)
7. Create user account
8. Install bootloader
9. Reboot and enjoy!
```

#### 2. Troubleshooting Guide
Create `docs/user-guides/troubleshooting.md`:

```markdown
# Troubleshooting

## Boot Issues
- **Black screen**: Add `nomodeset` to kernel parameters
- **No WiFi**: Check `lspci` for wireless card, install firmware
- **LUKS password not accepted**: Check keyboard layout

## Graphics Issues
- **Low resolution**: Install proprietary drivers (nvidia/amd)
- **Tearing**: Enable compositor in KDE settings

## Recovery Mode
- Select recovery in GRUB menu
- Run `fsck` to check filesystem
- Use Timeshift to restore snapshot
```

#### 3. Package Management Guide
Create `docs/user-guides/package-management.md`:

```markdown
# Package Management

## Basic Commands
```bash
# Update package list
sudo apt update

# Upgrade packages
sudo apt upgrade

# Install package
sudo apt install package-name

# Remove package
sudo apt remove package-name

# Search for package
apt search keyword
```

## Repository Management
Repository configuration: `/etc/apt/sources.list`
```

---

## Phase 14: Release & Updates

### Release Checklist

1. **Version bump**: Update version in all relevant files
2. **Changelog**: Document all changes since last release
3. **Testing**: Full system test on multiple hardware configs
4. **Security audit**: Run security scanners
5. **ISO generation**: Build and test ISO
6. **Repository update**: Push packages to repository
7. **Documentation update**: Update all user guides
8. **Announcement**: Prepare release notes

### Release Script
Create `scripts/build/release.sh`:

```bash
#!/bin/bash
set -e

VERSION="1.0.0"
CODENAME="Pioneer"

echo "=== Building Release ${VERSION} (${CODENAME}) ==="

# Build all components
./scripts/build/01-build-kernel.sh
./scripts/build/03-build-systemd.sh
./scripts/build/07-build-kde.sh

# Create packages
./scripts/build/package-all.sh

# Generate repository
./scripts/build/generate-repository.sh

# Create ISO
./scripts/build/10-generate-iso.sh

# Generate checksums
cd iso
sha256sum custom-linux-os-${VERSION}.iso > SHA256SUMS
gpg --detach-sign --armor SHA256SUMS

echo "Release ${VERSION} complete!"
```

### Update Management

#### Delta Updates
```bash
# Generate delta update
xdelta3 -e -s old-version.iso new-version.iso delta-update.xdelta

# Apply delta
xdelta3 -d -s old-version.iso delta-update.xdelta new-version.iso
```

#### APT Repository Updates
```bash
# scripts/build/push-updates.sh
#!/bin/bash

# Sign packages
for deb in packages/repository/pool/main/*/*.deb; do
    dpkg-sig --sign builder "$deb"
done

# Update repository
./scripts/build/generate-repository.sh

# Sync to server
rsync -avz --delete packages/repository/ server:/var/www/repo/
```

### Update Announcement Template
```markdown
# Custom Linux OS v${VERSION} Release Notes

## New Features
- Feature 1
- Feature 2

## Improvements
- Improvement 1
- Improvement 2

## Bug Fixes
- Fix 1
- Fix 2

## Security Updates
- CVE-XXXX-XXXX: Description

## Known Issues
- Issue 1 (workaround)

## Upgrade Instructions
```bash
sudo apt update
sudo apt dist-upgrade
```

## Download
- ISO: https://customlinux.org/download/v${VERSION}
- Torrent: https://customlinux.org/download/v${VERSION}.torrent
- SHA256: <checksum>
```

---

## Security Review Checklist

### System Security
- [ ] AppArmor profiles enabled for all critical applications
- [ ] LUKS encryption working properly
- [ ] Secure Boot chain validated
- [ ] Default firewall rules configured
- [ ] No unnecessary services running
- [ ] All packages signed and verified
- [ ] Root password policy enforced
- [ ] SSH hardened (key-only, no root)

### Network Security
- [ ] UFW enabled by default
- [ ] NetworkManager secure configuration
- [ ] DNS over HTTPS available
- [ ] VPN integration tested

### Application Security
- [ ] Firefox hardened configuration
- [ ] No telemetry in default applications
- [ ] Automatic security updates optional
- [ ] Package repository HTTPS-only

### Privacy
- [ ] No analytics or telemetry
- [ ] Local backups only (Timeshift)
- [ ] Private browsing mode by default option
- [ ] Clear privacy policy documented

---

## Build Verification

### Final System Tests
```bash
# Check all critical services
systemctl status systemd-journald
systemctl status NetworkManager
systemctl status sddm

# Verify encryption
cryptsetup status cryptroot

# Test package management
apt update
apt search firefox

# Check kernel
uname -a
lsmod | grep drm

# Verify security
aa-status
ufw status
```

### ISO Testing
- [ ] Boots on UEFI systems
- [ ] Boots on BIOS/Legacy systems
- [ ] Live mode functional
- [ ] Installer completes successfully
- [ ] Encrypted install works
- [ ] Network connectivity in live mode
- [ ] All default applications launch

---

## Performance Benchmarks

Document baseline performance:
- Boot time (UEFI to login): Target <30 seconds
- Memory usage (idle): Target <1GB
- Disk usage (base install): Target <10GB
- Application launch times
- System responsiveness

---

## Maintenance Plan

### Regular Tasks
- **Daily**: Monitor issue tracker
- **Weekly**: Security updates review
- **Monthly**: Package updates
- **Quarterly**: Major point releases
- **Annually**: LTS version updates

### Community Support
- Forum: https://forum.customlinux.org
- Bug tracker: https://github.com/customlinux/os/issues
- Documentation wiki: https://wiki.customlinux.org
- IRC/Discord: #customlinux

---

## License and Legal

Ensure all components comply with licensing:
- GPL components properly attributed
- Proprietary firmware clearly marked
- Third-party licenses included
- Copyright notices in place

Create `LICENSE` file with overall distribution license.
