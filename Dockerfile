FROM archlinux:base-20220220.0.48372
RUN pacman -Syu --needed --noconfirm edk2-ovmf expect libisoburn qemu
