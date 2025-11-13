#!/bin/bash
# Phase 1: Environment Preparation Script
# This script sets up the development environment for building the custom Linux distribution

set -e  # Exit on error
set -u  # Exit on undefined variable

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SOURCES_DIR="${PROJECT_ROOT}/sources"
BUILDS_DIR="${PROJECT_ROOT}/builds"

echo -e "${GREEN}=== Custom Linux Distribution - Environment Setup ===${NC}"
echo "Project root: ${PROJECT_ROOT}"

# Check if running on Linux
if [[ "$(uname -s)" != "Linux" ]]; then
    echo -e "${RED}Error: This script must be run on a Linux system${NC}"
    echo "Please use Ubuntu 22.04 LTS, Debian 12, or similar"
    exit 1
fi

# Check available disk space (minimum 200GB)
available_space=$(df -BG "${PROJECT_ROOT}" | awk 'NR==2 {print $4}' | sed 's/G//')
if [[ ${available_space} -lt 200 ]]; then
    echo -e "${YELLOW}Warning: Less than 200GB available. You have ${available_space}GB${NC}"
    echo -e "${YELLOW}This may not be sufficient for the entire build process${NC}"
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Detect distribution
if [ -f /etc/os-release ]; then
    . /etc/os-release
    echo "Detected OS: ${NAME} ${VERSION}"
else
    echo -e "${RED}Cannot detect Linux distribution${NC}"
    exit 1
fi

# Install build dependencies based on distribution
echo -e "${GREEN}Installing build dependencies...${NC}"

if [[ "${ID}" == "ubuntu" ]] || [[ "${ID}" == "debian" ]]; then
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
        unzip \
        tar \
        gzip \
        bzip2 \
        ccache \
        ninja-build \
        cmake \
        meson
        
elif [[ "${ID}" == "fedora" ]] || [[ "${ID}" == "rhel" ]] || [[ "${ID}" == "centos" ]]; then
    sudo dnf groupinstall -y "Development Tools"
    sudo dnf install -y \
        gcc gcc-c++ make \
        binutils \
        bison flex \
        gawk \
        texinfo \
        git \
        wget curl \
        patch \
        bc \
        openssl-devel \
        elfutils-libelf-devel \
        ncurses-devel \
        pkgconfig \
        autoconf automake libtool \
        gettext \
        python3 python3-pip \
        rsync \
        xz \
        cpio \
        unzip \
        tar \
        gzip \
        bzip2 \
        ccache \
        ninja-build \
        cmake \
        meson
        
elif [[ "${ID}" == "arch" ]] || [[ "${ID}" == "manjaro" ]]; then
    sudo pacman -Syu --noconfirm \
        base-devel \
        gcc \
        binutils \
        bison flex \
        gawk \
        texinfo \
        git \
        wget curl \
        patch \
        bc \
        openssl \
        libelf \
        ncurses \
        pkgconf \
        autoconf automake libtool \
        gettext \
        python python-pip \
        rsync \
        xz \
        cpio \
        unzip \
        tar \
        gzip \
        bzip2 \
        ccache \
        ninja \
        cmake \
        meson
else
    echo -e "${YELLOW}Unsupported distribution. Please install dependencies manually.${NC}"
fi

# Verify critical tools
echo -e "${GREEN}Verifying installed tools...${NC}"
tools=("gcc" "g++" "make" "git" "wget" "curl" "patch" "bison" "flex" "bc" "python3")
missing_tools=()

for tool in "${tools[@]}"; do
    if ! command -v "${tool}" &> /dev/null; then
        missing_tools+=("${tool}")
    else
        echo "  ✓ ${tool}: $(command -v ${tool})"
    fi
done

if [[ ${#missing_tools[@]} -gt 0 ]]; then
    echo -e "${RED}Missing tools: ${missing_tools[*]}${NC}"
    exit 1
fi

# Check GCC version (minimum 9.0)
gcc_version=$(gcc -dumpversion | cut -d. -f1)
if [[ ${gcc_version} -lt 9 ]]; then
    echo -e "${RED}GCC version ${gcc_version} is too old. Minimum required: 9.0${NC}"
    exit 1
fi
echo -e "${GREEN}GCC version: $(gcc --version | head -n1)${NC}"

# Set up ccache to speed up recompilation
echo -e "${GREEN}Configuring ccache...${NC}"
ccache --max-size=20G
ccache --set-config=cache_dir="${PROJECT_ROOT}/.ccache"
export PATH="/usr/lib/ccache:${PATH}"

# Create version tracking file
echo -e "${GREEN}Creating version tracking file...${NC}"
cat > "${PROJECT_ROOT}/versions.txt" << EOF
# Component Versions
# Generated: $(date)

KERNEL_VERSION=6.6
GLIBC_VERSION=2.38
GCC_VERSION=13.2
SYSTEMD_VERSION=254
GRUB_VERSION=2.06
KDE_PLASMA_VERSION=5.27
QT_VERSION=5.15
DPKG_VERSION=1.21.22
APT_VERSION=2.6.1

# Build information
BUILD_HOST=$(hostname)
BUILD_DATE=$(date +%Y-%m-%d)
BUILD_ARCH=$(uname -m)
EOF

echo -e "${GREEN}Version tracking file created: versions.txt${NC}"

# Create download script template
cat > "${SOURCES_DIR}/download-sources.sh" << 'EOF'
#!/bin/bash
# Script to download all source components
set -e

KERNEL_VERSION="6.6"
GLIBC_VERSION="2.38"
GCC_VERSION="13.2"

echo "Downloading source packages..."

# Kernel
if [ ! -f "kernel/linux-${KERNEL_VERSION}.tar.xz" ]; then
    echo "Downloading Linux kernel ${KERNEL_VERSION}..."
    mkdir -p kernel
    wget -P kernel/ "https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-${KERNEL_VERSION}.tar.xz"
fi

# glibc
if [ ! -f "toolchain/glibc-${GLIBC_VERSION}.tar.xz" ]; then
    echo "Downloading glibc ${GLIBC_VERSION}..."
    mkdir -p toolchain
    wget -P toolchain/ "https://ftp.gnu.org/gnu/glibc/glibc-${GLIBC_VERSION}.tar.xz"
fi

# GCC
if [ ! -f "toolchain/gcc-${GCC_VERSION}.tar.xz" ]; then
    echo "Downloading GCC ${GCC_VERSION}..."
    wget -P toolchain/ "https://ftp.gnu.org/gnu/gcc/gcc-${GCC_VERSION}/gcc-${GCC_VERSION}.tar.xz"
fi

echo "All sources downloaded successfully!"
EOF

chmod +x "${SOURCES_DIR}/download-sources.sh"

echo ""
echo -e "${GREEN}=== Environment Setup Complete ===${NC}"
echo ""
echo "Next steps:"
echo "  1. Review the versions in: versions.txt"
echo "  2. Download sources: cd sources && ./download-sources.sh"
echo "  3. Proceed to Phase 2: Kernel Compilation"
echo ""
echo "Project structure ready at: ${PROJECT_ROOT}"
