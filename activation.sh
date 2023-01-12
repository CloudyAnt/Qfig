# Make sure you are using unix-like os! Else if you are using Windows os, please use activation.ps1

currentLoc="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

baseConfig=$currentLoc/init.sh
# Check if actived

sysConfigFile=".zshrc"
[ ! -z "$sysConfigFile" ] && sysConifgFile=".bash_profile"

activationSegment=`cat ${HOME}/.zshrc | awk -v f="$baseConfig" '$0 ~ f'`
[ ! -z "$activationSegment" ] && echo "Qfig had already been activated!" && exit

echo source $baseConfig >> $HOME/.zshrc 
echo "Qfig has been activated! Please open a new session to check."

unset currentLoc
unset baseConfig 
unset activationSegment 
unset sysConfigFile
