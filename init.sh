# You can add custom configs in the 'config' file

## The location of Qfig project
Qfig_loc=$(dirname "$0")

## Base configs
source $Qfig_loc/command/baseCommands.sh

## Custom configs 
[[ "true" = $(sed -rn 's|<showVerboseInitMsg>(.+)</showVerboseInitMsg>|\1|p' $Qfig_loc/config) ]] && verbose=1

preferTextEditor=vim
if [ -f "$Qfig_loc/config" ]
then
    awk '/<enabledCommands>/{f = 1; next} /<\/enabledCommands>/{f = 0} f' $Qfig_loc/config | \
        while read -r cmds; do \
            cmdsFile="$Qfig_loc/command/${cmds}Commands.sh"
			if [ -f "$cmdsFile" ]; then
				source $cmdsFile
				[ $verbose ] && logInfo "Enabled commands: $cmds"
			else
				logWarn "$cmdsFile Not Exists!"
			fi
        done
    
    _preferTextEditor=$(sed -rn 's|<preferTextEditor>(.+)</preferTextEditor>|\1|p' $Qfig_loc/config)
    if [ ! -z "$_preferTextEditor" ]
    then
        preferTextEditor=$_preferTextEditor
        [ $verbose ] && logInfo "Using prefer text editor: $preferTextEditor"
	elif [ $verbose ]; then
		logInfo "Using default text editor: $preferTextEditor"
    fi
fi

## For functions only works on current computer, add them to the tempCommands.sh/tempCommands.ps1
## All functions in these files will not be included in git
[ -f "$Qfig_loc/command/tempCommands.sh" ] && source $Qfig_loc/command/tempCommands.sh

unset cmdsFile
unset verbose
unset _preferTextEditor
