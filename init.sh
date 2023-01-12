# You can add custom configs in the 'config' file

## The location of Qfig project
Qfig_loc=$(dirname "$0")

## The functions used in this script
function doNothing() {}

## Base configs
source $Qfig_loc/command/baseCommands.sh

## Custom configs 
[ -f "$Qfig_loc/config" ] && awk '/<enabledCommands>/{f = 1; next} /<\/enabledCommands>/{f = 0} f' $Qfig_loc/config | \
	while read -r cmds; do \
		cmdsFile="$Qfig_loc/command/${cmds}Commands.sh"
		[ -f "$cmdsFile" ] && source $cmdsFile || logWarn "$cmdsFile Not Exists!"
	done

## For functions only works on current computer, add them to the tempCommands.sh/tempCommands.ps1
## All functions in these files will not be included in git
[ -f "$Qfig_loc/command/tempCommands.sh" ] && source $Qfig_loc/command/tempCommands.sh || doNothing 

unset -f doNothing
