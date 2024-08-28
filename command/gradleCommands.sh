#? These are command about gradle, make sure gradle is available before use.

function gpkg() { #? gradle package & tell the size of jar
    logInfo "Packaging.."
    [ "-s" = $1 ] && gradle clean build -x tset || gradle clean build
    logInfo "Target size: "
    du -h target/*.jar
}

function gdhl() { #? highlight a word in dependency tree
    [ -z "$1" ] && return
    gradle -q dependencies | awk -v word=$1 '{sub(word, sprintf("\033[0;31m%s\033[0m", word)); print}'
}

function gkilldaemons() {
    pkill -f '.*GradleDaemon.*'
}

function ginit() { #? create a gradle project with minimal build.gradle
    if [ -f "build.gradle" ]; then
        logWarn "build.gradle already exists in this directory."
        return
    fi

    local groupId artifactId version
    while [ -z "$groupId" ]; do
        readTemp "\e[34mgroupId\e[0m: " && groupId=$_TEMP
    done
    while [ -z "$version" ]; do
        readTemp "\e[34mversion\e[0m: " && version=$_TEMP
    done

    echo "apply plugin: 'java'
group = '$groupId'
version = '$version'

repositories {
    mavenCentral()
}" > build.gradle
}