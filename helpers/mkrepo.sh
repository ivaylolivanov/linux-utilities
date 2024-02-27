#!/bin/bash

function mkrepo()
{
    local repo_name="$1"; shift 1;

    local repos_dir='/media/storage/repositories';
    local new_repo="${repos_dir}/${repo_name}.git";
    local ip_address="$(hostname -I | awk '{print $1}')";
    local remote="git@${ip_address%%*( )}:${new_repo}";

    if [ -d "$new_repo" ]; then
        printf -- "\nError: ${new_repo} already exists!\n\n";
        return 1;
    fi

    mkdir -pv "$new_repo" || return 2;

    (
        cd "$new_repo" || exit 1;
        git init --bare || exit 2;
    ) || return 3;

    printf -- "\nSuccessfully created new repository!\n";
    printf -- "\nYou can execute 'git remote add <REMOTE_NAME> ${remote}'.\n\n";

    return 0;
}

mkrepo "$@" || exit $?;
