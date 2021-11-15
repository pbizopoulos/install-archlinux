FROM archlinux:base-20211024.0.37588
RUN pacman -Syu --needed --noconfirm edk2-ovmf expect libisoburn qemu
