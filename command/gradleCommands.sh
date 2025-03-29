#? These are command about gradle, make sure gradle is available before use.

function gpkg() { #? gradle package & tell the size of jar
    logInfo "Packaging.."
    [ "-s" = $1 ] && gradle clean build -x test || gradle clean build
    logInfo "Target size: "
    du -h build/libs/*.jar
}

function gdhl() { #? highlight a word in dependency tree
    [ -z "$1" ] && return
    gradle -q dependencies | awk -v word=$1 '{sub(word, sprintf("\033[0;31m%s\033[0m", word)); print}'
}

function gkilldaemons() {
    pkill -f '.*GradleDaemon.*'
}

function ginit() { #? create a gradle project with minimal build.gradle and settings.gradle
    if [ -f "build.gradle" ] || [ -f "settings.gradle" ]; then
        logWarn "build.gradle or settings.gradle already exists in this directory."
        return
    fi

    local groupId projectName version
    while [ -z "$groupId" ]; do
        readTemp "\e[34mgroupId\e[0m: " && groupId=$_TEMP
    done
    while [ -z "$projectName" ]; do
        readTemp "\e[34mprojectName\e[0m: " && projectName=$_TEMP
    done
    while [ -z "$version" ]; do
        readTemp "\e[34mversion\e[0m: " && version=$_TEMP
    done

    echo "plugins {
    id 'java'
}
group = '$groupId'
version = '$version'

repositories {
    mavenCentral()
}" > build.gradle
    echo "rootProject.name = '$projectName'" > settings.gradle
    logInfo "build.gradle and settings.gradle created."
}
