# Activate Qfig for zsh(or bash). Please use activation-cygwin.sh if it's under cygwin

if [ -n "$ZSH_VERSION" ]; then
  # shellcheck disable=SC2296
  currentLoc=$(cd "$(dirname "${(%):-%x}")" >/dev/null 2>&1 && pwd)
elif [ -n "$BASH_VERSION" ]; then
  currentLoc=$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)
fi

baseConfig=$currentLoc/init.sh
function activeQfigForProfile() {
    local profile=$1
    if [ ! -f $profile ]; then
        if [ -d $profile ]; then
            echo "$profile is a directory!" && exit 1
        fi
        touch $profile
    fi
    
    # Check if actived
    activationSegment=$(cat $profile | awk -v f="$baseConfig" '$0 ~ f')

    if [ -z "$activationSegment" ]; then
        # Add registration
        echo source $baseConfig >> $profile
        activation=1
    fi
}

profiles=($HOME/.zshrc $HOME/.bashrc $HOME/.bash_profile)
for profile in "${profiles[@]}";do
    activeQfigForProfile $profile
done

if [ "$activation" ]; then
    echo "Qfig has been activated(for zsh and bash)! Please open a new session to check."
else
    echo "Qfig had already been activated(for zsh and bash)! Please open a new session to check."
fi
