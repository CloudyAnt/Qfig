#? Curl commands

function cpost() {
    [ -z "$1" ] && return
    curl -X POST -H "Content-Type: application/json" -d "$2" $1
}

function cput() {
    [ -z "$1" ] && return
    curl -X PUT -H "Content-Type: application/json" -d "$2" $1
}

