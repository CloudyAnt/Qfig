#? github related command
enable-qcmds json

function github:getInfo() {
    OPTIND=1
    local full=""
    while getopts ":f" opt; do
        case "$opt" in
            f)# Print full response
                full=1
                ;;
            \?)
                logError "Invalid option: -$OPTARG" && return 1
                ;;
        esac
    done
    shift "$((OPTIND - 1))"

    local repo="$1"

    # Auto-detect repo from current git repository if not specified
    if [ -z "$repo" ]; then
        if [ "$(git rev-parse --is-inside-work-tree 2>/dev/null)" = "true" ]; then
            local remote_url=$(git remote get-url origin 2>/dev/null)
            if [ -n "$remote_url" ]; then
                # Extract GitHub repo from various URL formats
                # Handles: git@github.com:owner/repo.git, https://github.com/owner/repo.git, etc.
                local tmp_repo="${remote_url##*github.com[/:]}"
                tmp_repo="${tmp_repo%.git}"
                if [[ "$tmp_repo" == */* ]]; then
                    repo="$tmp_repo"
                    logInfo "Getting info for current repo \e[1m$tmp_repo\e[0m"
                else
                    logError "Origin remote is not a GitHub repository"
                fi
            else
                logError "No repo specified and no origin remote found"
                return 1
            fi
        else
            logError "No repo specified and not in a git repository"
            return 1
        fi
    fi

    local resp=$(curl -s "https://api.github.com/repos/$repo")
    local http_code=$(jsonget -n "$resp" "status")

    if [ "404" = "$http_code" ]; then
        logWarn "The repo doesn't exists!" && return
    elif [ "200" = "$http_code" ]; then
        logWarn "Request failed with status: $http_code, check the full responese:"
        echo $resp
        return
    fi

    if [ "$full" ]; then
        echo $resp
        return
    fi

    local size=$(jsonget -n "$resp" size)
    if [ "$size" -lt 1024 ]; then
        size="${size}K"
    elif [ "$size" -lt 1048576 ]; then
        size="$((size / 1024))M"
    else
        size="$((size / 1048576))G"
    fi
    local createdAt=$(jsonget -n "$resp" "created_at")
    logInfo "Size: $size. Created At: $createdAt" 
}
