#!/usr/bin/bash

function install-packages()
{
    sudo apt update  || return 2;
    sudo apt upgrade || return 2;

    sudo apt install -y git emacs tree mpv fonts-inconsolata fonts-roboto llvm \
        clang clangd fonts-font-awesome mtp-tools libudisks2-dev jmtpfs rustc  \
        cargo gvfs-backends libudisks2-dev gvfs-backends htop libssl-dev wget  \
        pkg-config libdbus-1-dev qbittorrent pavucontrol curl || return 2;
}
