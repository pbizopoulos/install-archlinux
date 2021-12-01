FROM archlinux:base-20211121.0.39613
RUN pacman -Syu --needed --noconfirm edk2-ovmf expect libisoburn qemu
