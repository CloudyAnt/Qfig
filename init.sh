# You can add custom configs in the 'config' file

## The location of Qfig project
Qfig_loc=$(dirname "$0")

## Base configs
source $Qfig_loc/command/baseCommands.sh

## Custom configs 
preferTextEditor=vim
if [ -f "$Qfig_loc/config" ]
then
	[[ "true" = $(sed -rn 's|<showVerboseInitMsg>(.+)</showVerboseInitMsg>|\1|p' $Qfig_loc/config) ]] && verbose=1
	enabledCommands=""
    awk '/<enabledCommands>/{f = 1; next} /<\/enabledCommands>/{f = 0} f' $Qfig_loc/config | \
        while read -r cmds; do \
            cmdsFile="$Qfig_loc/command/${cmds}Commands.sh"
			if [ -f "$cmdsFile" ]; then
				source $cmdsFile
				enabledCommands="$enabledCommands $cmds" 
			else
				logWarn "$cmdsFile Not Exists!"
			fi
        done
	if [ $verbose ]; then
		[ $enabledCommands ] && logInfo "Enabled commands:$enabledCommands" || logInfo "None enabled commands"
	fi
    
    _preferTextEditor=$(sed -rn 's|<preferTextEditor>(.+)</preferTextEditor>|\1|p' $Qfig_loc/config)
    if [ ! -z "$_preferTextEditor" ]
    then
        preferTextEditor=$_preferTextEditor
    fi
	if [ $verbose ]; then
		[ $_preferTextEditor ] && logInfo "Using prefer text editor: $preferTextEditor" \
			|| logInfo "Using default text editor: $preferTextEditor"
	fi

	unset cmdsFile
	unset verbose
	unset enabledCommands
	unset _preferTextEditor
fi

## Load functions that only works on current computer
[ -f "$Qfig_loc/command/localCommands.sh" ] && source $Qfig_loc/command/localCommands.sh
