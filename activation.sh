# Activate Qfig for zsh(or bash)
currentShell=$(ps -p $$ comm=)
if [[ "$currentShell" =~ ^.+zsh$ ]]; then
	sysConfigFile="$HOME/.zshrc"
elif [[ "$currentShell" =~ ^.+bash$ ]]; then
	sysConfigFile="$HOME/.bash_profile"
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

# Delete old registration
awk -v odr="source $currentLoc/config.sh" '{if($0 !=odr) print}' $sysConfigFile > $HOME/.temprc
cat $HOME/.temprc > $sysConfigFile
rm $HOME/.temprc

# Init
source $sysConfigFile

unset currentShell
unset currentLoc
unset baseConfig 
unset activationSegment 
unset sysConfigFile