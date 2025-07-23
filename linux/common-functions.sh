#!/bin/bash

function is-in-git-repo()
{
    local directory="$1"; shift 1;

    cd "$directory" || return 1;
    git rev-parse --is-inside-work-tree >/dev/null 2>&1 || return 2;

    return 0;
}

function has-git-remote()
{
    local directory="$1"; shift 1;

    local -i subshell_status=0;
    local remote="";

    (
        cd             "$directory" || exit 1;
        is-in-git-repo "$directory" || exit 2;

       remote="$(git remote -v)";
       [ -z "$remote" ] && exit 3;

       exit 0;
    );

    subshell_status=$?;

    return $subshell_status;
}

function log-error()
{
    local message="$1"; shift 1;

    printf -- "\nERROR: %s!\n\n" "$message";

    return 0;
}
