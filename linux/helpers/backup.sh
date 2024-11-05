#!/usr/bin/bash

function get-os-name()
{
    local os_release='/etc/os-release';
    local os_name='';

    if [ ! -e "$os_release" ]; then
        printf -- "\nERROR: ${os_release} does not exist\!\n";
        return 1;
    fi

    if [ ! -r "$os_release" ]; then
        printf -- "\nERROR: ${os_release} is not readable\!\n";
        return 2;
    fi

    if [ -z "$os_release" ]; then
        printf -- "\nERROR: ${os_release} is empty\!\n";
        return 3;
    fi

    os_name="$(
        . "$os_release" || exit 4;
        [ -z "$ID" ]    && exit 5;

        echo "$ID" | tr [:upper:] [:lower];
    )";

    [ -z "$os_name" ] && return 6;

    echo "$os_name";
    return 0;
}

function get-rsync-binary()
{
    local rsync_binary='';
    rsync_binary="$(which -a rsync | head -n 1)";

    echo "$rsync_binary";
    return 0;
}

function backup()
{
    local location="$1"; shift 1;

    local rsync_binary='';
    local -a exlude_paths=(
        "/dev/*"
        "/proc/*"
        "/sys/*"
        "/tmp/*"
        "/run/*"
        "/mnt/*"
        "/media/*"
        "/lost+found"
    );

    rsync_binary="$(get-rsync-binary)";
    [ -z "$rsync_binary" ] &&
    {
        printf -- "\nERROR: rsync is not installed!\n";
        return 1;
    }

    "$rsync_binary"                       \
        --archive                         \
        --acls                            \
        --xattrs                          \
        --human-readable                  \
        --progress                        \
        --delete                          \
        --verbose                         \
        "${exlude_paths[@]/#/--exclude=}" \
        '/'                               \
        "$location";

    return 0;
}

function backup-stamp()
{
    local location="$1"; shift 1;

    local stamping_binary='';
    local stamp='';
    local stamp_temp_file='backup-stamp.txt';
    local timestamp='';
    local rsync_binary='';

    timestamp="$(date +"%Y-%m-%d-%H-%M-%S")";

    stamping_binary="$(which -a neofetch | head -n 1)";
    [ -z "$stamping_binary" ] &&
    {
        stamping_binary='hostnamectl';
    }

    rsync_binary="$(get-rsync-binary)";
    [ -z "$rsync_binary" ] &&
    {
        printf -- "\nERROR: rsync is not installed!\n";
        return 1;
    }

    stamp="$($stamping_binary)";

    printf -- "%40s\n" "$timestamp" > "$stamp_temp_file"
    echo "$stamp" >> "$stamp_temp_file";
    "$rsync_binary"        \
        --archive          \
        --verbose          \
        "$stamp_temp_file" \
        "$location"        || return "$?";

    rm -v "$stamp_temp_file";

    return 0;
}

function main()
{
    local destination_hostname="$1"; shift 1;

    local remote_storage='/media/storage/backups';
    local hostname='';
    local os_name='';
    local -i get_os_status=0;
    local backup_location_dir='';
    local backup_location_stamp='';

    hostname="$(hostname)";
    os_name="$(get-os-name)";
    get_os_status=$?;

    (( $get_os_status )) && return "$get_os_status";

    printf -v backup_location -- "%s:%s/%s-%s" \
        "$destination_hostname"                \
        "$remote_storage"                      \
        "$os_name"                             \
        "$hostname";

    backup_location_stamp="${backup_location}/backup-stamp.txt";

    backup       "$backup_location"       || return "$?";
    backup-stamp "$backup_location_stamp" || return "$?";

    return 0;
}

main "$@" || exit $?;
