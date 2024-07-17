#? Basic support of Qfig. String related commands are here.
#? These commands only requires sh built-in commands.

# This function is the first to be loaded, so that Qfig can always be reloaded in current session
function refresh-qfig() { #? refresh qfig by re-source init.sh
	[[ -o ksharrays ]] && local ksharrays=1 || local ksharrays=""
	# If ksharrays was set, arrays would based on 0, array items can only be accessed like '${arr[1]}' not '$arr[1]',
	# array size can only be accesse like '${#arr[@]}' not '${#arr}'. Some programs may not expect this option
	[ $ksharrays ] && set +o ksharrays || :

	if [ ! "-" = "$1" ]; then
		[ -z "$1" ] && logInfo "Refreshing qfig.." || logInfo "$1..."
	fi
	local cleanFuncs="" # some system (like msys) contains builtin functions that should not be clean
	if [ $cleanFuncs ]; then
		# unset all alias
		unalias -a
		# unset all functions
		declare -a allFunctions
		if [ $_CURRENT_SHELL = "zsh" ]; then
			allFunctions=${(ok)functions}
		elif [[ $_CURRENT_SHELL = "bash" ]]; then
			allFunctions=$(declare -F | awk '{print $3}')
		fi
		for fn in $allFunctions; do
			if [[ $fn != _* ]]; then # unset all function not prefixed with '_', there are many in git bash
				unset -f $fn
			fi
		done
	fi
	local qfigLocation=$_QFIG_LOC
	_QFIG_LOC="" # tell init.sh to reload
    source "$qfigLocation/init.sh"
	[ -z "$2" ] && logSuccess "Refreshed qfig" || logSuccess "$2"

	[ $ksharrays ] && set -o ksharrays || :
}

if [ "$_CURRENT_SHELL" = "bash" ]; then
	source "$_QFIG_LOC/command/enhancementForBash.sh"
elif [ "$_CURRENT_SHELL" = "zsh" ]; then
	source "$_QFIG_LOC/command/enhancementForZsh.sh"
fi

if [[ "$OSTYPE" =~ darwin* ]]; then
	function dquarantine() {  # delete quarantine attr
		[ -z "$1" ] && logError "Specify the path!" || :
		xattr -d com.apple.quarantine $1;
	}
fi

function qfig() { #? Qfig operations
	case $1 in
		-h|help)
			logInfo "Usage: qfig <command>\n\n  Available commands:\n"
			printf "    %-10s%s\n" "help" "Print this help message"
			printf "    %-10s%s\n" "refresh" "Refresh Qfig"
			printf "    %-10s%s\n" "update" "Update Qfig"
			printf "    %-10s%s\n" "config" "Edit config to enable commands, etc."
			printf "    %-10s%s\n" "report" "Report Qfig cared environment"
			printf "    %-10s%s\n" "v/version" "Show current version"
			printf "\n  \e[2mTips:\n"
			printf "    Command 'qcmds' perform operations about tool commands. Run 'qcmds -h' for more\n"
			printf "    Command 'gct' perform gct-commit step by step(need to enable 'git' commands)\n"
			printf "\e[0m"
			echo ""
			;;
		refresh)
			refresh-qfig
		;;
		update)
			logInfo "Fetching.."
			git -C $_QFIG_LOC fetch origin master
			if [ $? != 0 ]; then
				logError "Cannot fetch." && return 1
			fi
			declare -i behindCommits
			behindCommits=$(git -C $_QFIG_LOC rev-list --count .."master@{u}")
			if [ $behindCommits -eq 0 ]; then
				logSuccess "Qfig is already up to date" && return
			else
				local curHead=$(getCurrentHead 7)
				git -C $_QFIG_LOC pull --rebase 2>&1
				if [ $? != 0 ]; then
					logError "Cannot update." && return
				else
					logInfo "Updating Qfig.."
					local newHead=$(getCurrentHead 7)
					echoe "\nUpdate head \e[1m$curHead\e[0m -> \e[1m$newHead\e[0m:\n"
					git -C $_QFIG_LOC log --oneline --decorate --abbrev=7 -10 | awk -v ch=$curHead 'BEGIN{
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
				refresh-qfig - "Qfig updated!"
			fi
			;;
		config)
			if [ ! -f $_QFIG_LOCAL/config ]; then
				echoe "# This config was copied from the 'configTemplate'\n$(tail -n +2 $_QFIG_LOC/configTemplate)" > $_QFIG_LOCAL/config
				logInfo "Copied config from \e[1mconfigTemplate\e[0m"
			fi
			editfile $_QFIG_LOCAL/config
			;;
		into)
			cd $_QFIG_LOC
			;;
		report)
			local msg="$_INIT_MSG\n  OsType: $OSTYPE. Simulator: $TERM. Shell: $_CURRENT_SHELL"
			logInfo "$msg"
			;;
		v|version)
			local curHead=$(getCurrentHead)
			local branch=$(git -C $_QFIG_LOC symbolic-ref --short HEAD)
			echo "$branch ($curHead)"
			;;
		*)
			qfig help
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
			echoe "# Write your only-in-this-device commands/scripts below.
			# Changes will be effective in new sessions, to make it effective immidiately by running command 'resh'
			# This file will be ignored by .gitignore" > $targetFile
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

