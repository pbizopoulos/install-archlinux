.POSIX:

.PHONY: clean gui

debug_args_0=
debug_args_1=--interactive --tty
debug_args=$(debug_args_$(shell [ -t 0 ] && echo 1))

img=archlinux.img
kvm_args=--device /dev/kvm
tmpdir=tmp
workdir=/app

$(tmpdir)/$(img): Dockerfile Makefile in-device.sh in-qemu.sh
	mkdir -p $(tmpdir)/
	docker build --tag install-archlinux .
	docker container run \
		$(debug_args) \
		$(kvm_args) \
		--env IMG=$(img) \
		--env TMPDIR=$(tmpdir) \
		--rm \
		--user `id -u`:`id -g` \
		--volume `pwd`:$(workdir) \
		--workdir $(workdir) \
		install-archlinux ./in-qemu.sh

gui: $(tmpdir)/$(img)
	xhost +local:$(USER)
	docker container run \
		$(debug_args) \
		$(kvm_args) \
		--env DISPLAY \
		--rm \
		--user `id -u`:`id -g` \
		--volume /tmp/.X11-unix:/tmp/.X11-unix:ro \
		--volume `pwd`:$(workdir) \
		--workdir $(workdir) \
		install-archlinux qemu-system-x86_64 -m 4G -machine accel=kvm:tcg -net nic -net user -drive file=$(tmpdir)/$(img),format=raw,if=virtio -drive if=pflash,readonly=on,file=/usr/share/ovmf/x64/OVMF.fd -audiodev pa,id=snd0 -device ich9-intel-hda -device hda-output,audiodev=snd0
	xhost -local:$(USER)

clean:
	rm -rf $(tmpdir)/
