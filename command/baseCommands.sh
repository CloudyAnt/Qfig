#!/usr/bin/env zsh
#? These commands only requires zsh built-in commands

Qfig_log_prefix="●"

function _doNothing() { #x
}

function qfig() { #? Qfig preserved command
	case $1 in
		-h|help)
			logInfo "Usage: qfig <command>\n\n  Available commands:\n"
			printf "    %-10s%s\n" "help" "Print this help message"
			printf "    %-10s%s\n" "update" "Update Qfig"
			printf "    %-10s%s\n" "into" "Go into Qfig project folder"
			printf "    %-10s%s\n" "config" "Edit config to enable commands, etc."
			printf "    %-10s%s\n" "im" "Show initiation message again"
			printf "    %-10s%s\n" "v/version" "Show current version"
			printf "\n  \e[2mTips:\n"
			printf "    Command 'qcmds' perform operations about tool commands. Run 'qcmds -h' for more\n"
			printf "    Command 'gct' perform gct-commit step by step(need to enable 'git' commands)\n"
			printf "\e[0m"
			echo ""
			;;
		update)
			local parts=(${(@s/ /)$(git -C $Qfig_loc log --oneline --decorate -1)})
			local curHead=$parts[1]

			local pullMessage=$(git -C $Qfig_loc pull --rebase 2>&1)
            if [[ $? != 0 || "$pullMessage" = *"error"* || "$pullMessage" = *"fatal"* ]]; then
                logError "Cannot update Qfig:\n$pullMessage" && return
			elif [[ "$pullMessage" = *"Already up to date."* ]]; then
				logSuccess "Qfig is already up to date" && return
			else
				logInfo "Updating Qfig.."
				local parts=(${(@s/ /)$(git -C $Qfig_loc log --oneline --decorate -1)})
				local newHead=$parts[1]
				echo "\nUpdate head \e[1m$curHead\e[0m -> \e[1m$newHead\e[0m:\n"
				git -C $Qfig_loc log --oneline --decorate -10 | awk -v ch=$curHead 'BEGIN{
					tc["refactor"] = 31; tc["fix"] = 32; tc["feat"] = 33; tc["chore"] = 34; tc["doc"] = 35; tc["test"] = 36;
				} {
					if($0 ~ ch) {
						exit;
					} else {
						n = split($0, parts, ":");
						n1 = split(parts[1], parts1, " ");
						type = parts1[n1];
						c = tc[type]; if(!c) c = 37;
						printf "- [\033[1;" c "m%s\033[0m]%s\n", parts1[n1], parts[2];
					}
				} END {print ""}'
			fi
			rezsh - "Qfig updated!"
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
		v|version)
			local parts=(${(@s/ /)$(git -C $Qfig_loc log --oneline --decorate -1)})
			local curHead=$parts[1]
			local branch=$(git -C $Qfig_loc symbolic-ref --short HEAD)
			echo "$branch($curHead)"
			;;
		*)
			qfig help
			return 1
	esac
}

