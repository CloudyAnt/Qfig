#? github related command
enable-qcmds json

function github:getSize() {
    if ! +base:checkParams "repo" "$1"; then return 1; fi

    local repo="$1"
    if [[ "$repo" =~ ^https?://.*github\.com/(.+)\.git$ ]]; then
        repo="${BASH_REMATCH[1]}"
    fi

    local resp=$(curl -s "https://api.github.com/repos/$repo")
    local size=$(jsonget -n "$resp" size | sed 's/\x1b\[[0-9;]*m//g')

    if [ "$size" -lt 1024 ]; then
        echo "${size}K"
    elif [ "$size" -lt 1048576 ]; then
        echo "$((size / 1024))M"
    else
        echo "$((size / 1048576))G"
    fi
}
