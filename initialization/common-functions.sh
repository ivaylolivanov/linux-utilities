#!/usr/bin/bash

function file-exists()
{
    local filepath="$1"; shift 1;

    [ -f "$filepath" ] && return 0;

    return 1;
}

function file-is-readable()
{
    local filapath="$1"; shift 1;

    [ -r "$filapath" ] && return 0;

    return 1;
}

function detect-os()
{
    local -l os='';
    local -lr apt_raspi_filename='raspi.list';
    local apt_raspi_filepath="${APT_SOURCES_LIST_DIR}/${apt_raspi_filename}";

    file-exists "$OS_RELEASE_DATA" ||
    {
        printf -- "\nERROR: %s! %s!\n"          \
            "${OS_RELEASE_DATA} does not exist" \
            "Cannot detect current OS";
        return 1;
    }

    file-is-readable "$OS_RELEASE_DATA" ||
    {
        printf -- "\nERROR: %s is not readable!" \
            "$OS_RELEASE_DATA";
        return 2;
    }

    os="$(cat "$OS_RELEASE_DATA" | grep '^ID' | cut -d '=' -f2)";

    if [ "$os" = 'debian' ]; then
        file-exists "$apt_raspi_filepath" &&
            os='raspberry-pi-os';
    fi

    echo "$os";

    return 0;
}

function install-packages()
{
    # In case, no OS specifics were defined, use this stub function.
    return 0;
}