function qcmds() { #? operate available commands. Usage: qcmds $commandsPrefix $subcommands. -h for more
	local help
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
		logInfo "Usage: qcmds \$toolCommandsPrefix \$subcommands(optional). e.g., 'qcmds base'"
		echo "  Available Qfig tool commands(prefix): $(ls $Qfig_loc/command | perl -n -e'/(.+)Commands\.sh/ && print "$1 "')"
		echo "  Subcommands: explain(default), cat(or read), vim(or edit)"
		return
	fi

    local targetFile=$Qfig_loc/command/$1Commands.sh
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
						printf "\033[34m▍\033[39m";
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
    local value_name=$1
    local default_value=$2

    [ -z "$value_name" ] && return

    eval "local real_value=\$$value_name"

    [ -z "$real_value" ] && eval "$value_name='$default_value'"
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


function logError() { #? log error message
    [ -z $1 ] && return
    #logColor "\033[30;41m" $1 
	qfigLog "\e[38;05;196m" $1 $2
}

function logWarn() { #? log warning message
    [ -z $1 ] && return
    #logColor "\033[30;103m" $1
	qfigLog "\e[38;05;226m" $1 $2
}

function logSuccess() { #? log success message
    [ -z $1 ] && return
    #logColor "\033[30;42m" $1
	qfigLog "\e[38;05;118m" $1 $2
}

function logDebug() { #x debug
    [ -z $1 ] && return
	printf "\e[3m\e[34;100mDEBUG\e[0m \e[1;3m$1\e[0;0m\n"
}

function logSilence() { #? log unconspicuous message
    [ -z $1 ] && return
    #logColor "\033[30;42m" $1
	printf "\e[2m$Qfig_log_prefix $1\e[0m\n"
}

function qfigLog() { #x log with a colored dot prefix
	local sgr=$1 # Select graphic rendition
	local log=$2
	local prefix=$3
    [[ -z "$sgr" || -z "$log" ]] && return
	[ -z "$prefix" ] && prefix="$Qfig_log_prefix" || prefix=$3
	
	log=${log//\%/ percent}
	log=${log//$'\r'/} # It's seem that $'\r'(ANSI-C Quoting) != \r, \r can be printed by 'zsh echo -E' but the former can not. Github push message may contiains lots of $'\r' in order to update state.
	log=${log//\\\r/}
	log=$(echo $log)
	log="$sgr$prefix\e[0m $log\n"

	printf $log
}

function forbidAlias() { #x forbid alias 
	[ -z "$1" ] && return || _doNothing
	unsetAlias $1
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

function unsetAlias() { #x unset alias
	[ -z "$1" ] && return || _doNothing
	unalias $1 2>/dev/null
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
	local file
    for file in "$@"
    do
        [ ! -f "$file" ] && logError "Missing file: $file" && return
    done
    echo "checked"
}

function rezsh() { #? source .zshrc
	[[ -o ksharrays ]] && local ksharrays=1
	# If ksharrays was set, arrays would based on 0, array items can only be accessed like '${arr[1]}' not '$arr[1]',
	# array size can only be accesse like '${#arr[@]}' not '${#arr}'. Some programs may not expect this option
	set +o ksharrays

	if [ ! "-" = "$1" ]; then
		[ -z "$1" ] && logInfo "Refreshing zsh..." || logInfo "$1..."
	fi
	# unset all alias
	unalias -a
	# unset all functions
	unset -f -m '*'
    source ~/.zshrc
	[ -z "$2" ] && logSuccess "Refreshed zsh" || logSuccess "$2"

	[ $ksharrays ] && set -o ksharrays || _doNothing
}

function targz() { #? compress folder to tar.gz using option -czvf
	[ ! -d $1 ] && logError "Folder required" && return 
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

function findindex() { #? find 1st target index in provider. Usage: findindex provider target
	[[ -z $1 || -z $2 ]] && logError "Usage: findindex provider target" && return 1
	local s1len=${#1}
	local s2len=${#2}
	[ $s2len -gt $s1len ] && logError "Target is longer than provider!" && return 1
	local j=0
	local c2=${2:$j:1}
	local c2_0=$c2
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

function chr2uni() { #? convert characters to unicodes(4 digits with '\u' prefix)
	local all c
	all=$@
	for (( i=0 ; i<${#all}; i++ )); do
		c=${all:$i:1}
		local hex=$(printf "%x" "'$c")
		declare -a codes
		codes=($(uni2sp $hex -p))
		for code in $codes; do
			while [ ${#code} -lt 4 ]; do
				code="0$code"
			done
			printf "\\\u$code"
		done
	done
	printf "\n"
}

function chr2uni8() { #? convert characters to unicodes(4 digits with '\u' prefix or 8 digits with '\U' prefix)
	local all c
	all=$@
	for (( i=0 ; i<${#all}; i++ )); do
		c=${all:$i:1}
		local code=$(printf "%x" "'$c")
		if [ ${#code} -gt 4 ]; then
			while [ ${#code} -lt 8 ]; do
				code="0$code"
			done
			printf "\\\U$code"
		else
			while [ ${#code} -lt 4 ]; do
				code="0$code"
			done
			printf "\\\u$code"
		fi
	done
	printf "\n"
}

#? 'echo' convert '\u' or '\U' prefixed hexdecimals to chars, makes a function 'unicode2char' unnecessary

function hex2chr() { #? convert unicodes(hex codepoint) to characters
	declare -i codesCount=0;
	declare -i charsCount=0;
	local ls=""
	local err=""
	local arg
	for arg in "$@"
	do
		codesCount=$((codesCount + 1))
		if ! [[ $arg =~ '^[0-9a-fA-F]+$' ]]; then
			err="The $codesCount""th arg '$arg' is not hexdecimal" && break
			break
		elif [[ 0x$arg -lt 0x0 || 0x$arg -gt 0x10FFFF ]]; then
			err="The $codesCount""th arg '$arg' is out of range [0, 10FFFF]" && break
		elif [ $ls ]; then
			if [[ 0x$arg -lt 0xDC00 || 0x$arg -gt 0xDFFF ]]; then
				err="The $codesCount""th unicode is not a trailing surrogate, while the previous arg $ls is a leading surrogate" && break
			fi
			local uni=$(sp2uni $ls $arg)
			printf "\U$uni"
			charsCount=$((charsCount + 1))
			ls=""
		elif [[ 0x$arg -ge 0xD800 && 0x$arg -le 0xDBFF ]]; then
			ls=$arg
		elif [[ 0x$arg -ge 0xDC00 && 0x$arg -le 0xDFFF ]]; then
			err="The $codesCount""th unicode is a trailing surrogate, however is was not followed by a leading surrogate" && break
		elif [ ${#arg} -gt 4 ]; then
			if [ ${#arg} -gt 8 ]; then
				arg=${arg:$((${#arg} - 8))}
			fi
			printf "\U$arg"
			charsCount=$((charsCount + 1))
		else
			printf "\u$arg"
			charsCount=$((charsCount + 1))
		fi
	done
	[ $charsCount -gt 0 ] && printf "\n"
	if [ $err ]; then
		logError $err
		return 1
	fi
}

function chr2hex() { #? convert characters to unicodes(hex codepoint)
	local all c
	all=$@
	for (( i=0 ; i<${#all}; i++ )); do
		c=${all:$i:1}
		printf "%x " "'$c"
	done
	printf "\n"
}

function dec2hex() { #? convert decimal to hexadecimal
	local arg
	declare -i index=1
	local out=""
	for arg in "$@"
	do
		if ! [[ $arg =~ '^[0-9]+$' ]]; then
			logError $index"th param '$arg' is not decimal" && return 1
		fi
		out=$out$(printf "%x " $arg)
		index=$((index + 1))
	done
	if [ $index -gt 1 ]; then
		printf "$out\n"
	fi
}

function hex2dec() { #? convert hexadecimal to decimal
	local arg
	declare -i index=1
	local out=""
	for arg in "$@"
	do
		if ! [[ $arg =~ '^[0-9a-fA-F]+$' ]]; then
			logWarn $index"th param '$arg' is not hexdecimal" && return 1
		fi
		out=$out"$((0x$arg)) "
		index=$((index + 1))
	done
	if [ $index -gt 0 ]; then
		printf "$out\n"
	fi
}

function uni2sp() { #? convert unicode (range [10000, 10FFFF]) to surrogate pair (range [D800, DBFF] and [DC00, DFFF])
	[ -z $1 ] && return
	if ! [[ $1 =~ '^[0-9a-fA-F]+$' ]]; then
		logWarn "$1 is not hexdecimal" && return
	fi

	if [[ 0x$1 -lt 0x10000 || 0x$1 -gt 0x10FFFF ]]; then
		if [ '-p' = $2 ]; then # print when out of range
			echo $1
		else
			logWarn "$1 is out of range [10000, 10FFFF]"
		fi
	else
		local offset row column high low
		offset=$((0x$1 - 0x10000))
		row=$(($offset / 0x400))
		column=$(($offset % 0x400))
		high=$((0xD800 + $row))
		low=$((0xDC00 + $column))
		dec2hex $high $low
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

	local highOffset lowOffset uni
	highOffset=$((0x$1 - 0xD800))
	lowOffset=$((0x$2 - 0xDC00))
	uni=$(($highOffset * 1024 + $lowOffset + 0x10000))
	dec2hex $uni
}

function concat() { #? concat array. Usage: concat $meta $item1 $item2 $item3... -h for more
	if [ "-h" = "$1" ]; then
		logInfo "Usage: concat \$meta \$item1 \$item2 \$item3.... "
		echo "  \e[34m\$meta\e[0m pattern: \e[1m-joiner-start-end (exclusive)\e[0m. The first char is the separator of meta, here it's '-' (recommanded).
  Start and end are optional. 
  \e[34m\$meta\e[0m could also be a single character \$c, it equivalent to -\$c or joiner
  Examples: 
    \e[1mconcat -,-1-4 \${arr[@]}\e[0m (concat items of index 1, 2, 3 use joiner ',')
    \e[1mconcat \"|\\\|2\" a b c...\e[0m (concat all items after index 2 use joiner '\')
    \e[1mconcat , a b c...\e[0m (concat all items use joiner ',')"
		return
	fi
	[ -z "$1" ] && concat -h && return 1
	[ -z "$2" ] && return

	local joiner
	local start
	local end
	local maxEnd=$((${#@} + 1))
	if [ 1 -eq ${#1} ]; then
		joiner=$1
		start=2 # array start from the 2nd param
		end=$maxEnd # array end at (length() + 1)
	else
		local metaSeparator=${1:0:1}
		IFS=$metaSeparator local metas=($(echo $1)); IFS=' '

		if [ ${#metas[@]} -lt 1 ]; then
			logError "Meta must have at least 1 parts (joiner)" && return 1
		else
			[[ -o ksharrays ]] && local arrayBase=0 || local arrayBase=1
			start=${metas[$(($arrayBase + 2))]}
			if [ -z $start ]; then
				start=2
			elif [[ ! $start =~ "^[0-9]+$" ]]; then
				logError "Start must be a decimal" && return 1
			else
				start=$((start + 2))
			fi

			end=${metas[$(($arrayBase + 3))]}
			if [ -z $end ]; then
				end=$maxEnd
			elif [[ ! $end =~ "^[0-9]+$" ]]; then
				logError "End must be a decimal" && return 1
			else
				end=$((end + 2))
				if [ $end -gt $maxEnd ]; then
					end=$maxEnd
				fi
			fi
		fi
		joiner=${metas[$(($arrayBase + 1))]}
	fi

	if [ '\' = "$joiner" ]; then
		joiner='\\'
	fi

	local firstSet=""
	local i
	for (( i=$start ; i<$end; i++ )); do
		local item=${@:$i:1}
		if [ $firstSet ]; then
			printf "$joiner$item"
		else
			firstSet=1
			printf "$item"
		fi
	done
	printf "\n"
}

function rdIFS() { #? restore to default IFS $' \t\n'
	IFS=$' \t\n'
}

function confirm() { #? ask for confirmation. Usage: confirm $flags(optional) $msg(optional), -h for more
	local type="N" # N=normal, W=warning
	local enterForYes=""
	local prefix=""
	while getopts ":hwep:" opt; do
        case $opt in
			h)
				logInfo "Usage: confirm \$flags(optional) \$msg(optional).\n  Flags:\n"
				printf "    %-5s%s\n" "h" "Print this help message"
				printf "    %-5s%s\n" "w" "Raise to warning level"
				printf "    %-5s%s\n" "e" "Treat Enter as yes when it's normal level"
				printf "    %-5s%s\n" "p:" "Specific the prefix. default is $Qfig_log_prefix"
				return 0
				;;
            w)
				type="W"
                ;;
			e)
				enterForYes="1"
				;;
			p)
				prefix=$OPTARG
				;;
			:)
                ;;
			\?)
				;;
        esac
    done
	shift "$((OPTIND - 1))"

	local message
	[[ -z "$1" ]] && message="Are you sure ?" || message=$1
	local yn="";
	if [ "W" = "$type" ]; then
		[ -z "$prefix" ] && prefix="!" || _doNothing
		logWarn "$message \e[90mInput yes/Yes to confirm.\e[0m" $prefix
		vared yn
		if [[ 'yes' = "$yn" || 'Yes' = "$yn" ]]; then
			return 0
		fi
	else
		if [[ $enterForYes ]]; then
			logInfo "$message \e[90mPress Enter or Input y/Y for Yes, others for No.\e[0m" $prefix
		else
			logInfo "$message \e[90mInput y/Y for Yes, others for No.\e[0m" $prefix
		fi
		vared yn
		if [[ 'Y' = "$yn" || 'y' = "$yn" || 'yes' = "$yn" || 'Yes' = "$yn" ]] || [[ $enterForYes && -z "$yn" ]]; then
			return 0
		fi
	fi
	return 1
}

function _getStringWidth() { #x
	if [[ $_CURRENT_SHELL =~ ^.*zsh$ ]]; then
		echo $(($#1 * 3 - ${#${(ml[$#1 * 2])1}})) # zsh has this method to get width faster
		return
	fi

	declare -i width unicode
	width=0
	local all c i
	all=$@
	for (( i=0 ; i<${#all}; i++ )); do
		c=${all:$i:1}
		unicode="0x$(printf "%x" "'$c")"

		if [[ $unicode -ge 0x0020 && $unicode -le 0x007E ]] || [[ $unicode -ge 0xFF61 && $unicode -le 0xFF9F ]]; then
            # half-width
            width=$((width + 1))
        elif [[ $unicode -ge 0x4E00 && $unicode -le 0x9FFF ]] || [[ $unicode -ge 0x3040 && $unicode -le 0x309F ]] || \
            [[ $unicode -ge 0x30A0 && $unicode -le 0x30FF ]] || [[ $unicode -ge 0xFF01 && $unicode -le 0xFF5E ]]; then
            # full-width
            width=$((width + 2))
        else
            # others
            width=$((width + 2))
        fi
	done
	echo $width
}