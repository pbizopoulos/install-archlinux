.POSIX:

container_engine=docker
# For podman first execute `echo 'unqualified-search-registries=["docker.io"]' > /etc/containers/registries.conf.d/docker.conf`
tmpdir=tmp
workdir=/app

.PHONY: clean gui

debug_args=$(shell [ -t 0 ] && echo --interactive --tty)

user_arg_podman=
user_arg_docker=--user `id -u`:`id -g`
user_arg=$(user_arg_$(container_engine))

img=archlinux.img
kvm_args=--device /dev/kvm

$(tmpdir)/$(img): Dockerfile Makefile in-device.sh in-qemu.sh
	mkdir -p $(tmpdir)/
	podman build --tag install-archlinux .
	podman container run \
		$(debug_args) \
		$(kvm_args) \
		$(user_arg) \
		--env IMG=$(img) \
		--env TMPDIR=$(tmpdir) \
		--rm \
		--volume `pwd`:$(workdir) \
		--workdir $(workdir) \
		install-archlinux ./in-qemu.sh

gui: $(tmpdir)/$(img)
	xhost +local:$(USER)
	podman container run \
		$(debug_args) \
		$(kvm_args) \
		$(user_arg) \
		--env DISPLAY \
		--rm \
		--volume /tmp/.X11-unix:/tmp/.X11-unix:ro \
		--volume `pwd`:$(workdir) \
		--workdir $(workdir) \
		install-archlinux qemu-system-x86_64 -m 4G -machine accel=kvm:tcg -net nic -net user -drive file=$(tmpdir)/$(img),format=raw,if=virtio -drive if=pflash,readonly=on,file=/usr/share/ovmf/x64/OVMF.fd -audiodev pa,id=snd0 -device ich9-intel-hda -device hda-output,audiodev=snd0
	xhost -local:$(USER)

clean:
	rm -rf $(tmpdir)/
