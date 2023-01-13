# Activate Qfig for zsh(or bash)

currentLoc="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

baseConfig=$currentLoc/init.sh

sysConfigFile="$HOME/.zshrc"
[ ! -z "$sysConfigFile" ] && sysConifgFile="$HOME/.bash_profile"

# Check if actived
activationSegment=`cat ${HOME}/.zshrc | awk -v f="$baseConfig" '$0 ~ f'`
if [ ! -z "$activationSegment" ]
then
	echo "Qfig had already been activated!"
else
	# Add registration
	echo source $baseConfig >> $sysConfigFile
	echo "Qfig has been activated! Please open a new session to check."
fi

# Delete old registration
awk -v or="source $currentLoc/config.sh" '{if($0 !=or) print}' $sysConfigFile > $HOME/.temprc
cat $HOME/.temprc > $sysConfigFile
rm $HOME/.temprc

unset currentLoc
unset baseConfig 
unset activationSegment 
unset sysConfigFile
