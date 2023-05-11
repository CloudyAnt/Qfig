#? These are commands about java, make sure it's available before use.

function jrun() { #? java compile hello.java && java hello
    [ -z $1 ] && logError "Which file to run ?" && return
    [ ! -f "$1" ] && logError "File does not exist !" && return

    file=$1
    fileSuffix=`echo $file | awk -F '.' '{print $2}'`
    [ "java" != "$fileSuffix" ] && logWarn "File is not end with .java" && return

    simpleName=`echo $file | awk -F '.' '{print $1}'`
    javac $file

    # return if javac failed
    [ 1 -eq $? ] && return

    java $simpleName
}
