# These are command about gradle, make sure gradle is available before activation.

function gpkg() { #? gradle package & tell the size of jar
    logInfo "Packaging.."
    [ "-s" = $1 ] && gradle clean build -x tset || gradle clean build
    logInfo "Target size: "
    du -h target/*.jar
}

function gdhl() { #? hightlight a word in dependency tree
    [ -z "$1" ] && return
    gradle -q dependencies | awk -v word=$1 '{sub(word, sprintf("\033[0;31m%s\033[0m", word)); print}'
}

function gkilldaemons() {
    pkill -f '.*GradleDaemon.*'
}
