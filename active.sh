currentLoc="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

fileToActive=$currentLoc/config.sh
# Check if actived

sysConfigFile=".zshrc"
[ ! -z "$sysConfigFile" ] && sysConifgFile=".bash_profile"

activedFile=`cat ${HOME}/.zshrc | awk -v f="$fileToActive" '$0 ~ f'`
[ ! -z "$activedFile" ] && echo "Qfig had already actieved!" && exit

echo source $fileToActive >> $HOME/.zshrc 
echo "Qfig activated!"

unset currentLoc
unset fileToActive
unset activedFile
unset sysConfigFile
