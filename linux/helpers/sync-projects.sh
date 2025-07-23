#!/usr/bin/bash

export BASH_SCRIPT_FILEPATH="$(readlink -e "${BASH_SOURCE[0]}")";
export BASH_SCRIPT_DIRPATH="$(dirname "${BASH_SCRIPT_FILEPATH}")";
export UTILITIES_COMMON_FUNCTIONS="${UTILITIES_COMMON_FUNCTIONS:-${BASH_SCRIPT_DIRPATH}/../common-functions.sh}";

COMMIT_MESSAGE="[$(date +"%H:%M:%S %Y-%m-%d")] AUTO SYNC COMMIT";

CMD_LINE_HELP="";
CMD_LINE_VERBOSE="";
CMD_LINE_DIFF="";
CMD_LINE_DIRECTION="remote2local";

function parse-cmd-line-arguments()
{
    local arguments=("$@");

    local help="";

    for argument in "${arguments[@]}"; do
        case "$argument" in
            '-h' | '--help')
                CMD_LINE_HELP='true'
                ;;

            '-v' | '--verbose')
                CMD_LINE_VERBOSE='true'
                ;;

            '-d' | '--diff')
                CMD_LINE_DIFF='true';
                ;;

            '-r2l' | '--remote-to-local')
                CMD_LINE_DIRECTION='remote2local';
                ;;
            '-l2r' | '--local-to-remote')
                CMD_LINE_DIRECTION='local2remote';
                ;;
        esac
    done

    echo "${arguments[2]}";
}

function find-all-projects()
{
    local projects=();
    local project='';
    local project_root='';

    readarray -d '' projects < <(find "$HOME" -iname '*.git' -print0);

    for project in "${projects[@]}"; do
        project_root="$(readlink -e "$(dirname "$project")")";
        has-git-remote "$project_root" && echo "$project_root";
    done
}

function check-project-status()
{
    local project_dir="$1"; shift 1;

    local -i repo_status=0;

    (
        cd "$project_dir"             || exit 1;
        is-in-git-repo "$project_dir" || exit 2;

        is_clean="$(git status | grep --perl-regexp --only-matching 'clean')";
        if [ -z "$is_clean" ]; then
            exit 3;
        fi

        exit 0;
    );
    repo_status=$?;

    if [ -n "$CMD_LINE_VERBOSE" ]; then

        if [ $repo_status -eq 0 ]; then
            printf -- "%-75s is up to date!\n" "$project_dir";
        elif [ $repo_status -le 2 ]; then
            log-error "${project_dir} is invalid git repository";
        elif [ $repo_status -eq 3 ]; then
            printf -- "%-75s needs an update!\n" "$project_dir";
        fi

    fi

    return $repo_status;
}

function sync-project()
{
    local project_dir="$1"; shift 1;

    (
        cd "$project_dir" || exit 1;

        # [ -n "$CMD_LINE_VERBOSE" ] && git add '--dry-run' -- .;

        # git add .  || exit 2;
        # git commit -s -m "$COMMIT_MESSAGE";
        # echo "$COMMIT_MESSAGE";
    ) || return $?;
}

function main()
{
    local arguments=("$@");

    local -a project_dirs=();
    local project_dir="";
    local -i project_status=0;

    # Sourcing common functions:
    source "$UTILITIES_COMMON_FUNCTIONS" || return 1;

    parse-cmd-line-arguments "${arguments[@]}";

    IFS=$'\n' read -r -d '' -a project_dirs < <(find-all-projects);

    for project_dir in "${project_dirs[@]}"; do
        check-project-status "$project_dir";
        project_status=$?;

        [ $project_status -eq 3 ] && sync-project "$project_dir";
    done
}

main "$@";
