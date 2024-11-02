#!/usr/bin/bash

function is-persist-value-valid()
{
    local -l value="$1"; shift 1;

    local positive='--persist';
    local negative='--no-persist';

    [ "$value" != "$positive" ] && [ "$value" != "$negative" ] && return 1;

    return 0;
}

function is-alias-existing()
{
    local name="$1"; shift 1;
    local -i result=0;

    alias "${name}" >/dev/null 2>&1;
    result=$?;

    return $result;
}

function is-alias-persisting()
{
    local -l value="$1"; shift 1;

    local positive='--persist';

    [ "$value" != "$positive" ] && return 1;

    return 0;
}

function overwrite-alias()
{
    local name="$1";                   shift 1;
    local value="$1";                  shift 1;
    local persist="${1:---no-persist}"; shift 1;

    local aliases_file="${HOME}/.bash_aliases";

    is-persist-value-valid "$persist" ||
    {
        printf -- "\nERROR: %s '%s' and '%s'!\n\n"        \
            'The third argument supports only 2 values -' \
            '--persist'                                   \
            '--no-persist';
        return 1;
    }

    if is-alias-existing "$name"; then
       unalias "$name" || return 2;

       if is-alias-persisting "$persist" ; then
           sed -i "/^alias ${name}/d" "$aliases_file" || return 3;
       fi
    fi

    alias "${name}=${value}" || return 5;
    if is-alias-persisting "$persist"; then
        echo "alias ${name}='${value}';" >> "$aliases_file" || return 4;
    fi

    return 0;
}

function is-strict-value-valid()
{
    local -l value="$1"; shift 1;

    local positive='--strict';
    local negative='--no-strict';

    [ "$value" != "$positive" ] && [ "$value" != "$negative" ] && return 1;

    return 0;
}

function is-strict()
{
    local -l value="$1"; shift 1;

    local positive='--strict';

    [ "$value" == "$positive" ] && return 1;

    return 0;
}

function is-in-git-repo()
{
    local directory="$1"; shift 1;

    cd "$directory" || return 1;
    git rev-parse --is-inside-work-tree >/dev/null 2>&1 || return 2;

    return 0;
}

function mark-project()
{
    local -l persist="${1:---persist}"; shift 1;
    local -l strict="${1:---strict}";   shift 1;

    local alias_name='goto-project';
    local current_directory="$(pwd)";

    is-persist-value-valid "$persist" ||
    {
        printf -- "\nERROR: %s '%s' and '%s'!\n\n"        \
            'The first argument supports only 2 values -' \
            '--persist'                                   \
            '--no-persist';
        return 1;
    }

    is-strict-value-valid "$strict" ||
    {
        printf -- "\nERROR: %s '%s' and '%s'!\n\n"         \
            'The second argument supports only 2 values -' \
            '--strict'                                     \
            '--no-stricg';
        return 2;
    }

    if is-strict; then
        is-in-git-repo "$current_directory" ||
        {
            printf -- "ERROR: Not in a project. If the directory is %s\n%s\n" \
                "viable, initialize a git"                                    \
                "       repository or use '--no-strict' as second parameter.";
            return 3;
        }
    fi

    overwrite-alias "$alias_name" "cd ${current_directory}" "$persist" ||
        return 4;

    return 0;
}

function unmark-project()
{
    local alias_name='goto-project';
    local message='No current project set!';

    overwrite-alias "$alias_name" "echo ${message}" || return 1;

    return 0;
}
