[ "$_QFIG_LOC" ] && return || : # avoid 2nd load in bash

_CURRENT_SHELL=$(ps -p $$ -o comm= 2>/dev/null) # if [[ "$OSTYPE" == "darwin"* ]] || [[ "$OSTYPE" == "linux"* ]]
if [ $? -ne 0 ]; then
	_CURRENT_SHELL=$(ps -p $$ comm= 2>/dev/null) # elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]
fi
if [ $? -ne 0 ]; then
	echo "Cannot determine the current shell."
	return 1
fi

## Get the location of Qfig project
## If script X source this script, in bash "$0" is path of X, in zsh it's path of this script
if [[ "$_CURRENT_SHELL" =~ ^.*zsh$ ]]; then
	_QFIG_LOC=$(dirname "$0")
	_CURRENT_SHELL="zsh"
elif [[ "$_CURRENT_SHELL" =~ ^.*bash$ ]]; then
	_QFIG_LOC=$(dirname ${BASH_SOURCE[0]})
	_CURRENT_SHELL="bash"
else
	unset _CURRENT_SHELL
	echo "Only zsh and bash are supported now."
	return 1
fi
export _CURRENT_SHELL

## Base configs
source $_QFIG_LOC/command/baseCommands.sh

## Custom configs 
_PREFER_TEXT_EDITOR=vim
if [ -f "$_QFIG_LOC/config" ]; then
	[[ "true" = $(sed -rn 's|<showVerboseInitMsg>(.+)</showVerboseInitMsg>|\1|p' $_QFIG_LOC/config) ]] && verbose=1 || verbose=""
	enabledCommands=""
	declare -A enabledCommandsMap

	function _enableCommands() {
		local cmds rcmds cmdsFile
		cmds=$1
		if [[ $cmds == *":"* ]]; then
			if [[ $cmds == *":sh" ]]; then
				cmds=${cmds:0:-3}
			else
				return
			fi
		fi
		[ ${enabledCommandsMap[$cmds]} ] && return || :
		enabledCommandsMap[$cmds]=1
		cmdsFile="$_QFIG_LOC/command/${cmds}Commands.sh"
		if [ -f "$cmdsFile" ]; then
			# Add this file required commands
			while read -r line; do
				line=${line//$'\r'/}
				line=${line//$'\n'/}
				if [[ "$line" =~ ^#R:[0-9a-zA-Z]+$ ]]; then
					rcmds=${line:3}
					_enableCommands $rcmds
				fi
			done < $cmdsFile

			source $cmdsFile
			enabledCommands="$enabledCommands $cmds"
		else
			logWarn "$cmdsFile Not Exists!"
		fi
	}

	while read -r cmds; do
		_enableCommands $cmds
	done < <(awk '/<enabledCommands>/{f = 1; next} /<\/enabledCommands>/{f = 0} f' $_QFIG_LOC/config)

	unset -f _enableCommands
	unset enabledCommandsMap

	_INIT_MSG=""
	[ "$enabledCommands" ] && _INIT_MSG+="Enabled commands:$enabledCommands. " || _INIT_MSG+="None enabled commands. "
    
    preferTextEditor=$(sed -rn 's|<preferTextEditor>(.+)</preferTextEditor>|\1|p' $_QFIG_LOC/config)
    if [ ! -z "$preferTextEditor" ]
    then
        _PREFER_TEXT_EDITOR=$preferTextEditor
    fi
	[ $preferTextEditor ] && _INIT_MSG+="Text editor: $_PREFER_TEXT_EDITOR. " || _INIT_MSG+="Text editor: $_PREFER_TEXT_EDITOR(default). "
	if [ $verbose ]; then
		logInfo "$_INIT_MSG"
	fi

	unset verbose
	unset enabledCommands
	unset preferTextEditor
else
	_INIT_MSG="";_INIT_MSG+="None enabled cmds. Text editor: $_PREFER_TEXT_EDITOR(default). "
fi

## Load functions that only works on current computer
if [ -f "$_QFIG_LOC/command/localCommands.sh" ]; then
	source $_QFIG_LOC/command/localCommands.sh
fi

_IS_BSD=$(grep --version | awk '/BSD grep/{print "1"}') # otherwise it's GNU
[ -z "$_DEF_IFS" ] && _DEF_IFS=$IFS || :