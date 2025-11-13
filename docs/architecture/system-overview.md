# System Architecture Overview

## Layer Architecture

```
┌─────────────────────────────────────────────────────────┐
│                   User Applications                      │
│  Firefox, OnlyOffice, Dolphin, Haruna, Telegram, etc.  │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│              KDE Plasma Desktop Environment              │
│         Qt 5.15 LTS • SDDM • Plasma 5.27 LTS            │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│                  System Services Layer                   │
│  NetworkManager • D-Bus • PulseAudio • systemd-logind   │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│              Core System (systemd + glibc)               │
│   bash • coreutils • systemd • journald • udev          │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│                    Linux Kernel 6.6 LTS                  │
│  Drivers • Filesystems • Security • Power Management    │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│                  Hardware (x86_64)                       │
│      CPU • GPU • Storage • Network • Peripherals        │
└─────────────────────────────────────────────────────────┘
```

## Boot Process

1. **UEFI Firmware** → Loads GRUB2 bootloader
2. **GRUB2** → Prompts for LUKS password, loads kernel
3. **Kernel** → Initializes hardware, mounts initramfs
4. **initramfs** → Unlocks encrypted root, pivots to real root
5. **systemd** → Init system starts services
6. **SDDM** → Display manager presents login
7. **KDE Plasma** → Desktop environment launches

## Security Architecture

### Multi-Layer Security

```
┌─────────────────────────────────────────┐
│         Secure Boot (UEFI)               │  Hardware Root of Trust
├─────────────────────────────────────────┤
│         Signed Bootloader (shim)         │  Verified Boot Chain
├─────────────────────────────────────────┤
│         GRUB2 (signed)                   │  Bootloader Integrity
├─────────────────────────────────────────┤
│         Kernel (signed)                  │  Kernel Verification
├─────────────────────────────────────────┤
│         LUKS Full Disk Encryption        │  Data-at-Rest Protection
├─────────────────────────────────────────┤
│         AppArmor Mandatory Access        │  Application Confinement
├─────────────────────────────────────────┤
│         UFW Firewall                     │  Network Protection
├─────────────────────────────────────────┤
│         Signed Packages (GPG)            │  Software Integrity
└─────────────────────────────────────────┘
```

### Security Features

- **Kernel Hardening**: ASLR, SMEP, SMAP, stack protectors
- **AppArmor**: Mandatory access control for critical apps
- **LUKS**: AES-256 full disk encryption
- **Secure Boot**: Verified boot chain from firmware to OS
- **Firewall**: UFW enabled by default
- **Package Signing**: All packages GPG signed
- **No Telemetry**: Privacy-first design

## Filesystem Hierarchy

```
/                     Root filesystem (ext4, LUKS encrypted)
├── bin → usr/bin     Essential user binaries
├── boot              Kernel, initramfs, GRUB config
│   └── efi           EFI System Partition (FAT32)
├── dev               Device files (devtmpfs)
├── etc               System configuration files
│   ├── apt           Package manager config
│   ├── systemd       Init system config
│   ├── apparmor.d    Security profiles
│   └── default       Default configurations
├── home              User home directories
├── lib → usr/lib     Essential shared libraries
├── mnt               Temporary mount points
├── opt               Optional software packages
├── proc              Process information (procfs)
├── root              Root user home directory
├── run               Runtime variable data
├── sbin → usr/sbin   System binaries
├── srv               Service data
├── sys               System information (sysfs)
├── tmp               Temporary files (tmpfs)
├── usr               User programs and data
│   ├── bin           User binaries
│   ├── include       C header files
│   ├── lib           Libraries
│   ├── local         Local hierarchy
│   ├── sbin          System binaries
│   └── share         Architecture-independent data
└── var               Variable data
    ├── cache         Application cache
    ├── lib           State information
    ├── log           Log files
    └── tmp           Temporary files
```

## Package Management Architecture

```
┌──────────────────────────────────────────┐
│           User (apt commands)             │
└──────────────────────────────────────────┘
                    ↓
┌──────────────────────────────────────────┐
│         APT (High-level Manager)          │
│  • Dependency resolution                  │
│  • Repository management                  │
│  • Download/cache handling                │
└──────────────────────────────────────────┘
                    ↓
┌──────────────────────────────────────────┐
│      dpkg (Low-level Package Manager)     │
│  • Package installation                   │
│  • File extraction                        │
│  • Maintainer scripts execution           │
└──────────────────────────────────────────┘
                    ↓
┌──────────────────────────────────────────┐
│        Filesystem (/usr, /etc, etc.)      │
└──────────────────────────────────────────┘

Repository Structure:
┌──────────────────────────────────────────┐
│     APT Repository (HTTPS, GPG-signed)    │
│  • dists/stable/main/binary-amd64/        │
│  • pool/main/[a-z]/package/               │
│  • InRelease (signed metadata)            │
└──────────────────────────────────────────┘
```

## Network Architecture

```
┌─────────────────────────────────────────┐
│        Applications (Firefox, etc.)      │
└─────────────────────────────────────────┘
                  ↓
┌─────────────────────────────────────────┐
│             NetworkManager               │
│  • Connection management                 │
│  • WiFi/Ethernet handling                │
│  • VPN integration                       │
└─────────────────────────────────────────┘
                  ↓
┌─────────────────────────────────────────┐
│          Firewall (UFW/iptables)         │
│  • Default deny incoming                 │
│  • Allow outgoing                        │
│  • Per-application rules                 │
└─────────────────────────────────────────┘
                  ↓
┌─────────────────────────────────────────┐
│            Kernel Networking             │
│  • TCP/IP stack                          │
│  • Network drivers                       │
└─────────────────────────────────────────┘
                  ↓
┌─────────────────────────────────────────┐
│      Hardware (NIC, WiFi Adapter)        │
└─────────────────────────────────────────┘
```

