#!/usr/bin/bash

function initialize-aptitude()
{
    local codename="$OS_CODENAME";

    local debian_apt_url='http://deb.debian.org/debian/';
    local debian_apt_security_url='http://security.debian.org/debian-security';

    local apt_components="${codename} main non-free-firmware non-free contrib";
    local apt_components_security="${codename}-security main non-free-firmware non-free contrib";
    local apt_components_updates="${codename}-updates main non-free-firmware";

    local apt_initial_sources='';
    printf -v apt_initial_sources -- "%s\n%s\n%s\n%s\n%s\n%s\n"         \
        "deb ${debian_apt_url} ${apt_components}"                       \
        "deb-src ${debian_apt_url} ${apt_components}"                   \
        "deb ${debian_apt_security_url} ${apt_components_security}"     \
        "deb-src ${debian_apt_security_url} ${apt_components_security}" \
        "deb ${debian_apt_url} ${apt_components_updates}"               \
        "deb-src ${debian_apt_url} ${apt_components_updates}";

    printf -- "\n\nWriting initial aptitude sources list content:\n";
    echo "$apt_initial_sources" | sudo tee "$APT_SOURCES_LIST";

    return 0;
}

function install-brave-browser()
{
    local keyring_filename='brave-browser-archive-keyring.gpg';
    local keyring_save_location="/usr/share/keyrings/${keyring_filename}";
    local release_url='https://brave-browser-apt-release.s3.brave.com';
    local keyring_url="${release_url}/${keyring_filename}";
    local apt_repo_file="${APT_SOURCES_LIST}.d/brave-browser-release.list";

    local apt_source_content='';
    printf -v apt_source_content -- "deb [signed-by=%s] %s stable main" \
        "$keyring_save_location"                                        \
        "${release_url}/";

    sudo curl -fsSLo "$keyring_save_location" "$keyring_url" || return 1;
    echo "$apt_source_content" | sudo tee "$apt_repo_file";

    sudo apt update                   || return 2;
    sudo apt install -y brave-browser || return 2;

    return 0;
}

function install-rustup()
{
    local rustup_url='https://sh.rustup.rs';
    local protocol='=https';
    local rustup='';

    rustup="$(curl          \
        --proto "$protocol" \
        --tlsv1.2           \
        --silent            \
        --show-error        \
        --fail              \
        "${rustup_url}"     || exit 1)" || return $?;

    if [ -n "$rustup" ]; then
        eval "$rustup" || return 2;
    fi

    return 0;
}

function install-non-native-packages()
{
    install-brave-browser || return 1;
    install-rustup        || return 2;

    return 0;
}

function install-packages()
{
    initialize-aptitude || return 1;

    sudo apt update  || return 2;
    sudo apt upgrade || return 2;
    sudo apt install -y git emacs i3 i3lock rofi gdb nvidia-driver tree mpv    \
        firmware-misc-nonfree fonts-inconsolata fonts-roboto llvm clang clangd \
        fonts-font-awesome mtp-tools libudisks2-dev jmtpfs pkg-config feh jq   \
        gvfs-backends libudisks2-dev gvfs-backends ristretto xautolock cargo   \
        htop libssl-dev libdbus-1-dev picom vulkan-tools libvulkan-dev rustc   \
        qbittorrent pavucontrol thunderbird software-properties-common polybar \
        imagemagick shellcheck curl dvipng conky-all rsync xorg-dev blueman    \
        texlive texlive-latex-extra texlive-fonts-extra texlive-bibtex-extra   \
        python3-pip ssh physlock neofetch || return 2;

    install-non-native-packages || return 3;

    return 0;
}
