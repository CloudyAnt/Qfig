_CURRENT_SHELL=$(ps -p $$ -o comm= 2>/dev/null) # if [[ "$OSTYPE" == "darwin"* ]] || [[ "$OSTYPE" == "linux"* ]]
if [ $? -ne 0 ]; then
	_CURRENT_SHELL=$(ps -p $$ comm= 2>/dev/null) # elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]
fi
if [ $? -ne 0 ]; then
	echo "Qfig is activated, but cannot determine the current shell."
	return 1
fi

## Get the location of Qfig project
if [[ "$_CURRENT_SHELL" =~ ^.*zsh$ ]]; then
	_QFIG_LOC=$(dirname "$0")
	_CURRENT_SHELL="zsh"
elif [[ "$_CURRENT_SHELL" =~ ^.*bash$ ]]; then
	_QFIG_LOC=$(dirname ${BASH_SOURCE[0]})
	_CURRENT_SHELL="bash"
else
	unset _CURRENT_SHELL
	echo "Qfig is activated, but only zsh and bash are supported now."
	return 1
fi
export _CURRENT_SHELL

## Base configs
source $_QFIG_LOC/command/baseCommands.sh

## Custom configs 
preferTextEditor=vim
if [ -f "$_QFIG_LOC/config" ]; then
	[[ "true" = $(sed -rn 's|<showVerboseInitMsg>(.+)</showVerboseInitMsg>|\1|p' $_QFIG_LOC/config) ]] && verbose=1 || verbose=""
	enabledCommands=""
	_INIT_MSG=""
	while read -r cmds; do
		cmdsFile="$_QFIG_LOC/command/${cmds}Commands.sh"
		if [ -f "$cmdsFile" ]; then
			source $cmdsFile
			enabledCommands="$enabledCommands $cmds"
		else
			logWarn "$cmdsFile Not Exists!"
		fi
	done < <(awk '/<enabledCommands>/{f = 1; next} /<\/enabledCommands>/{f = 0} f' $_QFIG_LOC/config)
	[ "$enabledCommands" ] && _INIT_MSG+="Enabled commands:$enabledCommands. " || _INIT_MSG+="None enabled commands. "
    
    _preferTextEditor=$(sed -rn 's|<preferTextEditor>(.+)</preferTextEditor>|\1|p' $_QFIG_LOC/config)
    if [ ! -z "$_preferTextEditor" ]
    then
        preferTextEditor=$_preferTextEditor
    fi
	[ $_preferTextEditor ] && _INIT_MSG+="Text editor: $preferTextEditor. " || _INIT_MSG+="Text editor: $preferTextEditor(default). "
	if [ $verbose ]; then
		logInfo $_INIT_MSG
	fi

	unset cmdsFile
	unset verbose
	unset enabledCommands
	unset _preferTextEditor
fi

## Load functions that only works on current computer
if [ -f "$_QFIG_LOC/command/localCommands.sh" ]; then
	source $_QFIG_LOC/command/localCommands.sh
fi

_IS_BSD=$(grep --version | awk '/BSD grep/{print "1"}') # otherwise it's GNU
