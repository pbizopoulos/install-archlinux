FROM archlinux:base-20220522.0.57327
RUN echo 'Server = https://mirror.rackspace.com/archlinux/$repo/os/$arch' > /etc/pacman.d/mirrorlist
RUN pacman -Syu --needed --noconfirm edk2-ovmf expect libisoburn qemu
