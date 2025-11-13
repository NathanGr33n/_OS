# Phase 8: Desktop Environment (KDE Plasma)

## Overview
Build and configure KDE Plasma desktop with custom theming and default applications.

## Components
- **KDE Plasma 5.27 LTS** - Desktop environment
- **Qt 5.15 LTS** - GUI framework
- **SDDM** - Display manager
- **Default applications** - Firefox, OnlyOffice, Dolphin, etc.

## Qt Framework Build

### Download Qt 5.15 LTS
```bash
cd sources/kde
wget https://download.qt.io/official_releases/qt/5.15/5.15.12/single/qt-everywhere-opensource-src-5.15.12.tar.xz
tar -xf qt-everywhere-opensource-src-5.15.12.tar.xz
cd qt-everywhere-src-5.15.12
```

### Build Qt
```bash
./configure \
    -prefix /usr \
    -sysconfdir /etc/xdg \
    -opensource \
    -confirm-license \
    -nomake examples \
    -nomake tests \
    -system-sqlite \
    -openssl-linked \
    -dbus-linked \
    -qt-pcre \
    -skip qtwebengine

make -j$(nproc)  # Takes 2-4 hours
make install DESTDIR="${PROJECT_ROOT}/builds/qt5"
```

## KDE Plasma Build

### KDE Frameworks

Build order for KDE Frameworks 5:

1. **Extra CMake Modules**
2. **Core frameworks** (ki18n, kconfig, kcoreaddons)
3. **Tier 2 frameworks** (kauth, kcrash, kdoctools)
4. **Tier 3 frameworks** (kio, kparts, kservice)

```bash
cd sources/kde
git clone --depth 1 --branch v5.27.0 https://invent.kde.org/frameworks/extra-cmake-modules.git
cd extra-cmake-modules

mkdir build && cd build
cmake .. -DCMAKE_INSTALL_PREFIX=/usr
make -j$(nproc)
make install DESTDIR="${PROJECT_ROOT}/builds/kde-frameworks"
```

### KDE Plasma Desktop

```bash
cd sources/kde
git clone --depth 1 --branch v5.27.0 https://invent.kde.org/plasma/plasma-desktop.git
cd plasma-desktop

mkdir build && cd build
cmake .. \
    -DCMAKE_INSTALL_PREFIX=/usr \
    -DCMAKE_BUILD_TYPE=Release \
    -DKDE_INSTALL_LIBDIR=lib \
    -DBUILD_TESTING=OFF

make -j$(nproc)
make install DESTDIR="${PROJECT_ROOT}/builds/plasma-desktop"
```

### SDDM (Display Manager)

```bash
cd sources/kde
git clone --depth 1 https://github.com/sddm/sddm.git
cd sddm

mkdir build && cd build
cmake .. \
    -DCMAKE_INSTALL_PREFIX=/usr \
    -DCMAKE_BUILD_TYPE=Release \
    -DENABLE_JOURNALD=ON \
    -DNO_SYSTEMD=OFF

make -j$(nproc)
make install DESTDIR="${PROJECT_ROOT}/builds/sddm"
```

### SDDM Configuration

Create `configs/sddm/sddm.conf`:

```ini
[Autologin]
Relogin=false
Session=
User=

[General]
HaltCommand=/usr/bin/systemctl poweroff
RebootCommand=/usr/bin/systemctl reboot
Numlock=on

[Theme]
Current=custom-theme
CursorTheme=breeze_cursors
Font=Noto Sans,10,-1,5,50,0,0,0,0,0
ThemeDir=/usr/share/sddm/themes

[Users]
MaximumUid=60000
MinimumUid=1000
HideUsers=
HideShells=
```

## Default Applications

### Application List

1. **Firefox ESR** - Web browser
2. **OnlyOffice** - Office suite
3. **Dolphin** - File manager (included with KDE)
4. **Haruna** - Video player
5. **Sublime Text** - Code editor
6. **Thunderbird** - Email client
7. **Telegram Desktop** - Messaging
8. **Stacer** - System optimizer
9. **Konsole** - Terminal (included with KDE)
10. **Spectacle** - Screenshot tool (included with KDE)

### Firefox ESR

