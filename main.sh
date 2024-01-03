#!/usr/bin/bash

PROJECTS_DIR="${HOME}/Projects";
PROJECTS_SYSTEM76_DIR="${PROJECTS_DIR}/system76";
APT_SOURCES_LIST="/etc/apt/sources.list";
OS_RELEASE_DATA="/etc/os-release";
TIMEZONE='Europe/Sofia';

REPO_EMACS='git@github.com:ivaylolivanov/emacs.git';
REPO_I3WM='git@github.com:ivaylolivanov/i3WM_Setup.git';
REPO_SYSTEM76_FIRMWARE_CLI='https://github.com/pop-os/system76-firmware.git';

echo "Setting the timezone to ${TIMEZONE}";
sudo timedatectl set-timezone "$TIMEZONE";

OS="$(cat "$OS_RELEASE_DATA" | grep '^ID' | cut -d '=' -f2)";
OS_VERSION="$(cat "$OS_RELEASE_DATA" | grep '^VERSION_CODENAME' | cut -d '=' -f2)";

if [ "$OS" == 'debian' ]; then

    sudo echo 'deb http://deb.debian.org/debian/ bookworm main non-free-firmware non-free contrib'                           >  "$APT_SOURCES_LIST";
    sudo echo 'deb-src http://deb.debian.org/debian/ bookworm main non-free-firmware non-free contrib'                       >> "$APT_SOURCES_LIST";
    sudo echo 'deb http://security.debian.org/debian-security bookworm-security main non-free-firmware non-free contrib'     >> "$APT_SOURCES_LIST";
    sudo echo 'deb-src http://security.debian.org/debian-security bookworm-security main non-free-firmware non-free contrib' >> "$APT_SOURCES_LIST";
    sudo echo 'deb http://deb.debian.org/debian/ bookworm-updates main non-free-firmware'                                    >> "$APT_SOURCES_LIST";
    sudo echo 'deb-src http://deb.debian.org/debian/ bookworm-updates main non-free-firmware'                                >> "$APT_SOURCES_LIST";

    sudo apt update;
    sudo apt upgrade;
    sudo apt install -y git emacs i3 i3lock rofi polybar nvidia-driver tree mpv \
        firmware-misc-nonfree fonts-inconsolata fonts-roboto llvm clang clangd  \
        fonts-font-awesome mtp-tools libudisks2-dev jmtpfs pkg-config cargo feh \
        gvfs-backends libudisks2-dev gvfs-backends ristretto xautolock physlock \
        htop libssl-dev libdbus-1-dev picom vulkan-tools libvulkan-dev curl     \
        qbittorrent pavucontrol thunderbird;

fi

mkdir -pv "$PROJECTS_DIR";
mkdir -pv "$PROJECTS_SYSTEM76_DIR";

git config --global init.defaultBranch 'main';
git config --global user.name 'Ivaylo Ivanov';
git config --global user.email 'ivaylolivanov95@gmail.com';

git config --global alias.l    'log --pretty=oneline --decorate --abbrev-commit';
git config --global alias.ll   'log --graph --decorate --abbrev-commit --pretty=oneline';
git config --global alias.root 'rev-parse --show-toplevel';
git config --global alias.pwb  'branch --show-current';
git config --global alias.cb   'checkout';

git clone "$REPO_EMACS" "${HOME}/.emacs.d";
git clone "$REPO_I3WM" --branch='i3wm'     "${HOME}/.config/i3";
git clone "$REPO_I3WM" --branch='i3status' "${HOME}/.config/i3status";
git clone "$REPO_I3WM" --branch='rofi'     "${HOME}/.config/rofi";

git clone "$REPO_SYSTEM76_FIRMWARE_CLI" "${PROJECTS_SYSTEM76_DIR}/firmware-cli";
