function gorun() { #? go compile then run
    [ -z "$1" ] && logError "Which file to run?" && return 1
    local file=$1
    
    # Add .go extension if not present
    [[ $file =~ ^[^.]+$ ]] && file="${file}.go"
    
    # Validate file exists and has .go extension
    [ ! -f "$file" ] && logError "File $file does not exist!" && return 1
    [[ ! $file =~ \.go$ ]] && logWarn "File does not end with .go" && return 1

    # Extract filename without extension
    local simpleName=${file%.*}
    
    # Build and run
    if go build "$file"; then
        ./"$simpleName"
        rm "$simpleName" # Clean up executable
    fi
}

function _gorun() { #x
    # Handle array base for shell compatibility
    declare -i arrayBase
    [[ -o ksharrays ]] && arrayBase=0 || arrayBase=1

    # Only complete first argument
    [ $COMP_CWORD -gt $(($arrayBase + 1)) ] && return 0

    # Get current word being completed
    local current="${COMP_WORDS[$COMP_CWORD]}"
    
    # Generate completions for .go files
    local gofiles=$(compgen -f -X "!*.go" -- "$current")
    local noext=$(compgen -f -X "*.go" -- "$current")
    COMPREPLY=($(compgen -W "$gofiles $noext" -- "$current"))
    return 0
}

complete -F _gorun gorun