```bash
cd sources/apps
wget https://ftp.mozilla.org/pub/firefox/releases/115.6.0esr/source/firefox-115.6.0esr.source.tar.xz
tar -xf firefox-115.6.0esr.source.tar.xz
cd firefox-115.6.0esr

# Create mozconfig
cat > mozconfig << 'EOF'
ac_add_options --enable-application=browser
ac_add_options --prefix=/usr
ac_add_options --enable-release
ac_add_options --enable-hardening
ac_add_options --enable-optimize
ac_add_options --disable-debug
ac_add_options --enable-official-branding
ac_add_options --with-system-zlib
ac_add_options --with-system-bz2
EOF

./mach build
./mach install DESTDIR="${PROJECT_ROOT}/builds/firefox"
```

### Haruna Video Player

```bash
cd sources/apps
git clone --depth 1 https://github.com/g-fb/haruna.git
cd haruna

mkdir build && cd build
cmake .. -DCMAKE_INSTALL_PREFIX=/usr
make -j$(nproc)
make install DESTDIR="${PROJECT_ROOT}/builds/haruna"
```

### Stacer System Optimizer

```bash
cd sources/apps
git clone --depth 1 https://github.com/oguzhaninan/Stacer.git
cd Stacer

mkdir build && cd build
cmake .. -DCMAKE_INSTALL_PREFIX=/usr
make -j$(nproc)
make install DESTDIR="${PROJECT_ROOT}/builds/stacer"
```

## Custom KDE Theme

### Theme Structure

```
configs/kde/theme/
├── colors/
│   └── CustomColors
├── plasma/
│   └── desktoptheme/
│       └── custom/
├── icons/
│   └── custom-icons/
└── wallpapers/
    └── custom/
```

### Color Scheme

Create `configs/kde/theme/colors/CustomColors`:

```ini
[ColorEffects:Disabled]
Color=56,56,56
ColorAmount=0
ColorEffect=0
ContrastAmount=0.65
ContrastEffect=1
IntensityAmount=0.1
IntensityEffect=2

[ColorEffects:Inactive]
ChangeSelectionColor=true
Color=112,111,110
ColorAmount=0.025
ColorEffect=2
ContrastAmount=0.1
ContrastEffect=2
Enable=false
IntensityAmount=0
IntensityEffect=0

[Colors:Button]
BackgroundNormal=49,54,59
BackgroundAlternate=77,77,77
ForegroundNormal=239,240,241
ForegroundInactive=127,140,141
ForegroundActive=61,174,233
ForegroundLink=41,128,185
ForegroundVisited=127,140,141
ForegroundNegative=218,68,83
ForegroundNeutral=246,116,0
ForegroundPositive=39,174,96

[Colors:Window]
BackgroundNormal=35,38,41
BackgroundAlternate=49,54,59
ForegroundNormal=239,240,241
ForegroundInactive=127,140,141
ForegroundActive=61,174,233
ForegroundLink=41,128,185
ForegroundVisited=127,140,141
ForegroundNegative=218,68,83
ForegroundNeutral=246,116,0
ForegroundPositive=39,174,96
```

### Plasma Desktop Theme

Create `configs/kde/theme/plasma/desktoptheme/custom/metadata.desktop`:

```ini
[Desktop Entry]
Name=Custom Theme
Comment=Custom desktop theme for Custom Linux OS

X-KDE-PluginInfo-Name=custom
X-KDE-PluginInfo-Version=1.0
X-KDE-PluginInfo-Category=Plasma Theme
```

## Desktop Configuration

### Default Desktop Layout

Create `configs/kde/plasma-org.kde.plasma.desktop-appletsrc`:

```ini
[ActionPlugins][0]
RightButton;NoModifier=org.kde.contextmenu

[Containments][1]
activityId=
formFactor=0
immutability=1
lastScreen=0
location=0
plugin=org.kde.plasma.folder
wallpaperplugin=org.kde.image

[Containments][1][Wallpaper][org.kde.image][General]
Image=/usr/share/wallpapers/custom/default.jpg
SlidePaths=/usr/share/wallpapers

[Containments][2]
activityId=
formFactor=2
immutability=1
lastScreen=0
location=3
plugin=org.kde.panel

[Containments][2][Applets][3]
immutability=1
plugin=org.kde.plasma.kickoff

[Containments][2][Applets][4]
immutability=1
plugin=org.kde.plasma.pager

[Containments][2][Applets][5]
immutability=1
plugin=org.kde.plasma.systemtray

[Containments][2][Applets][6]
immutability=1
plugin=org.kde.plasma.digitalclock
```

