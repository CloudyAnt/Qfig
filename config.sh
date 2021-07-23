# Default configs. This file SHOULD NOT be edited! Please edit your myConfig.sh at current folder

Qfig_loc=$(dirname "$0")

## Base configs
source $Qfig_loc/command/utilCommands.sh

## Custom configs
[ -f "$Qfig_loc/myConfig.sh" ] && source $Qfig_loc/myConfig.sh

## Temp commands, will be ignored in .gitignore
[ -f "$Qfig_loc/command/tempCommands.sh" ] && source $Qfig_loc/command/tempCommands.sh 
