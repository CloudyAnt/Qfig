# Enhancement for bash

function readWithPromptAndLimit() {
    local prompt=$1
    local max_length=$2

    # save the original widget
    zle -A self-insert _saved_widget
    my-self-insert() {
        zle .self-insert
        if (( ${#BUFFER} >= max_length )); then
            # accept the line when length limit meets
            zle .accept-line; return
        fi
    }
    # replace the widget
    zle -N self-insert my-self-insert

    function cleanup() {
        # restore the original widget
        zle -A _saved_widget self-insert
        unset -f my-self-insert
        unset -f cleanup
        unfunction TRAPINT
    }

    # handle Ctrl-C
    function TRAPINT() {
        cleanup
        return 130
    }

    unsetVar _TEMP
    _TEMP=""
    vared -p "$prompt" _TEMP
    cleanup
}