#!/bin/bash
# Self-test script to build TF-A for QEMU and run basic tests

set -e

# Directory setup
TF_A_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${TF_A_DIR}/build/qemu/release"
LOG_FILE="${TF_A_DIR}/build_test.log"

echo "========================================="
echo "TF-A QEMU Build and Test Script"
echo "========================================="

# Clean up previous builds
echo -e "\n[1/4] Cleaning previous build..."
make -C "${TF_A_DIR}" PLAT=qemu clean 2>/dev/null || true
rm -f "${LOG_FILE}"

# Check for cross-compiler
echo -e "\n[2/4] Checking build dependencies..."
if command -v aarch64-linux-gnu-gcc &> /dev/null; then
    echo "  ✓ Found aarch64-linux-gnu-gcc"
    export CROSS_COMPILE=aarch64-linux-gnu-
elif command -v aarch64-none-elf-gcc &> /dev/null; then
    echo "  ✓ Found aarch64-none-elf-gcc"
    export CROSS_COMPILE=aarch64-none-elf-
else
    echo "  ✗ No AArch64 cross-compiler found"
    echo "  Please install: gcc-aarch64-linux-gnu"
    exit 1
fi

# Build TF-A for QEMU
echo -e "\n[3/4] Building TF-A for QEMU platform..."
echo "  Build log: ${LOG_FILE}"
cd "${TF_A_DIR}"

if make PLAT=qemu all E=0 V=1 2>&1 | tee "${LOG_FILE}"; then
    echo -e "\n  ✓ Build successful!"
else
    echo -e "\n  ✗ Build failed!"
    echo "  Check ${LOG_FILE} for details"
    exit 1
fi

# Verify build artifacts
echo -e "\n[4/4] Verifying build artifacts..."
cd "${TF_A_DIR}"

ARTIFACTS=(
    "bl1.bin"
    "bl2.bin"
    "bl31.bin"
)

MISSING=0
for artifact in "${ARTIFACTS[@]}"; do
    if [ -f "${BUILD_DIR}/${artifact}" ]; then
        echo "  ✓ Found ${artifact}"
        ls -lh "${BUILD_DIR}/${artifact}"
    else
        echo "  ✗ Missing ${artifact}"
        MISSING=1
    fi
done

if [ "${MISSING}" -eq 0 ]; then
    echo -e "\n========================================="
    echo "✅ All build artifacts verified!"
    echo "========================================="
    echo ""
    echo "Build directory: ${BUILD_DIR}"
    echo "To run in QEMU, you will need a BL33 image (e.g., UEFI or Linux kernel)"
    echo ""
    echo "Example QEMU command (requires BL33):"
    echo "  qemu-system-aarch64 -nographic -machine virt -cpu cortex-a57 \\"
    echo "      -bios ${BUILD_DIR}/bl1.bin \\"
    echo "      -device loader,file=${BUILD_DIR}/bl2.bin,addr=0x40000000 \\"
    echo "      -device loader,file=${BUILD_DIR}/bl31.bin,addr=0x40010000 \\"
    echo "      -device loader,file=<path-to-bl33.bin>,addr=0x40200000"
    echo ""
    exit 0
else
    echo -e "\n========================================="
    echo "❌ Build verification failed!"
    echo "========================================="
    exit 1
fi
