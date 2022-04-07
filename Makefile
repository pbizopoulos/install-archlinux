.POSIX:

container_engine=docker
# For podman first execute `printf 'unqualified-search-registries=["docker.io"]\n' > /etc/containers/registries.conf.d/docker.conf`
artifactsdir=artifacts
workdir=/app

.PHONY: clean gui

debug_args=$(shell [ -t 0 ] && printf '%s' '--interactive --tty')
img=archlinux.img
kvm_args=--device /dev/kvm
user_arg=$(shell [ $(container_engine) = 'docker' ] && printf '%s' '--user `id -u`:`id -g`')

$(artifactsdir)/$(img): Dockerfile Makefile in-device.sh in-qemu.sh ##	Build image.
	mkdir -p $(artifactsdir)/
	$(container_engine) build --tag install-archlinux .
	$(container_engine) container run \
		$(debug_args) \
		$(kvm_args) \
		$(user_arg) \
		--env IMG=$(img) \
		--env ARTIFACTSDIR=$(artifactsdir) \
		--rm \
		--volume `pwd`:$(workdir) \
		--workdir $(workdir) \
		install-archlinux ./in-qemu.sh

gui: $(artifactsdir)/$(img) ##				Run image in QEMU.
	xhost +local:$(USER)
	$(container_engine) container run \
		$(debug_args) \
		$(kvm_args) \
		$(user_arg) \
		--env DISPLAY \
		--rm \
		--volume /tmp/.X11-unix:/tmp/.X11-unix:ro \
		--volume `pwd`:$(workdir) \
		--workdir $(workdir) \
		install-archlinux qemu-system-x86_64 -m 4G -machine accel=kvm:tcg -net nic -net user -drive file=$(artifactsdir)/$(img),format=raw,if=virtio -drive if=pflash,readonly=on,file=/usr/share/ovmf/x64/OVMF.fd -audiodev pa,id=snd0 -device ich9-intel-hda -device hda-output,audiodev=snd0
	xhost -local:$(USER)

clean: ## 			Remove artifacts/ directory.
	rm -rf $(artifactsdir)/

help: ## 				Show all commands.
	@grep '##' $(MAKEFILE_LIST) | sed 's/\(\:.*\#\#\)/\:\ /' | sed 's/\$$(artifactsdir)/$(artifactsdir)/' | sed 's/\$$(img)/$(img)/' | grep -v grep
