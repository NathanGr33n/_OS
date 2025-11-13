# Phase 4: Init System & Core Utilities

## Overview
Install systemd as the init system and essential core utilities for the OS.

## Components
- **systemd 254** - Init system, service manager, and system daemon
- **bash 5.2** - Shell
- **coreutils 9.3** - Core GNU utilities (ls, cp, mv, etc.)
- **util-linux 2.39** - System utilities
- **procps-ng 4.0** - Process monitoring tools

## systemd Build

### Download
```bash
cd sources/systemd
git clone --depth 1 --branch v254 https://github.com/systemd/systemd.git
cd systemd
```

### Dependencies
```bash
# Install build dependencies
sudo apt install -y \
    meson ninja-build \
    libcap-dev \
    libmount-dev \
    libblkid-dev \
    libkmod-dev \
    libseccomp-dev \
    libgcrypt20-dev \
    libgpg-error-dev \
    libpam0g-dev \
    python3-jinja2
```

### Build systemd
```bash
meson setup build \
    --prefix=/usr \
    --sysconfdir=/etc \
    --localstatedir=/var \
    -Drootprefix=/ \
    -Dsysvinit-path=/etc/init.d \
    -Dsysvrcnd-path=/etc/rc.d

ninja -C build
DESTDIR="${PROJECT_ROOT}/builds/systemd" ninja -C build install
```

## Core Utilities

### bash
```bash
cd sources/toolchain
wget https://ftp.gnu.org/gnu/bash/bash-5.2.tar.gz
tar -xf bash-5.2.tar.gz
cd bash-5.2

./configure --prefix=/usr
make -j$(nproc)
make install DESTDIR="${PROJECT_ROOT}/builds/bash"
```

### coreutils
```bash
cd sources/toolchain
wget https://ftp.gnu.org/gnu/coreutils/coreutils-9.3.tar.xz
tar -xf coreutils-9.3.tar.xz
cd coreutils-9.3

./configure --prefix=/usr
make -j$(nproc)
make install DESTDIR="${PROJECT_ROOT}/builds/coreutils"
```

### Essential utilities list
- **File operations**: ls, cp, mv, rm, mkdir, rmdir, ln, chmod, chown
- **Text processing**: cat, grep, sed, awk, cut, sort, uniq
- **System**: ps, top, free, df, du, mount, umount
- **Network**: ip, ping, wget, curl

## systemd Configuration

Create default systemd configuration:

### Basic targets
```bash
# configs/systemd/system.conf
[Manager]
LogLevel=info
DefaultStandardOutput=journal
DefaultStandardError=journal
```

### Default services
```ini
# configs/systemd/services/networking.service
[Unit]
Description=Network Configuration
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/bin/systemctl restart NetworkManager

[Install]
WantedBy=multi-user.target
```

## Build Script

Create `scripts/build/03-build-systemd.sh`:

```bash
#!/bin/bash
set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SYSTEMD_SRC="${PROJECT_ROOT}/sources/systemd/systemd"
BUILD_DIR="${PROJECT_ROOT}/builds/systemd"

echo "=== Building systemd ==="

if [ ! -d "${SYSTEMD_SRC}" ]; then
    echo "Error: systemd source not found"
    exit 1
fi

cd "${SYSTEMD_SRC}"

meson setup build \
    --prefix=/usr \
    --sysconfdir=/etc \
    --localstatedir=/var \
    -Drootprefix=/ \
    -Dsysvinit-path=/etc/init.d

ninja -C build
DESTDIR="${BUILD_DIR}" ninja -C build install

echo "systemd build complete: ${BUILD_DIR}"
```

## Verification

Check systemd components:
```bash
ls builds/systemd/usr/lib/systemd/
# Should show: systemd, systemd-journald, etc.

ls builds/systemd/usr/bin/
# Should show: systemctl, journalctl, etc.
```

## Next Steps

Proceed to **Phase 5: Filesystem & Encryption**.

## References
- systemd Documentation: https://www.freedesktop.org/wiki/Software/systemd/
- systemd for Administrators: https://www.freedesktop.org/wiki/Software/systemd/InitrdInterface/
