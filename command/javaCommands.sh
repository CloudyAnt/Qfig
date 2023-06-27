#? These are commands about java, make sure it's available before use.

function jrun() { #? java compile then run, jrun Hello => javac Hello.java && java Hello
    [ -z $1 ] && logError "Which file to run ?" && return
    [ ! -f "$1" ] && logError "File does not exist !" && return

    local file=$1
    local fileSuffix=`echo $file | awk -F '.' '{print $2}'`
    [ "java" != "$fileSuffix" ] && logWarn "File is not end with .java" && return

    local simpleName=`echo $file | awk -F '.' '{print $1}'`
    javac $file

    # return if javac failed
    [ 1 -eq $? ] && return

    java $simpleName
}

function _jrun() { #x
    declare -i arrayBase
	[[ -o ksharrays ]] && arrayBase=0 || arrayBase=1 # if KSH_ARRAYS option set, array based on 0, and '{}' are required to access index
	if [ $COMP_CWORD -gt $(($arrayBase + 1)) ]; then
		return 0
	fi

	local latest="${COMP_WORDS[$COMP_CWORD]}"
    local fff=$(ls $latest*.java)
	COMPREPLY=($(compgen -W "$fff" -- $latest))
	return 0
}

complete -F _jrun jrun