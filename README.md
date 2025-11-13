# Custom Linux OS - Desktop-First Reliable Distribution

A fully custom Linux distribution built from scratch with a focus on security, privacy, and desktop usability.

## Project Overview

This project implements a complete Linux distribution featuring:

- **Linux Kernel 6.6 LTS** with desktop-optimized configuration
- **KDE Plasma 5.27 LTS** desktop environment
- **LUKS full-disk encryption** by default
- **Secure Boot** support
- **dpkg/APT** package management
- **systemd** init system
- **AppArmor** mandatory access control
- **Timeshift** system snapshots

## Features

### Security
- Full disk encryption (LUKS)
- Secure Boot with signed bootloader and kernel
- AppArmor profiles for critical applications
- UFW firewall enabled by default
- GPG-signed packages
- Kernel hardening (ASLR, SMEP, SMAP, stack protection)

### Privacy
- No telemetry or analytics
- Local backups only
- Privacy-respecting default applications

### Desktop Experience
- KDE Plasma 5.27 LTS with custom theming
- Curated default applications:
  - Firefox ESR (web browser)
  - OnlyOffice (office suite)
  - Dolphin (file manager)
  - Haruna (video player)
  - Sublime Text (editor)
  - Thunderbird (email)
  - Telegram Desktop (messaging)
  - Stacer (system optimizer)

### Reliability
- LTS kernel and desktop environment
- Tested package updates
- Timeshift snapshots for easy rollback
- Point-release update model

## Project Structure

```
_OS/
├── sources/          # Source code for all components
├── builds/           # Compiled binaries
├── configs/          # Configuration files
├── scripts/          # Build automation
│   ├── setup/        # Environment setup
│   └── build/        # Component builds
├── docs/             # Documentation
│   ├── phases/       # Build phases 1-14
│   ├── architecture/ # System design
│   └── user-guides/  # End-user docs
├── iso/              # ISO generation
└── packages/         # APT repository
```

## Build Phases

1. **Phase 1**: Preparation & Toolchain Setup
2. **Phase 2**: Kernel Compilation
3. **Phase 3**: Toolchain & C Library (glibc)
4. **Phase 4**: Init System & Core Utilities
5. **Phase 5**: Filesystem & Encryption
6. **Phase 6**: Bootloader (GRUB2)
7. **Phase 7**: Package Management (dpkg/APT)
8. **Phase 8**: Desktop Environment (KDE Plasma)
9. **Phase 9**: Networking & Security
10. **Phase 10**: Multimedia Support
11. **Phase 11**: Power Management
12. **Phase 12**: ISO & Live Media Creation
13. **Phase 13**: Documentation & User Guides
14. **Phase 14**: Release & Updates

See `docs/phases/` for detailed instructions for each phase.

## Quick Start

### Prerequisites
- Linux host system (Ubuntu 22.04 LTS recommended)
- 16GB+ RAM
- 200GB+ free storage
- Multi-core CPU

### Setup Build Environment

```bash
# Run environment setup
cd scripts/setup
chmod +x 00-prepare-environment.sh
sudo ./00-prepare-environment.sh

# Download sources
cd ../../sources
chmod +x download-sources.sh
./download-sources.sh
```

### Build System

```bash
# Build kernel
cd scripts/build
chmod +x 01-build-kernel.sh
./01-build-kernel.sh

# Continue with subsequent phases...
```

## Documentation

- **Roadmap**: `os_build_roadmap.md`
- **Architecture**: `docs/architecture/system-overview.md`
- **Build Phases**: `docs/phases/phase-*.md`
- **Version Info**: `versions.txt` (generated)

## System Requirements

### Minimum
- 64-bit x86 processor
- 4GB RAM
- 25GB storage
- UEFI firmware (BIOS legacy supported)

### Recommended
- Modern multi-core processor
- 8GB+ RAM
- 50GB+ SSD storage
- UEFI with Secure Boot

## Security

- All packages are GPG-signed
- Full system encryption available
- Regular security updates
- AppArmor mandatory access control
- Minimal attack surface

See `docs/phases/phase-09-14-remaining.md` for security audit checklist.

## License

This project integrates multiple open-source components, each with their own licenses:
- Linux kernel: GPL-2.0
- glibc: LGPL-2.1
- systemd: LGPL-2.1
- KDE Plasma: GPL-2.0+
- Individual applications: See respective licenses

See `LICENSE` for full distribution license information.

## Contributing

This is a custom build project. Contributions, suggestions, and issue reports are welcome.

## Support

For questions and issues:
- Review documentation in `docs/`
- Check troubleshooting guides
- Open an issue on the repository

## Version

**Current Version**: 1.0.0 (Development)
**Codename**: Pioneer
**Status**: In Development
Custom Linux OS
