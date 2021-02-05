# This script only contain operations which only use system commands

function qfig() { #? enter the Qfig project folder
    cd $Qfig_loc
}

function vimcs() { #? edit Qfig commands
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


function call1level() { #? call function in 1 level folders
    begin=`pwd`
    command=$1

    if [ "$begin" = "" ]
    then
        return
    fi

    for d in *; do
        [ ! -d "$begin/$d" ] && continue;
        cd "$begin/$d"
        eval $command
    done

    cd $begin
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
