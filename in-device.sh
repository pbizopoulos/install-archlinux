#!/bin/bash
set -eu

root_password="password"
user="pbizopoulos"
user_password="password"
timedatectl set-ntp true
wipefs -a -f "${1}"
echo -e "g\nn\n\n\n+512M\nt\n1\nn\n\n\n\nw\n" | fdisk "${1}"
yes | mkfs.ext4 "${1}"2
mount "${1}"2 /mnt
yes | mkfs.fat -F32 "${1}"1
mkdir -p /mnt/boot/
mount "${1}"1 /mnt/boot
reflector --latest 5 --sort rate --protocol https --save /etc/pacman.d/mirrorlist
pacstrap /mnt base base-devel broadcom-wl chromium docker git intel-ucode iwd linux-firmware man-db man-pages openssh pulseaudio slock vim xorg-server xorg-xinit xorg-xinput
genfstab -U /mnt > /mnt/etc/fstab

arch-chroot /mnt << EOF
ln -sf /usr/share/zoneinfo/Europe/Athens /etc/localtime
hwclock --systohc
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
echo "el_GR.UTF-8 UTF-8" >> /etc/locale.gen
echo "LANG=en_US.UTF-8" >> /etc/locale.conf
locale-gen
echo "archlinux" > /etc/hostname
echo root:${root_password} | chpasswd
useradd -m -G docker,wheel ${user}
echo ${user}:${user_password} | chpasswd
bootctl install
mkdir -p /boot/loader/
echo 'default arch.conf' > /boot/loader/loader.conf

mkdir -p /boot/loader/entries/

cat << END > /boot/loader/entries/arch.conf
title Arch Linux
linux /vmlinuz-linux
initrd /intel-ucode.img
initrd /initramfs-linux.img
options root=PARTUUID=$(blkid -s PARTUUID -o value "${1}"2) rw
END

cat << END > /etc/systemd/network/25-wireless.network
[Match]
Name=wlan0

[Network]
DHCP=ipv4
END

echo '%wheel ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers
systemctl enable iwd systemd-networkd systemd-resolved
cd /tmp/ && git clone https://github.com/pbizopoulos/fswm && cd fswm/ && make install

su ${user}

cd /tmp/ && git clone https://aur.archlinux.org/st.git && cd st/ && makepkg && curl -L https://st.suckless.org/patches/solarized/st-solarized-light-0.8.5.diff | git apply && cp config.def.h config.h && makepkg --noconfirm -sif
sed -i '$s/NOPASSWD: //' /etc/sudoers

cat << END > /home/${user}/.xinitrc
setxkbmap -layout us,gr -option grp:win_space_toggle
fswm st -f "Source Code Pro:pixelsize=60:style=bold"
END

cat << END > /home/${user}/.gitconfig
[user]
email = pbizopoulos@protonmail.com
name = Paschalis Bizopoulos
END

echo "export GDK_SCALE=4" >> /home/${user}/.bashrc
echo "filetype plugin indent on" > /home/${user}/.vimrc

cat << END > /home/${user}/post.txt
Chromium
1. Install Vimium
2. Install uBlock Origin

GitHub
1. ssh-keygen -t ed25519 -C "pbizopoulos@protonmail.com"
2. eval "$(ssh-agent -s)"
3. ssh-add /home/${user}/.ssh/id_ed25519
4. Copy contents of /home/${user}/.ssh/id_ed25519.pub to GitHub SSH settings.

Pulseaudio
1. pactl set-sink-volume 0 100%
2. pactl set-sink-mute 0 0
END

EOF

echo "Finished."
umount -R /mnt
