#!/usr/bin/bash

SCRIPT_ABS_PATH="$(readlink -e $0)";
SCRIPT_DIR="$(readlink -e $(dirname $SCRIPT_ABS_PATH))";
LINUX_FLAVOURS_DIR="${SCRIPT_DIR}/flavours";
COMMON_VARIABLES_FILE="${SCRIPT_DIR}/common-variables.sh";
COMMON_FUNCTIONS_FILE="${SCRIPT_DIR}/common-functions.sh";
HELPERS_DIR="$(readlink -e "${SCRIPT_DIR}/../helpers")";
ALIASES_FILE="${SCRIPT_DIR}/aliases.sh";
CLANG_FORMAT_FILE="${SCRIPT_DIR}/clang-format";

. "$COMMON_VARIABLES_FILE" || exit 1;
. "$COMMON_FUNCTIONS_FILE" || exit 2;

OS="$(detect-os)";
OS_CODENAME="$(cat "$OS_RELEASE_DATA" | grep '^VERSION_CODENAME' | cut -d '=' -f2)";
OS_SPECIFICS_SCRIPT="${LINUX_FLAVOURS_DIR}/${OS}.sh";

echo "Setting the timezone to ${TIMEZONE}";
sudo timedatectl set-timezone "$TIMEZONE";

if file-exists "$OS_SPECIFICS_SCRIPT" && [ -s "$OS_SPECIFICS_SCRIPT" ]; then
    . "$OS_SPECIFICS_SCRIPT";
fi

install-packages ||
{
    printf -- "\nFailed to install packages!\n\n";
    exit $?;
}

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
git clone "$REPO_I3WM" --branch='picom'    "${HOME}/.config/picom";

git clone "$REPO_SYSTEM76_FIRMWARE_CLI" "${PROJECTS_SYSTEM76_DIR}/firmware-cli";

echo "Installing aliases";
cp --verbose "$ALIASES_FILE" "$BASH_ALIAS_FILE";

echo "Installing global clang formatting config";
cp --verbose "$CLANG_FORMAT_FILE" "$CLANG_FORMAT_GLOBAL_CONFIG";

echo "Setting up persistent sourcing ${HELPERS_DIR}/alias-update.sh";
printf -- "\n. '%s';\n" "${HELPERS_DIR}/alias-update.sh" >> "$BASH_RC_FILE";
