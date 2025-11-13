# Phase 7: Package Management

## Overview
Build dpkg and APT from source, create package repository infrastructure.

## Components
- **dpkg 1.21.22** - Package format and low-level package manager
- **APT 2.6.1** - High-level package management tool
- **Repository infrastructure** - Package hosting and distribution
- **Package signing** - GPG key management for security

## dpkg Build

### Download
```bash
cd sources/toolchain
wget https://deb.debian.org/debian/pool/main/d/dpkg/dpkg_1.21.22.tar.xz
tar -xf dpkg_1.21.22.tar.xz
cd dpkg-1.21.22
```

### Dependencies
```bash
sudo apt install -y \
    libmd-dev \
    libz-dev \
    libbz2-dev \
    liblzma-dev \
    libzstd-dev \
    libselinux1-dev \
    po4a
```

### Build dpkg
```bash
./configure \
    --prefix=/usr \
    --sysconfdir=/etc \
    --localstatedir=/var \
    --disable-dselect \
    --disable-start-stop-daemon

make -j$(nproc)
make install DESTDIR="${PROJECT_ROOT}/builds/dpkg"
```

## APT Build

### Download
```bash
cd sources/toolchain
wget https://deb.debian.org/debian/pool/main/a/apt/apt_2.6.1.tar.xz
tar -xf apt_2.6.1.tar.xz
cd apt-2.6.1
```

### Dependencies
```bash
sudo apt install -y \
    libgnutls28-dev \
    libseccomp-dev \
    libdb-dev \
    libudev-dev \
    libgtest-dev \
    googletest \
    triehash
```

### Build APT
```bash
mkdir build
cd build

cmake .. \
    -DCMAKE_INSTALL_PREFIX=/usr \
    -DCMAKE_BUILD_TYPE=Release \
    -DSTATE_DIR=/var/lib/apt \
    -DCACHE_DIR=/var/cache/apt

make -j$(nproc)
make install DESTDIR="${PROJECT_ROOT}/builds/apt"
```

## Repository Structure

Create repository directory structure:

```
packages/repository/
├── dists/
│   └── stable/
│       ├── main/
│       │   ├── binary-amd64/
│       │   │   ├── Packages
│       │   │   ├── Packages.gz
│       │   │   └── Release
│       │   └── source/
│       ├── InRelease
│       └── Release
└── pool/
    └── main/
        ├── a/
        ├── b/
        └── [packages organized alphabetically]
```

## Package Building Guidelines

### Package Structure
```
package-name-1.0/
├── DEBIAN/
│   ├── control
│   ├── postinst
│   ├── prerm
│   ├── postrm
│   └── conffiles
├── usr/
│   ├── bin/
│   ├── lib/
│   └── share/
└── etc/
```

### Control File Template
```
Package: package-name
Version: 1.0-1
Section: base
Priority: optional
Architecture: amd64
Depends: libc6 (>= 2.38)
Maintainer: Custom Linux OS <maintainer@example.com>
Description: Short description
 Longer description that can span
 multiple lines with proper indentation.
```

### Build Package
```bash
# Create package
dpkg-deb --build package-name-1.0

# Verify
dpkg-deb --info package-name-1.0.deb
dpkg-deb --contents package-name-1.0.deb
```

## Repository Management

### Generate Package Index

Create `scripts/build/generate-repository.sh`:

```bash
#!/bin/bash
set -e

REPO_DIR="${PROJECT_ROOT}/packages/repository"
DIST="stable"
COMPONENT="main"
ARCH="amd64"

cd "${REPO_DIR}"

# Create Packages file
dpkg-scanpackages pool/main /dev/null > dists/${DIST}/${COMPONENT}/binary-${ARCH}/Packages
gzip -9c dists/${DIST}/${COMPONENT}/binary-${ARCH}/Packages > dists/${DIST}/${COMPONENT}/binary-${ARCH}/Packages.gz

# Generate Release file
apt-ftparchive release dists/${DIST} > dists/${DIST}/Release

# Sign Release file
gpg --default-key ${GPG_KEY_ID} -abs -o dists/${DIST}/Release.gpg dists/${DIST}/Release
gpg --default-key ${GPG_KEY_ID} --clearsign -o dists/${DIST}/InRelease dists/${DIST}/Release

echo "Repository updated"
```

### GPG Key Management

Generate repository signing key:

```bash
# Generate key
gpg --full-generate-key

# Export public key
gpg --armor --export ${KEY_ID} > ${PROJECT_ROOT}/packages/repository/public.key

# Users will import with:
# wget -qO- https://repo.example.com/public.key | apt-key add -
```

## APT Configuration

### sources.list

Create `configs/apt/sources.list`:

