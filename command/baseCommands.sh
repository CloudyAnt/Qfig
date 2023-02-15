# This script only contain operations which only use system commands

function qfig() { #? Qfig preserved command
	case $1 in
		help)
			logInfo "Usage: qfig <command>\n\n  Available commands:\n"
			printf "    %-10s%s\n" "help" "Print this help message"
			printf "    %-10s%s\n" "update" "Update Qfig"
			printf "    %-10s%s\n" "into" "Go into Qfig project folder"
			printf "    %-10s%s\n" "config" "Edit config to enable commands, etc."
			printf "\n  \e[2mTips:\n"
			printf "    Command 'qcmds' perform operations about tool commands. Run 'qcmds -h' for more\n"
			printf "    Command 'gct' perform gct-commit step by step(need to enable 'git' commands)\n"
			printf "\e[0m"
			echo ""
			;;
		update)
			pullMessage=$(git -C $Qfig_loc pull --rebase 2>&1)
            if [[ "$pullMessage" = *"error"* || "$pullMessage" = *"fatal"* ]]; then
                logError "Cannot update Qfig:\n$pullMessage"
			elif [[ "$pullMessage" = *"up to date"* ]]; then
				logSuccess "Qfig is up to date"
			else
				logSuccess "Latest changes has been pulled"
				rezsh
				logSuccess "Qfig updated!"
			fi
			unset pullMessage
			;;
		config)
			if [ ! -f $Qfig_loc/config ]; then
				echo "# This config was copied from the 'configTemplate'\n$(tail -n +2 $Qfig_loc/configTemplate)" > $Qfig_loc/config
				logInfo "Copied config from \e[1mconfigTemplate\e[0m"
			fi
			editfile $Qfig_loc/config
			;;
		into)
			cd $Qfig_loc
			;;
		*)
			qfig help
			return 1
	esac
}

function qread() { #? use vared like read
	[ -z $1 ] && logError "Missing variable name!" && return 1
	eval "$1="
	eval "vared $1"
}

function qcmds() { #? operate available commands. syntax: qcmds commandsPrefix subcommands. -h for more
	unset help
	while getopts "h" opt; do
        case $opt in
            h)
				help=1
                ;;
            \?)
                echo "Invalid option: -$OPTARG" && return
                ;;
        esac
    done
	if [[ "$help" || -z "$1" ]]; then
		logInfo "Basic syntax: qcmds toolCommandsPrefix subcommands(optional). e.g., 'qcmds base'"
		echo "  Available Qfig tool commands(prefix): $(ls $Qfig_loc/command | perl -n -e'/(.+)Commands\.sh/ && print "$1 "')"
		echo "  Subcommands: explain(default), cat(or read), vim(or edit)"
		return
	fi

    targetFile=$Qfig_loc/command/$1Commands.sh
	if [ ! -f "$targetFile" ]; then
		if [[ "local" = $1 ]]; then
			echo "# Write your only-in-this-device commands below. This file will be ignored by .gitignore" > $targetFile
		else
			logError "$targetFile dosen't exist" && qcmds && return 1
		fi
	fi
	
	case $2 in
		cat|read)
			cat $targetFile && return
			;;
		vim|edit)
			editfile $targetFile && return
			;;	
		""|explain)
			cat $targetFile | awk '/^function /{if ($4 == "#x") next; command = "\033[1;34m" $2 "\033[0m"; printf("%-30s", command); if ($4 == "#?") printf "\033[0m:\033[0;36m "; if ($4 == "#!") printf "\033[0m:\033[1;31m ";  \
				for (i = 5; i <= NF; i++) \
					printf $i " "; \
					printf "\n";}' \
					| awk '{sub("\\(\\)", "\033[1;37m()\033[0m")} 1'
			return
			;;
		*)
			logError "Unknown subcommand: $2"
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
	qfigLog "\e[38;05;123m" $1 $2
}


function logError() {
    [ -z $1 ] && return
    #logColor "\033[30;41m" $1 
	qfigLog "\e[38;05;196m" $1 $2
}

function logWarn() {
    [ -z $1 ] && return
    #logColor "\033[30;103m" $1
	qfigLog "\e[38;05;226m" $1 $2
}

function logSuccess() {
    [ -z $1 ] && return
    #logColor "\033[30;42m" $1
	qfigLog "\e[38;05;118m" $1 $2
}

function logDebug() { #x debug
    [ -z $1 ] && return
	printf "\e[3m\e[34;100mDEBUG\e[0m \e[1;3m$1\e[0;0m\n"
}

function logSilence() {
    [ -z $1 ] && return
    #logColor "\033[30;42m" $1
	printf "\e[2m● $1\e[0m\n"
}

function qfigLog() { #x log with a colored dot prefix
    [[ -z "$1" || -z "$2" ]] && return
	[ -z "$3" ] && prefix="●" || prefix=$3
	printf "$1$prefix\e[0m $2\n"
}

function forbiddenAlias() { #x alert a alias is forbidden
	[ -z "$1" ] && return
	if [ -z "$2" ]
	then
		logWarn "Forbidden Alias. Use \e[92m$1\e[0m Instead"
	else
		logWarn "Forbidden Alias: \e[31m$1\e[0m. Use \e[92m$2\e[0m Instead"
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

function utargz() { #? decompress a tar.gz file using option -xvf
	if [ ! -f $1 ] || [ ! ${1: -7}  = ".tar.gz" ]
	then	
		logError "A tar.gz file required"
	else
		tar -xvf $1
	fi
}

function ps2port() { #? get port which listening by process id
	[ -z "$1" ] && logError "Which pid ?" && return 1
	lsof -aPi -p $1
}

function port2ps() { #? get process which listening to port
	[ -z "$1" ] && logError "Which port ?" && return 1
	lsof -nP -iTCP -sTCP:LISTEN | grep $1
}
