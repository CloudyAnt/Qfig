# This script only contain operations which only use system commands

function qfig() { #? enter the Qfig project folder
    cd $Qfig_loc
}

function vimcmd() { #? edit Qfig commands
    targetFile=$Qfig_loc/command/$1Commands.sh
    [ ! -f "$targetFile" ]  && logWarn "$targetFile dosen't exist" && return
    vim $targetFile
}

function vimmap() { #? edit mappingFile
    targetFile=$Qfig_loc/$1MappingFile
    [ ! -f "$targetFile" ] && logWarn "$targetFile dosen't exist" && return
    vim $targetFile
}

function explain() { #? show comments for functions which defined like: function example() #? explaination
    targetFile=$1
    [ ! -f "$targetFile" ] && logWarn "$targetFile dosen't exist" && return

    logInfo "Explains of $targetFile: "

    cat $targetFile | awk '/^function /{command = "\033[1;34m" $2 "\033[0m"; printf("%-30s", command); if ($4 == "#?") printf "\033[1;36m:\033[0;36m "; if ($4 == "#!") printf "\033[0;31m:\033[1;31m ";  \
        for (i = 5; i <= NF; i++) \
            printf $i " "; \
            printf "\n";}' \
            | awk '{sub("\\(\\)", "\033[1;37m()\033[0m")} 1'  | awk '{sub(":", "\033[0;" c "m:\033[1;" c "m")} 1'
}

function explaincs() { #? show function comments in command folder 
    targetFile=$Qfig_loc/command/$1Commands.sh
    [ ! -f "$targetFile" ] && [ ! -f "$1" ] && logWarn "$targetFile dosen't exist" && return

    explain $targetFile
}

function defaultV() { #? set default value for variable
    value_name=$1
    default_value=$2

    [ -z "$value_name" ] && return

    eval "real_value=\$$value_name"

    [ -z "$real_value" ] && eval "$value_name='$default_value'"

    unset value_name
    unset default_value
    unset real_value
}

function unsetFunctionsInFile() {
    [ -z $1 ] && logError "trying to unsert functions, but no file was provided" && return 
    unset -f $(cat $1 | awk '/^function /{print $2}' | awk '{sub("\\(\\)", "")} 1')
}

### Log

function logInfo() {
    [ -z $1 ] && return
    logColor "\033[30;46m" $1 
}


function logError() {
    [ -z $1 ] && return
    logColor "\033[30;41m" $1 
}

function logWarn() {
    [ -z $1 ] && return
    logColor "\033[30;103m" $1
}

function logSuccess() {
    [ -z $1 ] && return
    logColor "\033[30;42m" $1
}

function logDebug() {
    [ -z $1 ] && return
    logColor "\033[1;3m\033[34;100m" $1
}

function logColor() {
    [[ -z "$1" || -z "$2" ]] && return
    echo $1$2"\033[0;0m"
}


### 

function mktouch() { #? make dirs & touch file
    [ -z $1 ] && return
    for f in "$@"; do
        mkdir -p -- "$(dirname -- "$f")"
        touch -- "$f"
    done
}


###

function replaceWord() { #? backup file with pointed suffix & replace word in file 
    [ $# -lt 4 ] && logError "required params: file placeholder replacement backupSuffix" && return

    [ ! -z = "$4" ] &&  cp "$1" "$1.$4"

    cat $1 | awk -v placeholder="$2" -v replacement="$3" '$0 ~ placeholder{sub(placeholder, replacement)} 1' | tee "$1" | printf ""
}


function undoReplaceWord() { #? recovery file with pointed suffix 
    [ $# -lt 2 ] && logError "required params: sourceFile suffix" && return
    [ -f "$1.$2" ] && mv "$1.$2" $1
}

###

function assertExist() { #? check file existence 
    for file in "$@"
    do
        [ ! -f "$file" ] && logError "Missing file: $file" && return
    done
    echo "checked"
}

function rezsh() { #? source .zshrc
    logInfo "Refreshing zsh..."
    source ~/.zshrc
    logSuccess "Refreshed zsh"
}