function resh() { #? refresh current shell session by config file(zsh.rc, etc)
    logInfo "Refreshing $_CURRENT_SHELL.."
    if [ "$_CURRENT_SHELL" = "zsh" ]; then
        source ~/.zshrc
    elif [ "$_CURRENT_SHELL" = "bash" ]; then
        source ~/.bashrc
    fi
    logInfo "Refreshed $_CURRENT_SHELL"
}

function editfile() { #? edit a file using preferredTextEditor
	[ -z $1 ] && logError "Which file ?" && return
	[ -d $1 ] && logError "Target is a directory !" && return
    eval "$_PREFER_TEXT_EDITOR $1"
}

function qmap() { #? edit a map(which may be recognized by Qfig commands) or output to _TEMP by -o flag
  OPTIND=1
  while getopts "o" opt; do
      case $opt in
          o)
              local output="1"
              ;;
          \?)
              ;;
      esac
  done
  shift "$((OPTIND - 1))"

  [ -z "$1" ] && logError "Which map ?" && return 1

  local file="$_QFIG_LOCAL/${1}MappingFile"
  if [ "$output" ]; then
    if [ -f "$file" ]; then
      local declaration
      declaration=$(awk -F '=' 'BEGIN{ s = "declare -gA _TEMP; _TEMP=("} \
      { if ( NF >= 2) s = s " [" $1 "]=" $2; } \
      END { s = s ")"; print s}' < "$file")
      eval "$declaration"
    else
      logWarn "Mapping file $file not exist"
      declare -gA _TEMP
    fi
  else
    editfile "$file"
  fi
}

function getArrayBase() { #x
	if [[ -o ksharrays ]] 2>/dev/null; then
		echo 0
	elif [[ "$_CURRENT_SHELL" = "zsh" ]]; then
		echo 1
	else
		echo 0
	fi
}

function getCurrentHead() { #x
	local branch commit len
	local branch=$(git -C $_QFIG_LOC rev-parse --abbrev-ref HEAD)
	[[ "$1" =~ ^[0-9]+$ && $1 -gt 0 ]] && len=$1 || len=9
	local commit=$(git -C $_QFIG_LOC rev-parse "$branch")
	echo ${commit:0:$len}
}

function readTemp() { #x
    _TEMP=
	local prompt=$1
	local limit=$2
	if [[ ! "$limit" = "" && "$limit" =~ ^[0-9]+$ && "$limit" -le 0 ]]; then
		logError "Invalid limit: $limit"
		return 1
	fi
	if [[ "$_CURRENT_SHELL" = "zsh" ]]; then
	    if [ "$limit" ]; then
	        readWithPromptAndLimit "$(echo -e "$prompt")" $limit
        else
            vared -p "$(echo -e "$prompt")" _TEMP
        fi
	else
	    if [ "$limit" ]; then
	        read -e -p "$(echo -e "$prompt")" -n $limit _TEMP
	    else
	        read -e -p "$(echo -e "$prompt")" _TEMP
        fi
	fi
}

function echoe() { #? echo with escapes
	[ -z "$1" ] && return 0 || :
	if [[ "$_CURRENT_SHELL" = "zsh" ]]; then # zsh use built-in echo
		echo "$1"
	else
		echo -e "$1"
	fi
}

function rmCr() { #x
	while IFS= read -r str; do
        echo "${str//$'\r'/}"
    done
	rdIFS
}

