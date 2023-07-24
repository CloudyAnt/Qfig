_CURRENT_SHELL=$(ps -p $$ comm=) # no -o after $$ for compatibility, this variable contains very detailed shell info

## Get the location of Qfig project
if [[ "$_CURRENT_SHELL" =~ ^.+zsh$ ]]; then
	Qfig_loc=$(dirname "$0")
	_CURRENT_SHELL="zsh"
elif [[ "$_CURRENT_SHELL" =~ ^.+bash$ ]]; then
	Qfig_loc=$(dirname ${BASH_SOURCE[0]})
	_CURRENT_SHELL="bash"
else
	unset _CURRENT_SHELL
	echo "Qfig is activated, but only zsh and bash are supported now."
	return 0
fi

## Base configs
source $Qfig_loc/command/baseCommands.sh

## Custom configs 
preferTextEditor=vim
if [ -f "$Qfig_loc/config" ]; then
	[[ "true" = $(sed -rn 's|<showVerboseInitMsg>(.+)</showVerboseInitMsg>|\1|p' $Qfig_loc/config) ]] && verbose=1 || verbose=""
	enabledCommands=""
	initMsg=""
	while read -r cmds; do \
		cmdsFile="$Qfig_loc/command/${cmds}Commands.sh"
		if [ -f "$cmdsFile" ]; then
			source $cmdsFile
			enabledCommands="$enabledCommands $cmds"
		else
			logWarn "$cmdsFile Not Exists!"
		fi
	done < <(awk '/<enabledCommands>/{f = 1; next} /<\/enabledCommands>/{f = 0} f' $Qfig_loc/config)
	[ "$enabledCommands" ] && initMsg+="Enabled commands:$enabledCommands. " || initMsg+="None enabled commands. "
    
    _preferTextEditor=$(sed -rn 's|<preferTextEditor>(.+)</preferTextEditor>|\1|p' $Qfig_loc/config)
    if [ ! -z "$_preferTextEditor" ]
    then
        preferTextEditor=$_preferTextEditor
    fi
	[ $_preferTextEditor ] && initMsg+="Using prefer text editor: $preferTextEditor. " || initMsg+="Using default text editor: $preferTextEditor. "
	if [ $verbose ]; then
		logInfo $initMsg
	fi

	unset cmdsFile
	unset verbose
	unset enabledCommands
	unset _preferTextEditor
fi

## Load functions that only works on current computer
if [ -f "$Qfig_loc/command/localCommands.sh" ]; then
	source $Qfig_loc/command/localCommands.sh
fi