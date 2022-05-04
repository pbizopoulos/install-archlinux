FROM archlinux:base-20220501.0.54834
RUN echo 'Server = https://mirror.rackspace.com/archlinux/$repo/os/$arch' > /etc/pacman.d/mirrorlist
RUN pacman -Syu --needed --noconfirm edk2-ovmf expect libisoburn qemu
