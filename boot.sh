#!/bin/bash

# qemu-img create -f qcow2 mac_hdd.img 64G
# echo 1 > /sys/module/kvm/parameters/ignore_msrs
#
# Type the following after boot,
# -v "KernelBooter_kexts"="Yes" "CsrActiveConfig"="103"
#
# printf 'DE:AD:BE:EF:%02X:%02X\n' $((RANDOM%256)) $((RANDOM%256))
#
# no_floppy = 1 is required for OS X guests!
#
# Commit 473a49460db0a90bfda046b8f3662b49f94098eb (qemu) makes "no_floppy = 0"
# for pc-q35-2.3 hardware, and OS X doesn't like this (it hangs at "Waiting for
# DSMOS" message). Hence, we switch to pc-q35-2.4 hardware.
#
# Network device "-device e1000-82545em" can be replaced with "-device vmxnet3"
# for possibly better performance.
BACKING_DIR=/backing
SNAPSHOT_DIR=/snapshot
mkdir -p $BACKING_DIR $SNAPSHOT_DIR
[ ! -f $BACKING_DIR/mac_hdd.img ] && qemu-img create -f qcow2 -b $BACKING_DIR/mac_hdd-backing.img $SNAPSHOT_DIR/mac_hdd.img

exec qemu-system-x86_64 -enable-kvm -m 8192 -cpu core2duo,kvm=off \
	  -machine pc-q35-2.4 \
	  -smp 4,cores=2 \
	  -usb -device usb-kbd -device usb-tablet \
	  -device isa-applesmc,osk="ourhardworkbythesewordsguardedpleasedontsteal(c)AppleComputerInc" \
	  -kernel /usr/lib/qemu/enoch_rev2839_boot \
	  -smbios type=2 \
	  -device ide-drive,bus=ide.2,drive=MacHDD \
	  -drive id=MacHDD,if=none,file=$SNAPSHOT_DIR/mac_hdd.img \
      	  -netdev user,id=usr0 -device e1000-82545em,netdev=usr0,id=vnet0 \
	  -device ich9-intel-hda -device hda-duplex \
	  -display none -redir tcp:2222::22 -vnc 0.0.0.0:0
