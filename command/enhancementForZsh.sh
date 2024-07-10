# enhancement for bash

function readWithPromptAndLimit() {
    local prompt=$1
    local max_length=$2

    zle -A self-insert _saved_widget
    my-self-insert() {
        zle .self-insert
        if (( ${#BUFFER} >= max_length )); then
            zle .accept-line; return
        fi
    }
    zle -N self-insert my-self-insert

    function cleanup() {
        zle -A _saved_widget self-insert
        unset -f my-self-insert
        unset -f cleanup
        unfunction TRAPINT
    }

    function TRAPINT() {
        cleanup
        return 130
    }

    _TEMP=""
    vared -p "$prompt" _TEMP
    cleanup
}