### Application Shortcuts

Create `configs/kde/kglobalshortcutsrc`:

```ini
[kwin]
Expose=Ctrl+F9
ExposeAll=Ctrl+F10
ShowDesktopGrid=Ctrl+F8
Suspend Compositing=Alt+Shift+F12
Switch to Desktop 1=Ctrl+F1
Switch to Desktop 2=Ctrl+F2
Switch to Desktop 3=Ctrl+F3
Switch to Desktop 4=Ctrl+F4
Window Close=Alt+F4
Window Maximize=Meta+PgUp
Window Minimize=Meta+PgDown

[org.kde.dolphin.desktop]
_launch=Meta+E

[org.kde.konsole.desktop]
_launch=Meta+T

[org.kde.spectacle.desktop]
_launch=Print
```

## First-Run Wizard

Create custom first-run wizard script:

```bash
#!/bin/bash
# configs/kde/first-run-wizard.sh

# Display welcome message
kdialog --title "Welcome to Custom Linux OS" \
    --msgbox "Thank you for installing Custom Linux OS. This wizard will help you set up your system."

# Configure user preferences
# Timezone
TIMEZONE=$(kdialog --combobox "Select your timezone:" \
    "America/New_York" "Europe/London" "Asia/Tokyo" "UTC")

# Language
LANG=$(kdialog --combobox "Select your language:" \
    "en_US.UTF-8" "es_ES.UTF-8" "fr_FR.UTF-8" "de_DE.UTF-8")

# Apply settings
timedatectl set-timezone "$TIMEZONE"
localectl set-locale LANG="$LANG"

# Create default directories
xdg-user-dirs-update

kdialog --title "Setup Complete" \
    --msgbox "Your system is now configured. Enjoy Custom Linux OS!"
```

## Build Script

Create `scripts/build/07-build-kde.sh`:

```bash
#!/bin/bash
set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

echo "=== Building KDE Plasma Desktop ==="

# Note: This is a simplified version
# Full KDE build requires building 50+ components in correct order

echo "Building Qt5..."
cd "${PROJECT_ROOT}/sources/kde/qt-everywhere-src-5.15.12"
./configure -prefix /usr -opensource -confirm-license
make -j$(nproc)
make install DESTDIR="${PROJECT_ROOT}/builds/qt5"

echo "Building KDE Frameworks..."
# Build each framework in order

echo "Building Plasma Desktop..."
cd "${PROJECT_ROOT}/sources/kde/plasma-desktop/build"
cmake .. -DCMAKE_INSTALL_PREFIX=/usr
make -j$(nproc)
make install DESTDIR="${PROJECT_ROOT}/builds/plasma-desktop"

echo "Building SDDM..."
cd "${PROJECT_ROOT}/sources/kde/sddm/build"
cmake .. -DCMAKE_INSTALL_PREFIX=/usr
make -j$(nproc)
make install DESTDIR="${PROJECT_ROOT}/builds/sddm"

echo "KDE Plasma build complete"
```

## Accessibility Features

Enable accessibility by default:

- **Screen reader** (Orca)
- **High contrast themes**
- **Large text options**
- **Keyboard navigation**
- **Sticky keys, slow keys**

Configuration in `configs/kde/kaccessrc`.

## System Integration

### Enable SDDM service
```bash
systemctl enable sddm
systemctl set-default graphical.target
```

### Desktop session files
Create `/usr/share/xsessions/plasma.desktop`:

```ini
[Desktop Entry]
Type=XSession
Exec=/usr/bin/startplasma-x11
TryExec=/usr/bin/startplasma-x11
DesktopNames=KDE
Name=Plasma (X11)
Comment=Plasma by KDE
```

## Testing

Test KDE Plasma in VM:
```bash
# Start X server
startx /usr/bin/startplasma-x11

# Or with SDDM
systemctl start sddm
```

## Next Steps

Proceed to **Phase 9: Networking & Security**.

## References
- KDE Build Guide: https://community.kde.org/Get_Involved/development
- Qt Documentation: https://doc.qt.io/
- SDDM: https://github.com/sddm/sddm
