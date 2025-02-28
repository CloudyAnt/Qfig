#? These are commands about java, make sure it's available before use.

function jrun() { #? java compile then run, jrun Hello => javac Hello.java && java Hello
    [ -z "$1" ] && logError "Which file to run?" && return 1
    local file=$1
    
    # Add .java extension if not present
    [[ $file =~ ^[^.]+$ ]] && file="${file}.java"
    
    # Validate file exists and has .java extension
    [ ! -f "$file" ] && logError "File $file does not exist!" && return 1
    [[ ! $file =~ \.java$ ]] && logWarn "File does not end with .java" && return 1

    # Extract filename without extension
    local simpleName=${file%.*}
    
    # Build and run
    if javac "$file"; then
        java "$simpleName"
    fi
}

function +jrun() { #x
    # Handle array base for shell compatibility
    declare -i arrayBase
    [[ -o ksharrays ]] && arrayBase=0 || arrayBase=1

    # Only complete first argument
    [ $COMP_CWORD -gt $(($arrayBase + 1)) ] && return 0

    # Get current word being completed
    local current="${COMP_WORDS[$COMP_CWORD]}"
    
    # Generate completions for .java files
    local javafiles=$(compgen -f -X "!*.java" -- "$current") 
    local noext=$(compgen -f -X "*.java" -- "$current")
    COMPREPLY=($(compgen -W "$javafiles $noext" -- "$current"))
    return 0
}

complete -F +jrun jrun
