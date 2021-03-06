Qfig_loc=$(dirname "$0")

source $Qfig_loc/command/devCommands.sh
source $Qfig_loc/command/gitCommands.sh
source $Qfig_loc/command/utilCommands.sh
source $Qfig_loc/command/dockerCommands.sh
source $Qfig_loc/command/sshCommands.sh
source $Qfig_loc/command/curlCommands.sh

# Temp commands, will be ignored in .gitignore
[ -f "$Qfig_loc/command/tempCommands.sh" ] && source $Qfig_loc/command/tempCommands.sh 