function filei() { #? print file info
	if [ "$_IS_BSD" ]; then
		file -I $1
	else
		file -i $1
	fi
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
function logSilence() { #? log inconspicuous message
    [ -z "$1" ] && return
    #logColor "\033[30;42m" $1
	printf "\e[2m$Qfig_log_prefix $1\e[0m\n"
}

# Flags:
# 1: no new line
# 2: no output(save to _TEMP)
function qfigLog() { #x log with a colored dot prefix
	local sgr=$1 # Select graphic rendition
	local log=$2
	local commands=$3 # prefix;flags
    [[ -z "$sgr" || -z "$log" ]] && return

    toArray "$commands" ';' && commands=("${_TEMP[@]}")
    local arrayBase=$(getArrayBase)

    # read prefix
    local prefix=${commands[$arrayBase]}
	[ -z "$prefix" ] && prefix="$Qfig_log_prefix" || :

    # read flags
    local flagsStr=${commands[$((arrayBase + 1))]}
    [[ "$flagsStr" =~ ^[0-9]+$ ]] && declare -i flags=$flagsStr || declare -i flags=0

	log=${log//\%/\%\%}
	# whatever a true LF (unicode d) or LF escape sequence "\r" (unicode 5c and 72) should be remove here
	log=${log//$'\r'/}
	log=${log//\\\r/}

    [[ $((flags & 1)) -eq 1 ]] && local nl="" || local nl="\n"
    log="$sgr$prefix\e[0m $log$nl"
    if [[ $((flags & 2)) -eq 2 ]]; then
        _TEMP="$log"
    else
        printf "$log"
    fi
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

function assertExist() { #? check file existence
	local file
    for file in "$@"
    do
        [ ! -f "$file" ] && logError "Missing file: $file" && return
    done
    echo "checked"
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

function rdIFS() { #? restore to default IFS
	IFS=$_DEF_IFS
}

function confirmYn() { #? confirm by y or n. Usage: confirmYn $flags(optional) $msg(optional), -h for more
    local prefix=""
    declare -i logFlags=3 # no new line & no output
    OPTIND=1
    while getopts ":hp:" opt; do
        case $opt in
            h)
                logInfo "Usage: confirmYn \$flags(optional) \$msg(optional).\n  \nFlags:\n"
                printf "    %-5s%s\n" "h" "Print this help message"
                printf "    %-5s%s\n" "p:" "Specific the prefix. default is $Qfig_log_prefix"
                printf "\e[0m"
                echo ""
                return 0
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
    local goon="1"
    local yn=""
    [[ -z "$1" ]] && message="Are you sure ?" || message=$1
    logInfo "$message \e[90m[Y/N] \e[0m" "$prefix;$logFlags"
    readTemp "$_TEMP" 1
    while [ "$goon" ]; do
        yn=$(echo "$_TEMP" | tr '[:upper:]' '[:lower:]')
        if [ "y" = "$yn" ]; then
            goon=""
        elif [ "n" = "$yn" ]; then
            return 1
        else
            logError "Invalid input, should be y or n "
            readTemp "" 1
        fi
    done
}

function confirm() { #? ask for confirmation. Usage: confirm $flags(optional) $msg(optional), -h for more
	local type="N" # N=normal, W=warning
    local inline="" # input after prompt
	local enterForYes="" # enter for yes
	local prefix=""
    declare -i logFlags=3 # no new line & no output
	OPTIND=1
	while getopts ":hlwep:" opt; do
        case $opt in
			h)
				logInfo "Usage: confirm \$flags(optional) \$msg(optional).\n  \nFlags:\n"
				printf "    %-5s%s\n" "h" "Print this help message"
                printf "    %-5s%s\n" "l" "Input inline(no new line, just after prompt)"
				printf "    %-5s%s\n" "w" "Raise to warning level"
				printf "    %-5s%s\n" "e" "Treat Enter as yes when it's normal level"
				printf "    %-5s%s\n" "p:" "Specific the prefix. default is $Qfig_log_prefix"
				printf "\e[0m"
				echo ""
				return 0
				;;
            l)
                inline="1"
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
		logWarn "$message \e[90mInput Yes to confirm.\e[0m" "$prefix;$logFlags"
		if [ "$inline" ]; then
		    readTemp "$_TEMP"
        else
            printf "$_TEMP\n"
            readTemp
        fi
		yn=$_TEMP
        yn=$(echo $yn | tr '[:upper:]' '[:lower:]')
		if [ 'yes' = "$yn" ]; then
            echoe "\e[34;1m[YES]\e[0m"
			return 0
		fi
	else
		if [[ $enterForYes ]]; then
			logInfo "$message \e[90mPress Enter or Input Y for Yes, others for No.\e[0m" "$prefix;$logFlags"
		else
			logInfo "$message \e[90mInput Y for Yes, others for No.\e[0m" "$prefix;$logFlags"
		fi
		if [ "$inline" ]; then
            readTemp "$_TEMP"
        else
            printf "$_TEMP\n"
            readTemp
        fi
		yn=$_TEMP
        yn=$(echo $yn | tr '[:upper:]' '[:lower:]')
		if [[ 'y' = "$yn" || 'yes' = "$yn" ]] || [[ $enterForYes && -z "$yn" ]]; then
            echoe "\e[34;1m[YES]\e[0m"
			return 0
		fi
	fi
    echoe "\e[33;1m[NO]\e[0m"
	return 1
}

function isExportedVar() { #? check whether it's exported var
	local dp
	dp=$(declare -p "$1" 2>/dev/null)
	if [[ "$dp" = 'declare -x'* ]] || [[ "$dp" = 'export '* ]]; then
		return 0
	fi
	return 1
}

#? Following are commands about string

function alignLeft() { #x
	[[ -z "$1" || -z "$2" || -z "$3" ]] && return
	declare -i len=$3
	local s=$1
	while [ ${#s} -lt $len ]; do
		s="$2$s"
	done
	echo $s
}

function md5x() { #? same as md5 in zsh, optimized md5sum of bash
	local str
	read str
	if [ "$_IS_BSD" ]; then
		echo -n $str | md5
	else
		local sum=($(echo -n $str | md5sum))
		echo ${sum[$(getArrayBase)]}
	fi
}

function replaceWord() { #? backup file with pointed suffix & replace word in file
    [ $# -lt 4 ] && logError "required params: file placeholder replacement backupSuffix" && return

    [ -n "$4" ] &&  cp "$1" "$1.$4"

    cat $1 | awk -v placeholder="$2" -v replacement="$3" '$0 ~ placeholder{sub(placeholder, replacement)} 1' | tee "$1" | printf ""
}


function undoReplaceWord() { #? recovery file with pointed suffix
    [ $# -lt 2 ] && logError "required params: sourceFile suffix" && return
    [ -f "$1.$2" ] && mv "$1.$2" $1
}

function findindex() { #? find 1st target index in provider. Usage: findindex provider target
	[[ -z $1 || -z $2 ]] && logError "Usage: findindex provider target" && return 1
	local s1len=${#1}
	local s2len=${#2}
	[ $s2len -gt $s1len ] && logError "Target is longer than provider!" && return 1
	declare -i i j
	i=0;j=0
	local c2=${2:$j:1}
	local c2_0=$c2
	for (( ; i<$s1len; i++ )); do
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

function concat() { #? concat array. Usage: concat $meta $item1 $item2 $item3... -h for more
	if [ "-h" = "$1" ]; then
		logInfo "Usage: concat \$meta \$item1 \$item2 \$item3.... "
		echoe "  \e[34m\$meta\e[0m pattern: \e[1m-joiner-start-end (exclusive)\e[0m. The first char is the separator of meta, here it's '-' (recommended).
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
		toArray $1 $metaSeparator && metas=("${_TEMP[@]}")

		if [ ${#metas[@]} -lt 1 ]; then
			logError "Meta must have at least 1 parts (joiner)" && return 1
		else
			declare -i arrayBase=$(getArrayBase)
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

function getStringWidth() { #x the return value is only valid for monospaced fonts
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

function trimString() { #? trim string
	[ -z "$1" ] && return
	local i s begin end len
	s=$1
	for (( i=0 ; i<${#s}; i++ )); do
		c=${s:$i:1}
		if ! [[ ' ' = "$c" || $'\t' = "$c" || $'\n' = "$c" || $'\r' = "$c" ]]; then
			begin=$i
			break
		fi
	done
	for (( i=$((${#s} - 1)) ; i>$begin; i-- )); do
		c=${s:$i:1}
		if ! [[ ' ' = "$c" || $'\t' = "$c" || $'\n' = "$c" || $'\r' = "$c" ]]; then
			end=$i
			break
		fi
	done
	len=$((end - begin + 1))
	echo ${s:begin:len}
}

function getMatch() { #? get regex match result
    local idx=$1
    if [ "$idx" = "" ]; then
        idx=0
    fi

	if [[ "$_CURRENT_SHELL" = "zsh" ]]; then
        if [ $idx = 0 ]; then
	        echo $MATCH
        else
            echo ${match[$idx]}
        fi
	else
        echo ${BASH_REMATCH[$idx]}
	fi
}

function toArray() { #? split string to array and save to _TEMP
    declare -ga _TEMP=()
    local splitter=" "
    [ "$2" ] && splitter="$2"
    if [[ "$_CURRENT_SHELL" = "zsh" ]]; then
        IFS="$splitter" _TEMP=($(echo "$1")); rdIFS
    else
        IFS="$splitter" read -ra _TEMP <<< "$1"; rdIFS
    fi
}

function repeatWord() { #? repeat a word n times
    local i
    local s=$1
    local count=$2
    local out=""
    for (( i=0 ; i<count; i++ )); do
        out="$out$s"
    done
    echo "$out"
}

function copyVar() { #? copy value and type of a variable to another
  [[ -z "$1" || -z "$2" ]] && logError "Usage: copyVar var1 var2" && return 1
  local declaration
  declaration=$(declare -p "$1")
  eval "${declaration/$1/$2}"
}