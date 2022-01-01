FROM archlinux:base-20211226.0.42348
RUN pacman -Syu --needed --noconfirm edk2-ovmf expect libisoburn qemu
