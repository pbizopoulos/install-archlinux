#!/bin/bash
set -o errexit

ISO="$(curl -fs "https://mirror.pkgbuild.com/iso/latest/" | grep -Eo 'archlinux-[0-9]{4}\.[0-9]{2}\.[0-9]{2}-x86_64.iso' | head -n 1)"
if [ ! -f "${TMPDIR}/${ISO}" ]; then
	rm -f "${TMPDIR}/archlinux-*.iso" "${TMPDIR}/${IMG}"
	curl -o "${TMPDIR}/${ISO}" "https://mirror.pkgbuild.com/iso/latest/${ISO}"
fi
xorriso -osirrox on -indev "${TMPDIR}/${ISO}" -extract arch/boot/x86_64 "${TMPDIR}"
ISO_VOLUME_ID="$(xorriso -indev "${TMPDIR}/${ISO}" |& awk -F : '$1 ~ "Volume id" {print $2}' | tr -d "' ")"
fallocate -l 8G "${TMPDIR}/${IMG}"
expect << EOF
set timeout -1
spawn qemu-system-x86_64 -m 4G -machine accel=kvm:tcg -net nic -net user -drive file=${TMPDIR}/${IMG},format=raw,if=virtio -cdrom "${TMPDIR}/${ISO}" -kernel "${TMPDIR}/vmlinuz-linux" -initrd "${TMPDIR}/initramfs-linux.img" -append "archisolabel=${ISO_VOLUME_ID} console=ttyS0" -nographic
expect "archiso login: "
send "root\n"
expect "# "
send "until systemctl is-active pacman-init; do sleep 1; done\n"
expect "# "
send "curl -L github.com/pbizopoulos/install-archlinux/raw/master/in-device.sh | sed 's/wlan0/ens3/g' | bash -s /dev/vda\n"
expect "Finished."
send "shutdown now\n"
expect "# "
send "shutdown now\n"
EOF
