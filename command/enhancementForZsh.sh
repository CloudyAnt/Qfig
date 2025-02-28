# Enhancement for zsh

function readWithPromptAndLimit() {
    local prompt=$1
    local max_length=$2

    # Validate input parameters
    [[ -z "$prompt" || -z "$max_length" ]] && return 1
    [[ ! "$max_length" =~ ^[0-9]+$ ]] && return 1

    # Save original widget
    zle -A self-insert _saved_widget

    # Define insert handler with length limit
    my-self-insert() {
        # Only insert if under length limit
        if (( ${#BUFFER} < max_length )); then
            zle .self-insert
        fi
        # Accept line when limit reached
        if (( ${#BUFFER} >= max_length )); then
            zle .accept-line
            return
        fi
    }

    # Replace widget
    zle -N self-insert my-self-insert

    # Cleanup function to restore original state
    function cleanup() {
        zle -A _saved_widget self-insert 
        unset -f my-self-insert cleanup TRAPINT
    }

    # Handle Ctrl-C interrupt
    function TRAPINT() {
        cleanup
        return 130
    }

    # Read input with prompt
    unsetVar _TEMP
    _TEMP=""
    vared -p "$prompt" _TEMP

    cleanup
    return 0
}