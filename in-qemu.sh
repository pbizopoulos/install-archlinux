#!/bin/bash
set -e

mkdir -p "${TMPDIR}"
cd "${TMPDIR}"
ISO="$(curl -fs "https://mirror.pkgbuild.com/iso/latest/" | grep -Eo 'archlinux-[0-9]{4}\.[0-9]{2}\.[0-9]{2}-x86_64.iso' | head -n 1)"
if [ ! -f "${ISO}" ]; then
	rm -f archlinux-*.iso "${IMG}"
	curl -o "${ISO}" "https://mirror.pkgbuild.com/iso/latest/${ISO}"
fi
xorriso -osirrox on -indev "${ISO}" -extract arch/boot/x86_64 .
ISO_VOLUME_ID="$(xorriso -indev "${ISO}" |& awk -F : '$1 ~ "Volume id" {print $2}' | tr -d "' ")"
fallocate -l 8G "${IMG}"
expect << EOF
set timeout -1
spawn qemu-system-x86_64 -m 4G -machine accel=kvm:tcg -net nic -net user -drive file=${IMG},format=raw,if=virtio -cdrom "${ISO}" -kernel vmlinuz-linux -initrd initramfs-linux.img -append "archisolabel=${ISO_VOLUME_ID} console=ttyS0" -nographic
expect "archiso login: "
send "root\n"
expect "# "
send "curl -L github.com/pbizopoulos/install-archlinux/raw/master/in-device.sh | sed 's/wlan0/ens3/g' | bash -s /dev/vda\n"
expect "Finished."
send "shutdown now\n"
expect "# "
send "shutdown now\n"
EOF
