#!/usr/bin/env zsh
#? These commands only requires zsh built-in commands

function qfig() { #? Qfig preserved command
	case $1 in
		help)
			logInfo "Usage: qfig <command>\n\n  Available commands:\n"
			printf "    %-10s%s\n" "help" "Print this help message"
			printf "    %-10s%s\n" "update" "Update Qfig"
			printf "    %-10s%s\n" "into" "Go into Qfig project folder"
			printf "    %-10s%s\n" "config" "Edit config to enable commands, etc."
			printf "    %-10s%s\n" "im" "Show initiation message again"
			printf "\n  \e[2mTips:\n"
			printf "    Command 'qcmds' perform operations about tool commands. Run 'qcmds -h' for more\n"
			printf "    Command 'gct' perform gct-commit step by step(need to enable 'git' commands)\n"
			printf "\e[0m"
			echo ""
			;;
		update)
			pullMessage=$(git -C $Qfig_loc pull --rebase 2>&1)
            if [[ $? != 0 || "$pullMessage" = *"error"* || "$pullMessage" = *"fatal"* ]]; then
                logError "Cannot update Qfig:\n$pullMessage" && return
			elif [[ "$pullMessage" = *"up to date"* ]]; then
				logSuccess "Qfig is up to date" && return
			else
				logInfo "Updating Qfig.."
				currentHeadFile=$Qfig_loc/.gcache/currentHead
				if [ ! -f "$currentHeadFile" ]; then
					mktouch $currentHeadFile
					echo "!!!" > $currentHeadFile
				fi

				lastHead=$(cat $currentHeadFile)
				parts=(${(@s/ /)$(git -C $Qfig_loc log --oneline --decorate -1)})
				newHead=$parts[1]
				echo $newHead > $currentHeadFile
				echo "\nUpdate head \e[1m$lastHead\e[0m -> \e[1m$newHead\e[0m:\n"
				git -C $Qfig_loc log --oneline --decorate -10 | awk -v ch=$lastHead 'BEGIN{first = 1;
					tc["refactor"] = 31; tc["fix"] = 32; tc["feat"] = 33; tc["chore"] = 34; tc["doc"] = 35; tc["test"] = 36;
				} {
					if($0 ~ ch) {
						exit;
					} else {
						if (first) { first = 0}
						n = split($0, parts, ":");
						n1 = split(parts[1], parts1, " ");
						type = parts1[n1];
						c = tc[type]; if(!c) c = 37;
						printf "- [\033[1;" c "m%s\033[0m]%s\n", parts1[n1], parts[2];
					}
				} END {print ""}'
			fi
			rezsh "" "Qfig updated!"
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
		im)
			logInfo $initMsg
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
			cat $targetFile | awk '{
					if (/^\#\? /) {
						printf "\033[1;34m▍\033[39m";
						for (i = 2; i <= NF; i++) {
							printf $i " ";
						}
						printf "\033[0m\n";
					} else if (/^function /) {
						if ($4 == "#x") next;
						command = "\033[34m" $2 "\033[2m ";
						while(length(command) < 29) {
							command = command "-";
						}
						printf("%s\033[0m", command);
						if ($4 == "#?") {
							printf "\033[36m ";
						} else if ($4 == "#!") {
							printf "\033[31m ";
						} else {
							printf " ";
						}
						for (i = 5; i <= NF; i++) {
							printf $i " ";
						}
						printf "\033[0m\n";
					} else if (/^alias /) {
						# gsub("'\''", "", $2);
						split($2, parts, "=");
						printf "\033[32malias \033[34m" parts[1] "\033[39m = \033[36m" parts[2];
						for (i = 3; i <= NF; i++) {
							# gsub("'\''", "", $i);
							printf(" %s", $i);
						}
						printf "\033[0m\n";
					} else if (/^forbidAlias /) {
						printf "\033[32malias \033[31m" $2 " \033[39m=>\033[34m";
						for (i = 3; i <= NF; i++) {
							printf(" %s", $i);
						}
						printf "\033[0m\n";
					}
				}' | awk '{sub("\\(\\)", "\033[37m()\033[0m")} 1'
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
	[ -z $1 ] && logError "Which file ?" && return
	[ -d $1 ] && logError "Target is a directory !" && return
    eval "$preferTextEditor $1"
}