## Desktop Session Flow

```
Boot → SDDM Login
         ↓
    User Authentication
         ↓
    Start Plasma Session
         ↓
    ┌──────────────────────────────┐
    │   KWin (Window Manager)       │
    │   • Window management         │
    │   • Compositing               │
    │   • Effects                   │
    └──────────────────────────────┘
         ↓
    ┌──────────────────────────────┐
    │   Plasma Shell                │
    │   • Desktop                   │
    │   • Panels                    │
    │   • Widgets                   │
    └──────────────────────────────┘
         ↓
    ┌──────────────────────────────┐
    │   System Services             │
    │   • D-Bus                     │
    │   • PulseAudio                │
    │   • NetworkManager            │
    │   • Bluetooth                 │
    └──────────────────────────────┘
         ↓
    User Desktop Ready
```

## System Services (systemd)

### Critical Services
- `systemd-journald.service` - Logging
- `systemd-udevd.service` - Device management
- `dbus.service` - Inter-process communication
- `NetworkManager.service` - Network management
- `sddm.service` - Display manager
- `tlp.service` - Power management

### Service Dependencies
```
graphical.target
├── multi-user.target
│   ├── network.target
│   │   └── NetworkManager.service
│   ├── dbus.service
│   ├── systemd-journald.service
│   └── systemd-logind.service
└── sddm.service (display-manager)
```

## Update and Maintenance Architecture

```
┌──────────────────────────────────────────┐
│     Security Updates (Automated)          │
│  • unattended-upgrades checks daily       │
│  • Downloads security patches             │
│  • Applies automatically (optional)       │
└──────────────────────────────────────────┘
                    ↓
┌──────────────────────────────────────────┐
│     Timeshift Snapshot (Pre-update)       │
│  • Creates system snapshot                │
│  • Enables rollback if needed             │
└──────────────────────────────────────────┘
                    ↓
┌──────────────────────────────────────────┐
│          Package Installation             │
│  • Verifies GPG signatures                │
│  • Extracts files                         │
│  • Runs maintainer scripts                │
└──────────────────────────────────────────┘
                    ↓
┌──────────────────────────────────────────┐
│       Post-Update Verification            │
│  • Service restarts                       │
│  • Kernel updates → reboot prompt         │
│  • Log review                             │
└──────────────────────────────────────────┘
```

## Performance Characteristics

### Memory Footprint
- Kernel: ~100MB
- systemd + core services: ~50MB
- SDDM: ~30MB
- KDE Plasma (idle): ~400MB
- **Total idle**: <600MB

### Storage Requirements
- Base system: ~5GB
- KDE Plasma: ~2GB
- Default applications: ~3GB
- **Total base install**: ~10GB

### Boot Performance
- UEFI → GRUB: ~2 seconds
- GRUB → Kernel init: ~3 seconds
- Kernel → systemd: ~5 seconds
- systemd → SDDM: ~10 seconds
- SDDM → Desktop: ~10 seconds
- **Total boot time**: ~30 seconds (SSD)

## Backup and Recovery

```
┌──────────────────────────────────────────┐
│      Timeshift (System Snapshots)         │
│  • Weekly automated snapshots             │
│  • Boot snapshots                         │
│  • GRUB integration for recovery          │
└──────────────────────────────────────────┘
                    ↓
┌──────────────────────────────────────────┐
│        User Data (Separate)               │
│  • /home excluded from system snapshots   │
│  • User responsible for data backup       │
└──────────────────────────────────────────┘
```

## Development and Build Infrastructure

```
Host System (Ubuntu/Debian)
         ↓
┌──────────────────────────────────────────┐
│    Build Environment                      │
│  • GCC 13.2 toolchain                     │
│  • Make, CMake, Meson                     │
│  • Git, wget, curl                        │
│  • ccache (build acceleration)            │
└──────────────────────────────────────────┘
         ↓
┌──────────────────────────────────────────┐
│     Component Compilation                 │
│  • Kernel → builds/kernel                 │
│  • glibc → builds/glibc                   │
│  • systemd → builds/systemd               │
│  • KDE → builds/kde                       │
└──────────────────────────────────────────┘
         ↓
┌──────────────────────────────────────────┐
│     Package Creation                      │
│  • dpkg-deb creates .deb packages         │
│  • GPG signing                            │
│  • Repository indexing                    │
└──────────────────────────────────────────┘
         ↓
┌──────────────────────────────────────────┐
│        ISO Generation                     │
│  • squashfs creation                      │
│  • GRUB bootloader integration            │
│  • Calamares installer                    │
└──────────────────────────────────────────┘
```

## Design Principles

1. **Security First**: Multiple security layers, encrypted by default
2. **Privacy Respect**: No telemetry, local backups only
3. **Reliability**: LTS components, tested updates, rollback capability
4. **Desktop Optimized**: Tuned for desktop use, good hardware support
5. **Transparency**: Open source, documented, reproducible builds
6. **Maintainability**: Modular architecture, clear separation of concerns
