#!/bin/bash
make PLAT=qemu clean
#make PLAT=qemu  BL32=../qemu_boot/tos.bin BL32_EXTRA1=../qemu_boot/tee-pageable_v2.bin BL32_EXTRA2=../qemu_boot/tee-pageable_v2.bin  BL33=../qemu_boot/QEMU_EFI.fd QEMU_USE_GIC_DRIVER=QEMU_GICV3  DEBUG=1 SPD=opteed all fip

make PLAT=qemu \
    BL32=../qemu_boot/tos.bin   BL32_EXTRA1=../qemu_boot/tee-pager_v2.bin BL32_EXTRA2=../qemu_boot/tee-pageable_v2.bin \
    BL33=../qemu_boot/QEMU_EFI.fd BL33_EDK2_UEFI_ENTRY_OFFSET=0x2000 \
    QEMU_USE_GIC_DRIVER=QEMU_GICV3  DEBUG=1 SPD=opteed all fip


cp build/qemu/debug/qemu_fw.bios ../qemu_boot/

cd ../qemu_boot/
#qemu-system-aarch64 -nographic -machine virt,secure=on,gic-version=3 -cpu cortex-a57  -kernel Image  -append 'console=ttyAMA0,38400 keep_bootcon'   -initrd rootfs.cpio.gz -smp 2 -m 1024 -bios  qemu_fw.bios  -serial mon:stdio  -d unimp,guest_errors,in_asm   -D ./qemu.log -trace pflash_*

qemu-system-aarch64 -nographic -machine virt,secure=on,gic-version=3 -cpu cortex-a57  \
    -kernel Image  -append 'console=ttyAMA0,38400 keep_bootcon'   -initrd rootfs.cpio.gz \
    -smp 2 -m 2048 -bios  qemu_fw.bios  -serial mon:stdio   -serial file:uart1.log \
    -d unimp,guest_errors,in_asm   -D ./qemu.log -trace pflash_* \
    -S -gdb tcp:0.0.0.0:1235 

cd -