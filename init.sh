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

## create local data folder
_QFIG_LOCAL=$_QFIG_LOC/.local
if [ ! -d "$_QFIG_LOCAL" ]; then
	mkdir "$_QFIG_LOCAL"
fi

# -z test whether this value was set
[ -z "$_DEF_IFS" ] && _DEF_IFS=$IFS || :


## Base configs
source $_QFIG_LOC/command/baseCommands.sh

## Custom configs 
_PREFER_TEXT_EDITOR=vim
localConfigFile=$_QFIG_LOCAL/config
if [ ! -f "$localConfigFile" ]; then
	localConfigFile=$_QFIG_LOC/configTemplate
fi
if [ -f "$localConfigFile" ]; then
	[[ "true" = $(sed -rn 's|<showVerboseInitMsg>(.+)</showVerboseInitMsg>|\1|p' $localConfigFile) ]] && verbose=1 || verbose=""
	enabledCommands=""
	declare -A enabledCommandsMap

   # Add line 'enable-qcmds foo' in the commands file if it requires foo commands
	function enable-qcmds() {
		local cmds rcmds cmdsFile
		cmds=$1
		if [[ $cmds == *":"* ]]; then
			if [[ $cmds == *":sh" ]]; then
				# only load shell commands
				cmds=${cmds:0:-3}
			else
				return
			fi
		fi
		[ ${enabledCommandsMap[$cmds]} ] && return || :
		enabledCommandsMap[$cmds]=1
		cmdsFile="$_QFIG_LOC/command/${cmds}Commands.sh"
		if [ -f "$cmdsFile" ]; then
			source $cmdsFile
			enabledCommands="$enabledCommands $cmds"
		else
			logWarn "$cmdsFile Not Exists!"
		fi
	}

	while read -r cmds; do
		enable-qcmds $cmds
	done < <(awk '/<enabledCommands>/{f = 1; next} /<\/enabledCommands>/{f = 0} f' $localConfigFile)

	_INIT_MSG=""
	[ "$enabledCommands" ] && _INIT_MSG+="Enabled commands:$enabledCommands. " || _INIT_MSG+="None enabled commands. "
    
    preferTextEditor=$(sed -rn 's|<preferTextEditor>(.+)</preferTextEditor>|\1|p' $localConfigFile)
    if [ -n "$preferTextEditor" ]
    then
        _PREFER_TEXT_EDITOR=$preferTextEditor
    fi
	[ $preferTextEditor ] && _INIT_MSG+="Text editor: $_PREFER_TEXT_EDITOR. " || _INIT_MSG+="Text editor: $_PREFER_TEXT_EDITOR(default). "
	if [ $verbose ]; then
		logInfo "$_INIT_MSG"
	fi

	unset verbose
	unset localConfigFile
	unset enabledCommands
	unset enabledCommandsMap
	unset preferTextEditor
	unset -f enable-qcmds
else
	_INIT_MSG="";_INIT_MSG+="None enabled cmds. Text editor: $_PREFER_TEXT_EDITOR(default). "
fi

## Load functions that only works on current computer
if [ -f "$_QFIG_LOC/command/localCommands.sh" ]; then
	source $_QFIG_LOC/command/localCommands.sh
fi

_IS_BSD=$(grep --version | awk '/BSD grep/{print "1"}') # otherwise it's GNU
