# Phase 1: Preparation & Toolchain Setup

## Overview
This phase establishes the development environment and acquires all necessary tools for building a custom Linux distribution from scratch.

## Host System Requirements

### Recommended Host OS
- **Linux-based system** (Ubuntu 22.04 LTS, Debian 12, Fedora 38+, or Arch Linux)
- Alternative: WSL2 on Windows with Ubuntu 22.04
- **NOT recommended**: Native Windows (limited compatibility with build tools)

### Hardware Requirements
- CPU: Multi-core processor (8+ cores recommended for parallel builds)
- RAM: 16GB minimum, 32GB recommended
- Storage: 200GB+ free space (sources, builds, and ISO generation)
- Network: Stable broadband connection for downloading sources

## Required Build Tools

### Core Development Tools
```bash
# Debian/Ubuntu-based systems
sudo apt update
sudo apt install -y \
    build-essential \
    gcc g++ make \
    binutils \
    bison flex \
    gawk \
    texinfo \
    git \
    wget curl \
    patch \
    bc \
    libssl-dev \
    libelf-dev \
    libncurses-dev \
    pkg-config \
    autoconf automake libtool \
    gettext \
    python3 python3-pip \
    rsync \
    xz-utils \
    cpio \
    unzip
```

### Cross-Compilation Support (if needed)
```bash
# For building on x86_64 for x86_64
sudo apt install -y gcc-multilib g++-multilib

# For other architectures (if cross-compiling)
sudo apt install -y crossbuild-essential-arm64  # Example for ARM64
```

### Version Control
```bash
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
```

## Directory Structure Setup

Project structure (already created):
```
_OS/
├── sources/          # Source code for all components
│   ├── kernel/       # Linux kernel source
│   ├── toolchain/    # GCC, binutils, glibc
│   ├── systemd/      # Init system
│   ├── kde/          # KDE Plasma desktop
│   └── apps/         # Default applications
├── builds/           # Compiled binaries and build artifacts
├── configs/          # Configuration files
│   ├── kernel/       # Kernel .config files
│   ├── systemd/      # Systemd unit files
│   └── kde/          # KDE customization configs
├── scripts/          # Build automation scripts
│   ├── build/        # Component build scripts
│   └── setup/        # Environment setup scripts
├── docs/             # Documentation
│   ├── phases/       # Phase-by-phase guides
│   ├── architecture/ # System architecture docs
│   └── user-guides/  # End-user documentation
├── iso/              # ISO generation workspace
└── packages/         # Package repository
    └── repository/   # APT repository structure
```

## Component Versions (LTS Focus)

### Core Components
| Component | Version | Source URL | Notes |
|-----------|---------|------------|-------|
| Linux Kernel | 6.6 LTS | https://kernel.org | Released Dec 2023, supported until Dec 2026 |
| glibc | 2.38 | https://ftp.gnu.org/gnu/glibc/ | Latest stable |
| GCC | 13.2 | https://ftp.gnu.org/gnu/gcc/ | For toolchain build |
| systemd | 254 | https://github.com/systemd/systemd | Latest stable |
| GRUB | 2.06 | https://ftp.gnu.org/gnu/grub/ | UEFI bootloader |

### Desktop Environment
| Component | Version | Source URL | Notes |
|-----------|---------|------------|-------|
| KDE Plasma | 5.27 LTS | https://download.kde.org/stable/plasma/ | LTS release |
| Qt | 5.15 LTS | https://download.qt.io/official_releases/qt/ | Required for KDE |

### Package Management
| Component | Version | Source URL | Notes |
|-----------|---------|------------|-------|
| dpkg | 1.21.22 | https://salsa.debian.org/dpkg-team/dpkg | Package format |
| APT | 2.6.1 | https://salsa.debian.org/apt-team/apt | Package manager |

### Default Applications
| Application | Version | Purpose | Source |
|-------------|---------|---------|--------|
| Firefox | Latest ESR | Web browser | Mozilla repositories |
| OnlyOffice | Latest | Office suite | OnlyOffice repositories |
| Dolphin | (with KDE) | File manager | KDE Plasma |
| Haruna | Latest | Video player | https://github.com/g-fb/haruna |
| Sublime Text | Latest | Text editor | Sublime repositories |
| Thunderbird | Latest | Email client | Mozilla repositories |
| Telegram Desktop | Latest | Messaging | Telegram repositories |
| Stacer | Latest | System optimizer | https://github.com/oguzhaninan/Stacer |

## Setup Script

Create the environment setup script (see `scripts/setup/00-prepare-environment.sh`).

## Verification Checklist

- [ ] Host OS meets minimum requirements
- [ ] All development tools installed
- [ ] Directory structure created
- [ ] Component versions documented
- [ ] Git repository initialized
- [ ] Network connectivity verified
- [ ] Storage space verified (200GB+ free)

## Next Steps

Proceed to **Phase 2: Kernel Compilation** once all tools are installed and the environment is ready.

## Troubleshooting

### Issue: Missing dependencies
**Solution**: Run `sudo apt build-dep linux` to install kernel build dependencies.

### Issue: Insufficient disk space
**Solution**: Clean up host system or add external storage. The build process requires significant space.

### Issue: Slow downloads
**Solution**: Use a mirror closer to your location. Update `/etc/apt/sources.list` or use download managers.

## Additional Resources

- Linux From Scratch: https://www.linuxfromscratch.org/
- Kernel Build Documentation: https://www.kernel.org/doc/html/latest/
- GCC Documentation: https://gcc.gnu.org/onlinedocs/
