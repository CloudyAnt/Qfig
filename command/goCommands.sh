function gorun() { #? go compile then run
    [ -z $1 ] && logError "Which file to run ?" && return
    local file=$1
    if [[ $file =~ ^[^.]+$ ]]; then
        file=$file".go"
    fi
    [ ! -f "$file" ] && logError "File $file does not exist !" && return

    local fileSuffix=$(echo $file | awk -F '.' '{print $2}')
    [ "go" != "$fileSuffix" ] && logWarn "File is not end with .go" && return

    local simpleName=$(echo $file | awk -F '.' '{print $1}')
	go build $file

    # return if javac failed
    [ 1 -eq $? ] && return

    ./$simpleName
}

function _gorun() { #x
    declare -i arrayBase
	[[ -o ksharrays ]] && arrayBase=0 || arrayBase=1 # if KSH_ARRAYS option set, array based on 0, and '{}' are required to access index
	if [ $COMP_CWORD -gt $(($arrayBase + 1)) ]; then
		return 0
	fi

	local latest="${COMP_WORDS[$COMP_CWORD]}"
    local fff=$(ls $latest*.go)
	COMPREPLY=($(compgen -W "$fff" -- $latest))
	return 0
}

complete -F _gorun gorun 
