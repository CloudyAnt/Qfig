#? These commands only requires zsh built-in commands

## these commands with '_' prefix weren't designed to be shown by 'qcmds' or to be used directly (though you can)
function _getArrayBase() { #x
	if [[ -o ksharrays ]] 2>/dev/null; then
		echo 0
	elif [[ "$_CURRENT_SHELL" = "zsh" ]]; then # Besides, fish is the same
		echo 1
	else
		echo 0
	fi
}

function _getCurrentHead() { #x
	declare -i arrayBase=$(_getArrayBase)
	local parts=($(echo $(git -C $_QFIG_LOC log --oneline --decorate -1)))
	echo ${parts[$arrayBase]} # dash doesn't support such grammar
}

function _readTemp() { #x
	_TEMP=
	if [[ "$_CURRENT_SHELL" = "zsh" ]]; then
		vared _TEMP
	else
		read _TEMP
	fi
}

function _alignLeft() { #x
	[[ -z "$1" || -z "$2" || -z "$3" ]] && return
	declare -i len=$3
	local s=$1
	while [ ${#s} -lt $len ]; do
		s="$2$s"
	done
	echo $s
}

function echoe() { #? echo with escapes
	[ -z "$1" ] && return 0 || :
	if [[ "$_CURRENT_SHELL" = "zsh" ]]; then # csh, tcsh, etc. are the same
		echo "$1"
	else
		echo -e "$1"
	fi
}

function md5x() { #? same as md5 in zsh, optimized md5sum of bash
	local str
	read str
	if [ "$_IS_BSD" ]; then
		echo -n $str | md5
	else
		local sum=($(echo -n $str | md5sum))
		echo ${sum[0]}
	fi
}

function _rmCr() { #x
	while IFS= read -r str; do
        echo "${str//$'\r'/}"
    done
	rdIFS
}

function qfig() { #? Qfig preserved command
	case $1 in
		-h|help)
			logInfo "Usage: qfig <command>\n\n  Available commands:\n"
			printf "    %-10s%s\n" "help" "Print this help message"
			printf "    %-10s%s\n" "update" "Update Qfig"
			printf "    %-10s%s\n" "into" "Go into Qfig project folder"
			printf "    %-10s%s\n" "config" "Edit config to enable commands, etc."
			printf "    %-10s%s\n" "report" "Show initiation message, and current shell/terminal info."
			printf "    %-10s%s\n" "v/version" "Show current version"
			printf "\n  \e[2mTips:\n"
			printf "    Command 'qcmds' perform operations about tool commands. Run 'qcmds -h' for more\n"
			printf "    Command 'gct' perform gct-commit step by step(need to enable 'git' commands)\n"
			printf "\e[0m"
			echo ""
			;;
		update)
			local curHead=$(_getCurrentHead)
			local pullMessage=$(git -C $_QFIG_LOC pull --rebase 2>&1)
            if [[ $? != 0 || "$pullMessage" = *"error"* || "$pullMessage" = *"fatal"* ]]; then
                logError "Cannot update Qfig:\n$pullMessage" && return
			elif [[ "$pullMessage" = *"Already up to date."* ]]; then
				logSuccess "Qfig is already up to date" && return
			else
				logInfo "Updating Qfig.."
				local newHead=$(_getCurrentHead)
				echoe "\nUpdate head \e[1m$curHead\e[0m -> \e[1m$newHead\e[0m:\n"
				git -C $_QFIG_LOC log --oneline --decorate -10 | awk -v ch=$curHead 'BEGIN{
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
			resh - "Qfig updated!"
			;;
		config)
			if [ ! -f $_QFIG_LOC/config ]; then
				echoe "# This config was copied from the 'configTemplate'\n$(tail -n +2 $_QFIG_LOC/configTemplate)" > $_QFIG_LOC/config
				logInfo "Copied config from \e[1mconfigTemplate\e[0m"
			fi
			editfile $_QFIG_LOC/config
			;;
		into)
			cd $_QFIG_LOC
			;;
		report)
			local msg="$_INIT_MSG\n  OsType: $OSTYPE. Simulator: $TERM. Shell: $_CURRENT_SHELL"
			logInfo "$msg"
			;;
		v|version)
			local curHead=$(_getCurrentHead)
			local branch=$(git -C $_QFIG_LOC symbolic-ref --short HEAD)
			echo "$branch ($curHead)"
			;;
		*)
			qfig help
			return 1
	esac
}

