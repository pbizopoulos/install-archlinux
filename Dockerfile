FROM archlinux:base-20220626.0.64095
RUN echo 'Server = https://mirror.rackspace.com/archlinux/$repo/os/$arch' > /etc/pacman.d/mirrorlist
RUN pacman -Syu --needed --noconfirm edk2-ovmf expect libisoburn qemu
