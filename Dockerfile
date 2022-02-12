FROM archlinux:base-20220206.0.46909
RUN pacman -Syu --needed --noconfirm edk2-ovmf expect libisoburn qemu