function qmap() { #? view or edit a map(which may be recognized by Qfig commands)
	[ -z "$1" ] && logError "Which map ?" && return 1
	editfile "$Qfig_loc/$1MappingFile"
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
#? About colorful output, refer to https://en.wikipedia.org/wiki/ANSI_escape_code#SGR

function logInfo() { #? log info
    [ -z $1 ] && return
    #logColor "\033[30;46m" $1 
	qfigLog "\e[38;05;123m" $1 $2
}


function logError() { #? log error
    [ -z $1 ] && return
    #logColor "\033[30;41m" $1 
	qfigLog "\e[38;05;196m" $1 $2
}

function logWarn() { #? log warn
    [ -z $1 ] && return
    #logColor "\033[30;103m" $1
	qfigLog "\e[38;05;226m" $1 $2
}

function logSuccess() { #? log success
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
	sgr=$1 # Select graphic rendition
	log=$2
	prefix=$3
    [[ -z "$sgr" || -z "$log" ]] && return
	[ -z "$prefix" ] && prefix="●" || prefix=$3
	
	log=${log//\%/ percent}
	log=${log//$'\r'/} # It's seem that $'\r'(ascii code 13) != \r, \r can be printed by 'zsh echo -E' but the former can not. Github push message may contiains lots of ascii code 13 in order to update state.
	log=${log//\\\r/}
	log=$(echo $log)
	log="$sgr$prefix\e[0m $log\n"

	printf $log
}

function forbidAlias() { #x forbid alias 
	[ -z "$1" ] && return
	if [ -z "$2" ]
	then
		eval "alias $1='logWarn \"Forbidden alias \\\\e[31m$1\\\\e[0m.\"'"
	elif [ -z "$3" ]
	then
		eval "alias $1='logWarn \"Forbidden alias \\\\e[31m$1\\\\e[0m, user \\\\e[92m$2\\\\e[0m instead.\"'"
	else
		eval "alias $1='logWarn \"Forbidden alias \\\\e[31m$1\\\\e[0m, user \\\\e[92m$2\\\\e[0m or \\\\e[92m$3\\\\e[0m instead.\"'"
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
    [ -z "$1" ] && logInfo "Refreshing zsh..." || logInfo "$1..."
    source ~/.zshrc
	[ -z "$2" ] && logSuccess "Refreshed zsh" || logSuccess "$2"
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

function findindex() { #? find 1st target index in provider. syntax: findindex provider target
	[[ -z $1 || -z $2 ]] && logError "Syntax: findindex provider target" && return 1
	s1len=${#1}
	s2len=${#2}
	[ $s2len -gt $s1len ] && logError "Target is longer than provider!" && return 1
	j=0
	c2=${2:$j:1}
	c2_0=$c2
	for (( i=0 ; i<$s1len; i++ )); do
		c1=${1:$i:1}	
		if [ "$c1" = "$c2" ]; then
			[ $j = 0 ] && k=$i
			j=$(($j + 1))	
			if [ $j = $s2len ]; then
				echo $k
				return
			else
				c2=${2:$j:1}
			fi
		else
			j=0
			c2=$c2_0
		fi	
	done
	return 1
}

function chr() { #? convert number[s] to ASCII character[s]
	awk '{
		split($0, chars, " ");
		for (i=1; i <= length($0); i++) {
			printf("%c", chars[i]);
		}
		printf("\n");
	}' <<< $@
}

function int() { #? convert ASCII character[s] to number[s]
	all=$@
	for (( i=0 ; i<${#all}; i++ )); do
		c=${all:$i:1}
		printf "%d " "'$c"
	done
	printf "\n"
}

function dec2hex() { #? convert decimal to hexadecimal
	[ -z $1 ] && return
	printf "%x\n" $1
}

function hex2dec() { #? convert hexadecimal to decimal
	[ -z $1 ] && return
	echo $((0x$1))
}

function uni2sp() { #? convert unicode (range [10000, 10FFFF]) to surrogate pair (range [D800, DBFF] and [DC00, DFFF])
	[ -z $1 ] && return
	if ! [[ $1 =~ '^[0-9a-fA-F]+$' ]]; then
		logWarn "$1 is not hexdecimal" && return
	fi

	if [[ 0x$1 -lt 0x10000 || 0x$1 -gt 0x10FFFF ]]; then
		logWarn "$1 is out of range [10000, 10FFFF]"
	else
		offset=$((0x$1 - 0x10000))
		row=$(($offset / 0x400))
		column=$(($offset % 0x400))
		high=$((0xD800 + $row))
		low=$((0xDC00 + $column))
		echo "$(dec2hex $high) $(dec2hex $low)"
	fi
}

function sp2uni() { #? convert surrogate pair (range [D800, DBFF] and [DC00, DFFF]) to unicode (range [10000, 10FFFF])
	[[ -z $1 || -z $2 ]] && logWarn "A surrogate pair needs 2 units" && return
	if ! [[ $1 =~ '^[0-9a-fA-F]+$' && $2 =~ '^[0-9a-fA-F]+$' ]]; then
		logWarn "$1 or $2 is not hexdecimal" && return
	fi

	if [[ 0x$1 -lt 0xD800 || 0x$1 -gt 0xDBFF ]]; then
		logWarn "1st (high-surrogate) unit $1 is out of range [D800, DBFF]" && return
	fi
	if [[ 0x$2 -lt 0xDC00 || 0x$2 -gt 0xDFFF ]]; then
		logWarn "2nd (low-surrogate) unit $2 is out of range [DC00, DFFF]" && return
	fi

	highOffset=$((0x$1 - 0xD800))
	lowOffset=$((0x$2 - 0xDC00))
	uni=$(($highOffset * 1024 + $lowOffset + 0x10000))
	echo $(dec2hex $uni)
}