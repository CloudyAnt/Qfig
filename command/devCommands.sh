# These commands require 3rd programs

### Maven

alias mrefresh='mvn clean && mvn compile'
alias minst='mvn install'

function mpkg() { #? maven package & tell the size of jar in ./target
    logInfo "Maven packaging.."
    [ -z "$1" ] && mvn clean package || mvn clean package -P $1
    #[ "-s" = $1 ] && mvn clean package -Dmaven.test.skip=true || mvn clean package
    logInfo "Target size: "
    du -h target/*.jar
}

function mdhl() { #? hightlight a word in dependency tree
    [ -z "$1" ] && return
    mvn dependency:tree | awk -v word=$1 '{sub(word, sprintf("\033[0;31m%s\033[0m", word)); print}'
}

### Gradle

function gpkg() {
    logInfo "Gradle packaging.."
    [ "-s" = $1 ] && gradle clean build -x tset || gradle clean build
    logInfo "Target size: "
    du -h target/*.jar
}

function gdhl() { #? hightlight a word in dependency tree
    [ -z "$1" ] && return
    gradle -q dependencies | awk -v word=$1 '{sub(word, sprintf("\033[0;31m%s\033[0m", word)); print}'
}

### MySQL

alias mysqlu='mysql -uroot -p'
