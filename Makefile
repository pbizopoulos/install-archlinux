.POSIX:

.PHONY: clean gui

artifacts_dir=artifacts
container_engine=docker # For podman first execute $(printf 'unqualified-search-registries=["docker.io"]\n' > /etc/containers/registries.conf.d/docker.conf)
debug_args=$$(test -t 0 && printf '%s' '--interactive --tty')
image_file_name=archlinux.img
kvm_args=--device /dev/kvm
user_arg=$$(test $(container_engine) = 'docker' && printf '%s' "--user $$(id -u):$$(id -g)")
work_dir=/work

$(artifacts_dir)/$(image_file_name): Dockerfile Makefile in-device.sh in-qemu.sh ## Build image.
	mkdir -p $(artifacts_dir)/
	$(container_engine) build --tag install-archlinux .
	$(container_engine) container run \
		$(debug_args) \
		$(kvm_args) \
		$(user_arg) \
		--env IMG=$(image_file_name) \
		--env ARTIFACTSDIR=$(artifacts_dir) \
		--rm \
		--volume $$(pwd):$(work_dir)/ \
		--workdir $(work_dir) \
		install-archlinux ./in-qemu.sh

gui: $(artifacts_dir)/$(image_file_name) ## Run image in QEMU.
	xhost +local:$(USER)
	$(container_engine) container run \
		$(debug_args) \
		$(kvm_args) \
		$(user_arg) \
		--env DISPLAY \
		--rm \
		--volume /tmp/.X11-unix:/tmp/.X11-unix:ro \
		--volume $$(pwd):$(work_dir)/ \
		--workdir $(work_dir) \
		install-archlinux qemu-system-x86_64 -m 4G -machine accel=kvm:tcg -net nic -net user -drive file=$(artifacts_dir)/$(image_file_name),format=raw,if=virtio -drive if=pflash,readonly=on,file=/usr/share/ovmf/x64/OVMF.fd -audiodev pa,id=snd0 -device ich9-intel-hda -device hda-output,audiodev=snd0
	xhost -local:$(USER)

clean: ## Remove $(artifacts_dir) directory.
	rm -rf $(artifacts_dir)/

help: ## Show all commands.
	@sed 's/\$$(artifacts_dir)/$(artifacts_dir)/g; s/\$$(codefile)/$(codefile)/g' $(MAKEFILE_LIST) | grep '##' | grep -v grep | awk 'BEGIN {FS = ":.* ## "}; {printf "%-30s# %s\n", $$1, $$2}'
