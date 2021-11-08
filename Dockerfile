FROM archlinux
RUN pacman -Syu --needed --noconfirm edk2-ovmf expect libisoburn qemu
