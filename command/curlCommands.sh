# Curl commands

function cget() {
    [ -z "$1" ] && return
    curl -X GET -H "Content-Type: application/json" "$1"
}

function cpost() {
    [ -z "$1" ] || [ -z "$2" ] && return
    curl -X POST -H "Content-Type: application/json" -d "$1" $2
}

function cput() {
    [ -z "$1" ] || [ -z "$2" ] && return
    curl -X PUT -H "Content-Type: application/json" -d "$1" $2
}

