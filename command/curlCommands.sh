# Curl commands

function cget() {
    curl -X GET -H "Content-Type: application/json" "$1"
}

function cput() {
    curl -X PUT -d "$2" -H "Content-Type: application/json" "$1"
}
