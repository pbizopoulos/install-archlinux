FROM archlinux:base-20220123.0.45312
RUN pacman -Syu --needed --noconfirm edk2-ovmf expect libisoburn qemu
