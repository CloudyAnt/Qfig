# This script only contain operations which only use system commands

function qfig() { #? enter the Qfig project folder
    cd $Qfig_loc
}

function qread() { #? use vared like read
	[ -z $1 ] && logError "Missing variable name!" && return 1
	eval "$1="
	eval "vared $1"
}

function qcmds() { #? operate available commands. syntax: qcmds commandsPrefix subcommands. -h for more
	[ -z "$1" ] && logInfo "Available commands(prefix): $(ls $Qfig_loc/command | perl -n -e'/(.+)Commands\.sh/ && print "$1 "')" && return
	if [ "-h" = "$1" ]; then
		logInfo "Basic syntax: qcmds commandsPrefix subcommands"
		qcmds
		logInfo "Subcommands: explain(default), cat(or read), vim(or edit)"
		return
	fi

    targetFile=$Qfig_loc/command/$1Commands.sh
    [ ! -f "$targetFile" ]  && logError "$targetFile dosen't exist" && qcmds && return 1
	
	case $2 in
		cat|read)
			cat $targetFile && return
			;;
		vim|edit)
			editfile $targetFile && return
			;;	
		""|explain)
			cat $targetFile | awk '/^function /{if ($4 == "#x") next; command = "\033[1;34m" $2 "\033[0m"; printf("%-30s", command); if ($4 == "#?") printf "\033[1;36m:\033[0;36m "; if ($4 == "#!") printf "\033[0;31m:\033[1;31m ";  \
				for (i = 5; i <= NF; i++) \
					printf $i " "; \
					printf "\n";}' \
					| awk '{sub("\\(\\)", "\033[1;37m()\033[0m")} 1'  | awk '{sub(":", "\033[0;" c "m:\033[1;" c "m")} 1'
			return
			;;
		*)
			logError "Unknown subcommands: $2"
			qcmds -h
			return 1
			;;
	esac
}

function editfile() { #? edit a file using preferedTextEditor
    [ ! -f $1 ] && logError "File required!"
    eval "$preferTextEditor $1"
}

function editmap() { #? edit mappingFile
    targetFile=$Qfig_loc/$1MappingFile
    [ ! -f "$targetFile" ] && logWarn "$targetFile dosen't exist" && return
    editfile $targetFile
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

function unsetFunctionsInFile() { #x unset functions in file 
    [ -z $1 ] && logError "trying to unsert functions, but no file was provided" && return 
    unset -f $(cat $1 | awk '/^function /{print $2}' | awk '{sub("\\(\\)", "")} 1')
}

### Log

function logInfo() {
    [ -z $1 ] && return
    #logColor "\033[30;46m" $1 
	qfigLog "\033[38;05;123m" $1
}


function logError() {
    [ -z $1 ] && return
    #logColor "\033[30;41m" $1 
	qfigLog "\033[38;05;196m" $1
}

function logWarn() {
    [ -z $1 ] && return
    #logColor "\033[30;103m" $1
	qfigLog "\033[38;05;226m" $1
}

function logSuccess() {
    [ -z $1 ] && return
    #logColor "\033[30;42m" $1
	qfigLog "\033[38;05;118m" $1
}

function logDebug() { #x debug
    [ -z $1 ] && return
	echo "\033[;3m\033[34;100mDEBUG\033[0;0m \033[1;3m$1\033[0;0m"
}

function qfigLog() { #x log with a colored dot prefix
    [[ -z "$1" || -z "$2" ]] && return
	echo "$1●\033[0;0m $2"
}

function forbiddenAlias() { #x alert a alias is forbidden
	[ -z "$1" ] && return
	if [ -z "$2" ]
	then
		logWarn "Forbidden Alias. Use \033[92;38m$1\033[0;0m Instead"
	else
		logWarn "Forbidden Alias: \033[31;38m$1\033[0;0m. Use \033[92;38m$2\033[0;0m Instead"
	fi
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

function targz() { #? compress folder to tar.gz using option -czvf
	[ ! -d $1 ] && logError "Folder required" && return 
	name=$(echo $1 | rev | cut -d/ -f1 | rev)
	tar -czvf $(echo $1 | rev | cut -d/ -f1 | rev).tar.gz $1
}

function utargz() { #? decompress a tar.gz file by using oftion -xvf
	if [ ! -f $1 ] || [ ! ${1: -7}  = ".tar.gz" ]
	then	
		logError "A tar.gz file required"
	else
		tar -xvf $1
	fi
}
