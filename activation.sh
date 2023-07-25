# Activate Qfig for zsh(or bash)
currentShell=$(ps -p $$ -o comm=) # if [[ "$OSTYPE" == "darwin"* ]] || [[ "$OSTYPE" == "linux"* ]]
if [ $? -ne 0 ]; then
	currentShell=$(ps -p $$ comm=) # elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]
fi
if [ $? -ne 0 ]; then
	echo "Sorry, cannot determine the current shell."
	exit 1
fi

# .zprofile or .bash_profile will no be loaded if it's not login shell
# .zshrc and .bashrc will always be loaded
if [[ "$currentShell" =~ ^.*zsh$ ]]; then
	sysConfigFile="$HOME/.zshrc"
elif [[ "$currentShell" =~ ^.*bash$ ]]; then
	sysConfigFile="$HOME/.bashrc"
else
	echo "Sorry, only zsh and bash are not supported now."
	unset currentShell
	exit 1
fi

[ ! -f "$sysConfigFile" ] && touch $sysConfigFile || cp $sysConfigFile $sysConfigFile.bk

currentLoc="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
baseConfig=$currentLoc/init.sh

# Check if actived
activationSegment=`cat $sysConfigFile | awk -v f="$baseConfig" '$0 ~ f'`
if [ ! -z "$activationSegment" ]
then
	echo "Qfig had already been activated!"
else
	# Add registration
	echo source $baseConfig >> $sysConfigFile
	echo "Qfig has been activated! Please open a new session to check."
fi

# Init
source $sysConfigFile

unset currentShell
unset currentLoc
unset baseConfig 
unset activationSegment 
unset sysConfigFile