```
# Custom Linux OS Repository
deb [signed-by=/usr/share/keyrings/custom-linux-os.gpg] https://repo.customlinux.org/apt stable main
deb-src [signed-by=/usr/share/keyrings/custom-linux-os.gpg] https://repo.customlinux.org/apt stable main

# Security updates
deb [signed-by=/usr/share/keyrings/custom-linux-os.gpg] https://repo.customlinux.org/apt stable-security main
```

### apt.conf.d configurations

Create `configs/apt/apt.conf.d/`:

```bash
# 50unattended-upgrades
Unattended-Upgrade::Allowed-Origins {
    "CustomLinuxOS:stable";
    "CustomLinuxOS:stable-security";
};

Unattended-Upgrade::Package-Blacklist {
};

Unattended-Upgrade::AutoFixInterruptedDpkg "true";
Unattended-Upgrade::MinimalSteps "true";
Unattended-Upgrade::Remove-Unused-Dependencies "true";
Unattended-Upgrade::Automatic-Reboot "false";
```

## Package Versioning Scheme

Follow semantic versioning with Debian epoch:

```
[epoch:]upstream-version[-debian-revision]

Examples:
- 1.0.0-1       (initial release)
- 1.0.1-1       (upstream update)
- 1.0.1-2       (packaging fix)
- 1:2.0.0-1     (epoch bump for version reset)
```

## Essential Packages List

Create initial package set:

1. **Base system**
   - base-files
   - base-passwd
   - dpkg
   - apt
   - libc6

2. **Core utilities**
   - coreutils
   - bash
   - grep
   - sed
   - gawk

3. **System**
   - systemd
   - udev
   - dbus

4. **Networking**
   - network-manager
   - openssh-client
   - openssh-server

5. **Desktop**
   - plasma-desktop
   - kde-applications
   - sddm

## Automated Package Building

Create `scripts/build/build-package.sh`:

```bash
#!/bin/bash
set -e

PACKAGE_NAME=$1
VERSION=$2

if [ -z "$PACKAGE_NAME" ] || [ -z "$VERSION" ]; then
    echo "Usage: $0 <package-name> <version>"
    exit 1
fi

WORK_DIR="${PROJECT_ROOT}/packages/build/${PACKAGE_NAME}-${VERSION}"
POOL_DIR="${PROJECT_ROOT}/packages/repository/pool/main/${PACKAGE_NAME:0:1}/${PACKAGE_NAME}"

echo "Building package: ${PACKAGE_NAME} ${VERSION}"

# Build source
cd "${WORK_DIR}"
dpkg-buildpackage -us -uc -b

# Move to pool
mkdir -p "${POOL_DIR}"
mv ../*.deb "${POOL_DIR}/"

# Update repository
./scripts/build/generate-repository.sh

echo "Package built and added to repository"
```

## Repository Mirroring

For updates, use repository mirroring:

```bash
#!/bin/bash
# scripts/build/sync-mirror.sh

UPSTREAM="https://upstream-mirror.com/repository"
LOCAL="${PROJECT_ROOT}/packages/repository"

rsync -avz --delete \
    --exclude='*.src.*' \
    ${UPSTREAM}/ ${LOCAL}/

./scripts/build/generate-repository.sh
```

## Security Best Practices

1. **Sign all packages**: Use GPG for package and repository signing
2. **HTTPS only**: Serve repository over HTTPS
3. **Regular updates**: Establish update schedule for security patches
4. **Audit trail**: Log all package installations and updates
5. **Reproducible builds**: Ensure deterministic package builds

## Build Script

Create `scripts/build/06-build-package-management.sh`:

```bash
#!/bin/bash
set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

echo "=== Building Package Management Tools ==="

# Build dpkg
cd "${PROJECT_ROOT}/sources/toolchain/dpkg-1.21.22"
./configure --prefix=/usr --sysconfdir=/etc --localstatedir=/var
make -j$(nproc)
make install DESTDIR="${PROJECT_ROOT}/builds/dpkg"

# Build APT
cd "${PROJECT_ROOT}/sources/toolchain/apt-2.6.1/build"
cmake .. -DCMAKE_INSTALL_PREFIX=/usr
make -j$(nproc)
make install DESTDIR="${PROJECT_ROOT}/builds/apt"

echo "Package management tools build complete"
```

## Testing

Test package installation:
```bash
# Install package
dpkg -i package.deb

# List installed packages
dpkg -l

# Remove package
dpkg -r package-name

# Update package list
apt update

# Install via APT
apt install package-name
```

## Next Steps

Proceed to **Phase 8: Desktop Environment (KDE Plasma)**.

## References
- dpkg Documentation: https://man7.org/linux/man-pages/man1/dpkg.1.html
- APT User's Guide: https://www.debian.org/doc/manuals/apt-guide/
- Debian Policy Manual: https://www.debian.org/doc/debian-policy/
- Creating Debian Packages: https://www.debian.org/doc/manuals/maint-guide/
