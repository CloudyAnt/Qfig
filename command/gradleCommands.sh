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
    local templateExt="gradle"
    OPTIND=1
    while getopts ":k" opt; do
        case $opt in
            k)
                ext="gradle.kts"
                templateExt="gradle.kts"
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

    sed -e "s/@@GROUPID@@/$groupId/g" \
        -e "s/@@VERSION@@/$version/g" \
        "$_QFIG_LOC/staff/build.$templateExt.template" > build.$ext

    sed "s/@@PROJECTNAME@@/$projectName/g" \
        "$_QFIG_LOC/staff/settings.$templateExt.template" > settings.$ext

    echo "version=$version
org.gradle.jvmargs=-Dfile.encoding=UTF-8
org.gradle.daemon.idletimeout=30000" > gradle.properties
    logInfo "build.$ext, settings.$ext and gradle.properties created."
}
