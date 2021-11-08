#!/bin/bash
set -e

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
pacstrap /mnt base base-devel broadcom-wl docker git intel-ucode iwd linux-firmware man-db man-pages mpv mutt newsboat pulseaudio qutebrowser slock vim xorg-server xorg-xinit xorg-xinput yt-dlp zathura-pdf-mupdf
genfstab -U /mnt >> /mnt/etc/fstab

arch-chroot /mnt << EOF
ln -sf /usr/share/zoneinfo/Europe/Athens /etc/localtime
hwclock --systohc
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
echo "el_GR.UTF-8 UTF-8" >> /etc/locale.gen
echo "LANG=en_US.UTF-8" >> /etc/locale.conf
locale-gen
echo "archlinux" > /etc/hostname
echo "root:$root_password" | chpasswd
useradd -m -G docker,wheel "$user"
echo "$user:$user_password" | chpasswd
bootctl install
mkdir -p /boot/loader/

cat << END > /boot/loader/loader.conf
default arch.conf
timeout 0
END

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

systemctl enable iwd
systemctl enable systemd-networkd
systemctl enable systemd-resolved

echo "set font 'monospace 55'" > /etc/zathurarc
git clone https://github.com/pbizopoulos/fswm && cd fswm && make install && cd .. && rm -rf fswm/

su "$user"

cd /tmp/ && git clone https://aur.archlinux.org/st.git && cd st && makepkg && curl -L https://st.suckless.org/patches/solarized/st-solarized-light-20190306-ed68fe7.diff | git apply && cp config.def.h config.h && makepkg --noconfirm -sif

cat << END > /home/"$user"/.xinitrc
setxkbmap -layout us,gr -option grp:win_space_toggle
fswm st -f "Source Code Pro:pixelsize=60:style=bold"
END

cat << END > /home/"$user"/.gitconfig
[user]
email = pbizopoulos@protonmail.com
name = Paschalis Bizopoulos
[pull]
rebase = false
END

echo "export QT_SCALE_FACTOR=4" >> /home/"$user"/.bashrc

mkdir -p /home/"$user"/.mail/
touch /home/"$user"/.mail/spoolfile

cat << END > /home/"$user"/.muttrc
set editor=/usr/bin/vim
set folder="~/.mail"
set from="pbizopoulos@iti.gr"
set pop_host="pops://pbizopoulos@mail.iti.gr:995"
set realname="Paschalis Bizopoulos"
set record="~/.mail/sent"
set smtp_url="smtps://pbizopoulos@mail.iti.gr:465"
set spoolfile="~/.mail/spoolfile"
END

mkdir -p /home/"$user"/.newsboat/
touch /home/"$user"/.newsboat/urls

cat << END > /home/"$user"/.newsboat/config
browser "qutebrowser %u"
delete-read-articles-on-quit yes
macro m set browser "mpv %u"; open-in-browser ; set browser "qutebrowser %u"
END

echo "filetype plugin indent on" > /home/"$user"/.vimrc

cat << END > /home/"$user"/post.txt
GitHub
1. ssh-keygen -t ed25519 -C "pbizopoulos@protonmail.com"
2. eval "$(ssh-agent -s)"
3. ssh-add /home/"$user"/.ssh/id_ed25519
4. Copy contents of /home/"$user"/.ssh/id_ed25519.pub to GitHub SSH settings.

Mutt
1. Add spoolfile to /home/"$user"/.mail/spoolfile

Newsboat
1. Add RSS urls to /home/"$user"/.newsboat/urls

Pulseaudio
1. pactl set-sink-volume 0 100%
2. pactl set-sink-mute 0 0
END

EOF

echo "Finished."
umount -R /mnt
