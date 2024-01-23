#!/bin/bash

echo "Starting Installation . . ."
echo "This script assumes that you have already partitioned your disk as follows:"
echo -e "    * Mountpont=/mnt      Type=Linux Filesystem       Mountpath='/mnt'"
echo -e "    * Mountpont=/mnt/efi  Type=EFI File System        Mountpath='/efi'"
echo -e "    * Mountpont=/mnt/boot Type=Linux Extended Boot    Mountpath='/boot'"

if mountpoint -q /mnt && mountpoint -q /mnt/efi && mountpoint -q /mnt/boot; then
    echo "All mountpoints are valid."
else
    echo "One or more mountpoints are invalid."
    exit 1
fi

PACKAGES="base linux linux-firmware amd-ucode xdg-user-dirs efifs glibc fwupd"

# Update the mirror list
echo "Updating mirror list . . ."
reflector

# Power Management
echo "Added power-profiles-daemon for power management . . ."
PACKAGES="$PACKAGES power-profiles-daemon"

# dGPU
echo "Added switcheroo-control for switching between dGPU and iGPU . . ."
PACKAGES="$PACKAGES switcheroo-control"

# Vulkan
echo "Added vulkan-radeon for Vulkan . . ."
PACKAGES="$PACKAGES vulkan-radeon vulkan-icd-loader"

# Flatpak
echo "Added flatpak for installing apps . . ."
PACKAGES="$PACKAGES flatpak"

# Boot Splash
echo "Added plymouth for boot animation . . ."
PACKAGES="$PACKAGES plymouth"

# Fonts
echo "Added fonts . . ."
PACKAGES="$PACKAGES noto-fonts noto-fonts-cjk noto-fonts-emoji ttf-dejavu ttf-liberation ttf-roboto"

# Superuser
echo "Added sudo for executing commands as superuser . . ."
PACKAGES="$PACKAGES sudo"

# Printer
echo "Added CUPS for printing . . ."
PACKAGES="$PACKAGES cups cups-pdf"

# Editors
echo "Added vim and nano for editing files . . ."
PACKAGES="$PACKAGES vim nano"

# Git
echo "Added git for version control . . ."
PACKAGES="$PACKAGES git"

# Bash Completion
echo "Added bash-completion and pkgfile for bash completion . . ."
PACKAGES="$PACKAGES bash-completion pkgfile"

# Network (NetworkManager)
echo "Added NetworkManager for network . . ."
PACKAGES="$PACKAGES networkmanager network-manager-applet"

# Audio (Pipewire)
echo "Added pipewire for audio . . ."
PACKAGES="$PACKAGES pipewire wireplumber pipewire-audio pipewire-pulse pipewire-alsa pipewire-jack"

# Codecs
echo "Added multimedia codecs . . ."
PACKAGES="$PACKAGES gst-plugins-base gst-plugins-good gst-plugins-bad gst-plugins-ugly gst-libav gst-plugin-pipewire gst-plugin-va libva-mesa-driver"

# Image Codecs
echo "Added image codecs . . ."
PACKAGES="$PACKAGES libjxl libheif libavif libwebp"

# Screen Capture
echo "Added screen capture tools . . ."
PACKAGES="$PACKAGES xdg-desktop-portal xdg-desktop-portal-gnome"

# Minimal GNOME
echo "Added GNOME . . ."
PACKAGES="$PACKAGES gdm gnome-shell gnome-keyring polkit-gnome gnome-control-center gnome-terminal gnome-tweaks nautilus gnome-backgrounds gnome-disk-utility gnome-software gnome-initial-setup"

echo "Packages to be installed:"
echo $PACKAGES
sleep 2

# Install
echo -e"\n\nInstalling . . ."
pacstrap -K /mnt $PACKAGES

# Generate fstab
echo "Generating fstab . . ."
genfstab -U /mnt >> /mnt/etc/fstab

# Copy mirrorlist
echo "Copying mirrorlist . . ."
cp /etc/pacman.d/mirrorlist /mnt/etc/pacman.d/mirrorlist

# Add plymouth to HOOKS
echo "Adding plymouth to HOOKS . . ."
sed -i 's/HOOKS=(\(.*\))/HOOKS=(\1 plymouth)/g' /mnt/etc/mkinitcpio.conf

# Enable GDM and NetworkManager
arch-chroot /mnt systemctl enable gdm NetworkManager

# Install systemd-boot
echo "Installing systemd-boot . . ."
arch-chroot /mnt bootctl --esp-path=/efi --boot-path=/boot install

mkdir -p /mnt/efi/EFI/systemd/drivers
cp /mnt/usr/lib/efifs-x64/ext2_x64.efi /mnt/efi/EFI/systemd/drivers/

read -p "Enter the path to your root partition: " root_partition
UUID=$(arch-chroot /mnt blkid -s UUID -o value $root_partition)

echo -e \
"title\tArch Linux
linux\t/vmlinuz-linux
initrd\t/amd-ucode.img
initrd\t/initramfs-linux.img
options\troot=UUID=$UUID rw boot splash" >> /mnt/boot/loader/entries/arch.conf

echo -e \
"title\tArch Linux (Fallback)
linux\t/vmlinuz-linux
initrd\t/amd-ucode.img
initrd\t/initramfs-linux-fallback.img
options\troot=UUID=$UUID rw boot splash" >> /mnt/boot/loader/entries/arch-fallback.conf

echo "Done!"
echo "You can now reboot into your new Arch Linux installation."
