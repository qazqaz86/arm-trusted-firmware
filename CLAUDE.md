# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Trusted Firmware-A (TF-A) provides a reference implementation of secure world software for Armv7-A and Armv8-A, including a Secure Monitor executing at Exception Level 3 (EL3). It implements various Arm interface standards, such as:

- Power State Coordination Interface (PSCI)
- Trusted Board Boot Requirements CLIENT (TBBR-CLIENT)
- SMC Calling Convention
- System Control and Management Interface (SCMI)
- Software Delegated Exception Interface (SDEI)

## Build System

**Prerequisites:**
- Set cross-compiler: `export CROSS_COMPILE=<path-to-aarch64-gcc>/bin/aarch64-none-elf-`

**Common Build Commands:**
```bash
# Build for FVP platform (default) with GCC
make PLAT=fvp all

# Build for QEMU virt platform with GCC
make PLAT=qemu all

# Build for FVP platform with Clang (recommended)
export CROSS_COMPILE=aarch64-none-elf-
make CC=clang PLAT=fvp E=0 all

# Debug build
make PLAT=fvp DEBUG=1 all

# Clean build artifacts
make PLAT=fvp clean

# Full clean (all platforms)
make realclean

# Build FIP (Firmware Image Package)
make PLAT=fvp fip

# Build fiptool
make PLAT=fvp fiptool

# Build documentation
make doc

# List all supported platforms
make help

# Run self-test script for QEMU build (verifies build artifacts)
./test_qemu_build.sh
```

**Build Options:**
- `PLAT=<platform>` - Target platform (required for most targets)
- `DEBUG=1` - Debug build
- `ARCH=aarch32` - Build for AArch32 (requires `AARCH32_SP=sp_min`)
- `CC=<compiler-path>` - Use clang or armclang instead of gcc
- `CROSS_COMPILE=<toolchain-prefix>` - Toolchain prefix
- `E=0` - Disable warnings as errors (useful for Clang builds)

**Build Output:**
- Products in `build/<platform>/<build-type>/`
- Key binaries: bl1.bin, bl2.bin, bl31.bin (AArch64), bl32.bin

## Boot Flow (AArch64)

TF-A implements a multi-stage boot flow:

1. **BL1** - AP Trusted ROM (EL3)
   - Minimal architectural initialization
   - Determines boot path (cold/warm boot)
   - Loads and verifies BL2

2. **BL2** - Trusted Boot Firmware
   - Loads and verifies subsequent firmware images
   - Supports dynamic configuration via device tree

3. **BL31** - EL3 Runtime Software
   - Implements PSCI (Power State Coordination Interface)
   - Manages interrupts and exceptions
   - Provides runtime services via SMC calls
   - Main entry point: `bl31_main()` in bl31/bl31_main.c

4. **BL32** - Secure-EL1 Payload (optional)
   - Trusted OS or Secure Partition Manager

5. **BL33** - Non-trusted Firmware
   - UEFI or other normal world firmware

## Key Directories

- `bl1/`, `bl2/`, `bl31/`, `bl32/` - Boot loader stage implementations
- `plat/` - Platform ports (100+ supported platforms including fvp, rpi4, juno, etc.)
- `include/` - Header files
- `lib/` - Libraries (xlat tables, cpus, el3_runtime, etc.)
- `drivers/` - Device drivers
- `services/` - Runtime services (std_svc, spd, etc.)
- `tools/` - fiptool, cert_create, sptool, etc.
- `docs/` - Sphinx documentation

## Important Conventions

- Export headers in `include/export/` must follow special rules (see include/export/README)
- All files must include SPDX-License-Identifier header
- Code uses BSD-3-Clause license
- Platform ports go in `plat/<vendor>/<platform>/`
- Runtime services register via `runtime_svc_init()`

## Common Development Tasks

**Adding a new platform:**
- Create directory structure in `plat/<vendor>/<platform>/`
- Implement platform porting interfaces
- Create platform.mk and platform_defaults.mk

**Adding a runtime service:**
- Register with `DECLARE_RT_SVC()` macro
- Implement SMC handler function

**Code style checking:**
```bash
# Check entire codebase
make checkcodebase

# Check patches against base commit
make checkpatch
```

## Testing with QEMU

**Prerequisites:**
- QEMU system emulator for AArch64: `qemu-system-aarch64`
- BL33 non-trusted firmware (e.g., UEFI from EDK II or Linux kernel)
- Device tree compiler (dtc) for full FIP support

**Quick Self-Test:**
```bash
# Run the self-test script to build and verify TF-A for QEMU
./test_qemu_build.sh
```
This script:
1. Cleans previous builds
2. Checks for cross-compiler dependencies
3. Builds TF-A for the `qemu` platform
4. Verifies all build artifacts (bl1.bin, bl2.bin, bl31.bin)

**Build artifacts for testing:**
After a successful build, the following binaries are available in `build/<platform>/release/`:
- `bl1.bin` - First stage bootloader
- `bl2.bin` - Second stage bootloader  
- `bl31.bin` - EL3 runtime firmware

**Build for QEMU platform:**
```bash
# Build specifically for QEMU virt platform
make PLAT=qemu all E=0
```

**To test with QEMU:**
Note: Full QEMU testing requires a FIP (Firmware Image Package) which combines all the bootloader stages with a non-trusted firmware (BL33). Building the FIP requires:
1. Device Tree Compiler (dtc)
2. OpenSSL development libraries (libssl-dev)
3. A BL33 image (e.g., UEFI or Linux kernel)

**Example QEMU command structure (for reference):**
```bash
# This is a reference - you will need to build a FIP first
qemu-system-aarch64 \
    -nographic \
    -machine virt \
    -cpu cortex-a57 \
    -bios build/qemu/release/bl1.bin \
    -device loader,file=build/qemu/release/bl2.bin,addr=0x40000000 \
    -device loader,file=build/qemu/release/bl31.bin,addr=0x40010000 \
    -device loader,file=<path-to-bl33.bin>,addr=0x40200000
```

For complete testing, refer to the TF-A documentation for building a FIP and running with QEMU.
