# Activate Qfig for zsh(or bash)
currentShell=$(ps -p $$ -o comm= 2>/dev/null) # if [[ "$OSTYPE" == "darwin"* ]] || [[ "$OSTYPE" == "linux"* ]]
if [ $? -ne 0 ]; then
	currentShell=$(ps -p $$ comm= 2>/dev/null) # elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]
fi
if [ $? -ne 0 ]; then
	echo "Sorry, cannot determine the current shell."
	exit 1
fi

if [[ "$currentShell" =~ ^.*zsh$ ]]; then
	sysConfigFile="$HOME/.zshrc" # .zshrc will always be loaded
elif [[ "$currentShell" =~ ^.*bash$ ]]; then
	sysConfigFile="$HOME/.bashrc" # bash may only run .bashrc if not login shell
	sysConfigFile1="$HOME/.bash_profile" # bash only run .bash_profile if login shell
else
	echo "Sorry, only zsh and bash are not supported now."
	unset currentShell
	exit 1
fi

[ ! -f "$sysConfigFile" ] && touch $sysConfigFile || :
[[ ! -z "$sysConfigFile1" && ! -f "$sysConfigFile1" ]] && touch $sysConfigFile1 || :

currentLoc="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
baseConfig=$currentLoc/init.sh

# Check if actived
activationSegment=$(cat $sysConfigFile | awk -v f="$baseConfig" '$0 ~ f')
if [ ! -z "$activationSegment" ]
then
	echo "Qfig had already been activated!"
else
	# Add registration
	echo source $baseConfig >> $sysConfigFile

	# Add registration to the 2nd profile if not added
	if [ ! -z "$sysConfigFile1" ]; then
		activationSegment=$(cat $sysConfigFile1 | awk -v f="$baseConfig" '$0 ~ f')
		[ -z "$activationSegment" ] && echo source $baseConfig >> $sysConfigFile1 || :
	fi
	echo "Qfig has been activated! Please open a new session to check."
fi

# Init
source $sysConfigFile

unset currentShell
unset currentLoc
unset baseConfig 
unset activationSegment 
unset sysConfigFile
unset sysConfigFile1