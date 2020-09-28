### Maven

function mpkg() { #? maven package & tell the size of jar in ./target
    logInfo "Maven packaging.."
    [ "-s" = $1 ] && mvn clean package -Dmaven.test.skip=true || mvn clean package
    logInfo "Target size: "
    du -h target/*.jar
}

function gpkg() {
    logInfo "Gradle packaging.."
    [ "-s" = $1 ] && gradle clean build -x tset || gradle clean build
    logInfo "Target size: "
    du -h target/*.jar
}

function mdhl() { #? hightlight a word in dependency tree
    [ -z "$1" ] && return
    mvn dependency:tree | awk -v word=$1 '{sub(word, sprintf("\033[0;31m%s\033[0m", word)); print}'
}

### MySQL

alias mysqlu='mysql -uroot -p'

## System

function vimcs() { #? vim commands
   [ -z $1 ] || [ ! -f `tdmt`/command/$1Commands.sh ] && return
   vim `tdmt`/command/$1Commands.sh
}
