FROM archlinux:base-20220206.0.46909
RUN rm -r /etc/pacman.d/gnupg/
RUN pacman-key --init
RUN pacman-key --populate archlinux
RUN pacman -Sc
RUN pacman -Syu --needed --noconfirm edk2-ovmf expect libisoburn qemu
