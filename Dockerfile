FROM archlinux:base-20220220.0.48372
RUN printf 'Server = https://mirror.rackspace.com/archlinux/$repo/os/$arch' > /etc/pacman.d/mirrorlist
RUN pacman -Syu --needed --noconfirm edk2-ovmf expect libisoburn qemu
