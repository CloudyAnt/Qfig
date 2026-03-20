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

function ginit() { #? create a gradle project. Usage: ginit [-k]
    local ext="gradle"
    OPTIND=1
    while getopts ":k" opt; do
        case $opt in
            k)
                ext="gradle.kts"
                logInfo "Will create kts build files"
                ;;
            \?)
                return 1
                ;;
        esac
    done

    if [ -f "build.$ext" ] || [ -f "settings.$ext" ]; then
        logWarn "build.$ext or settings.$ext already exists in this directory."
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
    id(\"java\")
}
group = \"$groupId\"
version = \"$version\"

repositories {
    mavenCentral()
}" > build.$ext
    echo "rootProject.name = \"$projectName\"" > settings.$ext
    logInfo "build.$ext and settings.$ext created."
}