function qcmds() { #? operate available commands. Usage: qcmds $commandsPrefix $subcommands. -h for more
	local help
	OPTIND=1
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
		echo "  Available Qfig tool commands(prefix): $(ls $_QFIG_LOC/command | perl -n -e'/(.+)Commands\.sh/ && print "$1 "')"
		echo "  Subcommands: explain(default), cat(or read), vim(or edit)"
		return
	fi

    local targetFile=$_QFIG_LOC/command/$1Commands.sh
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
					if (/^#\? /) {
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
	editfile "$_QFIG_LOC/$1MappingFile"
}

### Log
#? About colorful output, refer to https://en.wikipedia.org/wiki/ANSI_escape_code#SGR

function logInfo() { #? log info
    [ -z "$1" ] && return
    #logColor "\033[30;46m" $1
	qfigLog "\e[38;05;123m" "$1" "$2"
}


function logError() { #? log error message
    [ -z "$1" ] && return
    #logColor "\033[30;41m" $1 
	qfigLog "\e[38;05;196m" "$1" "$2"
}

function logWarn() { #? log warning message
    [ -z "$1" ] && return
    #logColor "\033[30;103m" $1
	qfigLog "\e[38;05;226m" "$1" "$2"
}

function logSuccess() { #? log success message
    [ -z "$1" ] && return
    #logColor "\033[30;42m" $1
	qfigLog "\e[38;05;118m" "$1" "$2"
}

function logDebug() { #x debug
    [ -z "$1" ] && return
	printf "\e[3m\e[34;100mDEBUG\e[0m \e[1;3m$1\e[0;0m\n"
}

Qfig_log_prefix="●"
function logSilence() { #? log unconspicuous message
    [ -z "$1" ] && return
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
	# whatever a true LF (unicode d) or LF escape sequence "\r" (unicode 5c and 72) should be remove here
	log=${log//$'\r'/} 
	log=${log//\\\r/}
	log="$sgr$prefix\e[0m $log\n"

	printf "$log"
}

function forbidAlias() { #x forbid alias 
	[ -z "$1" ] && return || :
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
	[ -z "$1" ] && return || :
	unalias $1 2>/dev/null
}

### 

function mktouch() { #? make dirs & touch file
    [ -z "$1" ] && return
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

function resh() { #? re-source .zshrc/.bashrc
	[[ -o ksharrays ]] && local ksharrays=1 || local ksharrays=""
	# If ksharrays was set, arrays would based on 0, array items can only be accessed like '${arr[1]}' not '$arr[1]',
	# array size can only be accesse like '${#arr[@]}' not '${#arr}'. Some programs may not expect this option
	[ $ksharrays ] && set +o ksharrays || :

	if [ ! "-" = "$1" ]; then
		[ -z "$1" ] && logInfo "Refreshing $_CURRENT_SHELL..." || logInfo "$1..."
	fi
	# unset all alias
	unalias -a
	# unset all functions
	if [ $_CURRENT_SHELL = "zsh" ]; then
		unset -f -m '*'
	elif [[ $_CURRENT_SHELL = "bash" && ! "$OSTYPE" = "msys" ]]; then # msys = Git Bash, some functions in it should not be unset
		for f in $(declare -F -p | cut -d " " -f 3); do unset -f $f; done
	fi
    source "$HOME/.${_CURRENT_SHELL}rc"
	[ -z "$2" ] && logSuccess "Refreshed $_CURRENT_SHELL" || logSuccess "$2"

	[ $ksharrays ] && set -o ksharrays || :
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
	[ -z "$1" ] && return
	local hexes
	hexes=($(echo $(chr2hex "$1")))
	for hex in "${hexes[@]}"; do
		hex=$(_alignLeft $hex 0 4)
		printf "\\\u$hex"
	done
	printf "\n"
}

function chr2uni8() { #? convert characters to unicodes(4 digits with '\u' prefix or 8 digits with '\U' prefix)
	[ -z "$1" ] && return
	local hexes lps
	hexes=($(echo $(chr2hex "$1")))
	for hex in "${hexes[@]}"; do
		if [ $lps ]; then
			if [[ 0x$hex -ge 0xDC00 && 0x$hex -le 0xDFFF ]]; then
				hex=$(sp2uni $lps $hex)
				hex=$(_alignLeft $hex 0 8)
				printf "\\\U$hex"
			else
				printf "\\\u$lps\\\u$hex"
			fi
			lps=""
		elif [[ 0x$hex -ge 0xD800 && 0x$hex -le 0xDBFF ]]; then
			lps="$hex"
		elif [ ${#hex} -gt 4 ]; then
			hex=$(_alignLeft $hex 0 8)
			printf "\\\U$hex"
		else
			hex=$(_alignLeft $hex 0 4)
			printf "\\\u$hex"
		fi
		printf "\n"
	done
}

#? 'echo' convert '\u' or '\U' prefixed hexdecimals to chars, makes a function 'unicode2char' unnecessary

function hex2chr() { #? convert hex unicode code points to characters
	declare -i codesCount=0;
	declare -i charsCount=0;
	local ls=""
	local err=""
	local arg
	for arg in "$@"
	do
		codesCount=$((codesCount + 1))
		if ! [[ $arg =~ ^[0-9a-fA-F]+$ ]]; then
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
	[ -z "$1" ] && return
	local all c i
	all=$@
	for (( i=0 ; i<${#all}; i++ )); do
		c=${all:$i:1}
		printf "%x " "'$c"
	done
	printf "\n"
}

function dec2hex() { #? convert decimals to hexadecimals
	local arg
	declare -i index=1
	local out=""
	for arg in "$@"
	do
		if ! [[ $arg =~ ^[0-9]+$ ]]; then
			logError $index"th param '$arg' is not decimal" && return 1
		fi
		[ $index -eq 1 ] && out=$out$(printf "%x" $arg) || out=$out$(printf " %x" $arg)
		index=$((index + 1))
	done
	if [ $index -gt 1 ]; then
		printf "$out\n"
	fi
}

function hex2dec() { #? convert hex unicode code points to decimals
	local arg
	declare -i index=1
	local out=""
	for arg in "$@"
	do
		if ! [[ $arg =~ ^[0-9a-fA-F]+$ ]]; then
			logWarn $index"th param '$arg' is not hexdecimal" && return 1
		fi
		out=$out"$((0x$arg)) "
		index=$((index + 1))
	done
	if [ $index -gt 0 ]; then
		printf "$out\n"
	fi
}

function uni2sp() { #? convert 1 unicode (range [10000, 10FFFF]) to surrogate pair (range [D800, DBFF] and [DC00, DFFF])
	[ -z "$1" ] && return
	if ! [[ $1 =~ ^[0-9a-fA-F]+$ ]]; then
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

function sp2uni() { #? convert 1 surrogate pair (range [D800, DBFF] and [DC00, DFFF]) to unicode (range [10000, 10FFFF])
	[[ -z $1 || -z $2 ]] && logWarn "A surrogate pair needs 2 units" && return
	if ! [[ $1 =~ ^[0-9a-fA-F]+$ && $2 =~ ^[0-9a-fA-F]+$ ]]; then
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
		echoe "  \e[34m\$meta\e[0m pattern: \e[1m-joiner-start-end (exclusive)\e[0m. The first char is the separator of meta, here it's '-' (recommanded).
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
			declare -i arrayBase=$(_getArrayBase)
			start=${metas[$(($arrayBase + 2))]}
			if [ -z $start ]; then
				start=2
			elif [[ ! $start =~ ^[0-9]+$ ]]; then
				logError "Start must be a decimal" && return 1
			else
				start=$((start + 2))
			fi

			end=${metas[$(($arrayBase + 3))]}
			if [ -z $end ]; then
				end=$maxEnd
			elif [[ ! $end =~ ^[0-9]+$ ]]; then
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

__IFS__=$(hex2chr 20 9 a)
function rdIFS() { #? restore to default IFS
	IFS=$__IFS__
}

function confirm() { #? ask for confirmation. Usage: confirm $flags(optional) $msg(optional), -h for more
	local type="N" # N=normal, W=warning
	local enterForYes=""
	local prefix=""
	OPTIND=1
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
		[ -z "$prefix" ] && prefix="!" || :
		logWarn "$message \e[90mInput yes/Yes to confirm.\e[0m" $prefix
		_readTemp && yn=$_TEMP || return 1
		if [[ 'yes' = "$yn" || 'Yes' = "$yn" ]]; then
			return 0
		fi
	else
		if [[ $enterForYes ]]; then
			logInfo "$message \e[90mPress Enter or Input y/Y for Yes, others for No.\e[0m" $prefix
		else
			logInfo "$message \e[90mInput y/Y for Yes, others for No.\e[0m" $prefix
		fi
		_readTemp && yn=$_TEMP || return 1
		if [[ 'Y' = "$yn" || 'y' = "$yn" || 'yes' = "$yn" || 'Yes' = "$yn" ]] || [[ $enterForYes && -z "$yn" ]]; then
			return 0
		fi
	fi
	return 1
}

function _getStringWidth() { #x
	if [[ $_CURRENT_SHELL = "zsh" ]]; then
		echo $(($#1 * 3 - ${#${(ml[$#1 * 2])1}})) # zsh can use this method to get width faster
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

function hex2utf8() { #? covert unicode code points to utf8 code units, -s to add space between bytes
	local arg out part bytesInterval
	declare -i index=1
	if [ "-s" = "$1" ]; then
		bytesInterval=" "
		shift 1
	fi
	declare -i uni
	for arg in "$@"
	do
		if ! [[ $arg =~ ^[0-9a-fA-F]+$ ]]; then
			logError $index"th param '$arg' is not decimal" && return 1
		fi
		uni=0x$arg
		[ $index -eq 1 ] && part="" || part=" "
		if [[ 0x$arg -le 0xF ]]; then
			part="${part}0$arg"
		elif [[ 0x$arg -le 0x7F ]]; then
			part="$part$arg"
		elif [[ 0x$arg -le 0x7FF ]]; then
			part="$part$(dec2hex $((0xC0 + ($uni >> 6))))$bytesInterval"
			part="$part$(dec2hex $((0x80 + ($uni & 0x3F))))"
		elif [[ 0x$arg -le 0xFFFF ]]; then
			part="$part$(dec2hex $((0xE0 + ($uni >> 12))))$bytesInterval"
			part="$part$(dec2hex $((0x80 + ($uni >> 6 & 0x3F))))$bytesInterval"
			part="$part$(dec2hex $((0x80 + ($uni & 0x3F))))"
		elif [[ 0x$arg -le 0x10FFFF ]]; then
			part="$part$(dec2hex $((0xE0 + ($uni >> 18))))$bytesInterval"
			part="$part$(dec2hex $((0x80 + ($uni >> 12 & 0x3F))))$bytesInterval"
			part="$part$(dec2hex $((0x80 + ($uni >> 6 & 0x3F))))$bytesInterval"
			part="$part$(dec2hex $((0x80 + ($uni & 0x3F))))"
		else
			logError $index"th param '$arg' is out of range" && return 1
		fi
		out=$out$part
		index=$((index + 1))
	done
	echo $out
}

function hex2utf16() { #? covert hex unicode code points to utf16 code units, -h for more
	local bytesInterval le opt
	OPTIND=1
	while getopts ":hsl" opt; do
        case $opt in
			h)
				logInfo "Usage: confirm \$flags(optional) \$msg(optional).\n  Flags:\n"
				printf "    %-5s%s\n" "h" "Print this help message"
				printf "    %-5s%s\n" "s" "Add spaces between bytes"
				printf "    %-5s%s\n" "l" "Change to litte endian"
				return 0
				;;
            s)
				bytesInterval=" "
                ;;
			l)
				le=1
				;;
            \?)
                echo "Invalid option: -$OPTARG" && return
                ;;
        esac
    done
	shift "$((OPTIND - 1))"

	local arg out prefix byte1 byte2 sp
	declare -i index=1
	declare -i byteIndex=1
	declare -i uni
	declare -i arrayBase=$(_getArrayBase)

	function _process() {
		[ $byteIndex -eq 1 ] && prefix="" || prefix=" "
		byte1=$(dec2hex $(($uni >> 8)))
		byte2=$(dec2hex $(($uni & 0xFF)))
		[[ 0x$byte1 -le 0xF ]] && byte1="0$byte1" || :
		[[ 0x$byte2 -le 0xF ]] && byte2="0$byte2" || :
		[ $le ] && out+="$prefix$byte2$bytesInterval$byte1" || out+="$prefix$byte1$bytesInterval$byte2"
	}

	for arg in "$@"
	do
		if ! [[ $arg =~ ^[0-9a-fA-F]+$ ]]; then
			logError $index"th param '$arg' is not decimal" && unset -f _process && return 1
		fi

		if [[ 0x$arg -le 0xFFFF ]]; then
			uni=0x$arg
			_process
			byteIndex=$((byteIndex + 1))
		elif [[ 0x$arg -le 0x10FFFF ]]; then
			sp=($(echo $(uni2sp $arg)))
			uni=0x${sp[$arrayBase]}
			_process
			byteIndex=$((byteIndex + 1))

			uni=0x${sp[$((arrayBase + 1))]}
			_process
			byteIndex=$((byteIndex + 1))
		else
			logError $index"th param '$arg' is out of range" && unset -f _process && return 1
		fi
		index=$((index + 1))
	done
	unset -f _process
	echo $out
}

function enurlp() { #? encode url param.
	[ -z "$1" ] && return
	local all c hex out
	all=$@
	for (( i=0 ; i<${#all}; i++ )); do
		c=${all:$i:1}
		hex=$(printf "%x" "'$c")
		if [[ 0x$hex -eq 0x20 ]]; then
			out=$out%20
		elif [[ 0x$hex -ge 0x41 && 0x$hex -le 0x5A ]] || [[ 0x$hex -ge 0x61 && 0x$hex -le 0x7a ]] \
		|| [[ 0x$hex -ge 0x30 && 0x$hex -le 0x39 ]] \
		|| [[ 0x$hex -eq 0x2A || 0x$hex -eq 0x2D || 0x$hex -eq 0x2E || 0x$hex -eq 0x5F ]]; then
			out=$out$c
		else
			local bytes=($(echo $(hex2utf8 -s $hex)))
			for byte in "${bytes[@]}"; do
				out="$out%$byte"
			done
		fi
	done
	echo $out
}	