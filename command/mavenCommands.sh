#? These are commands about maven, make sure maven is available before use.

alias mfresh='mvn clean && mvn compile'
alias minst='mvn clean && mvn install'

function mpkg() { #? maven package & tell the size of jar in ./target
    OPTIND=1
    while getopts ":p:s" opt; do
        case $opt in
            s) # Skip test
                skipSegment="-Dmaven.test.skip=true" >&2
                logInfo "Skip tests"
                ;;
            p) # Select profile
                [ -z $OPTARG ] && logError "Which profile ?" && return
                profileSegment="-P $OPTARG"
                logInfo "Using profile: $OPTARG"
                ;;
            :)
                echo "Option $OPTARG requires an arg" && return
                ;;
            \?)
                echo "Invalid option: -$OPTARG" && return
                ;;
        esac
    done

    logInfo "Packaging.."
    mvn clean package $skipSegment $profileSegment
    logInfo "Target size: "
    du -h target/*.jar
}

function mdhl() { #? highlight a word in dependency tree
    [ -z "$1" ] && return
    mvn dependency:tree | awk -v word=$1 '{sub(word, sprintf("\033[0;31m%s\033[0m", word)); print}'
}

function minit() { #? create a maven project with minimal pom.xml
    if [ -f "pom.xml" ]; then
        logWarn "pom.xml already exists in this directory."
        return
    fi

    local groupId artifactId version
    while [ -z "$groupId" ]; do
        readTemp "\e[34mgroupId\e[0m: " && groupId=$_TEMP
    done
    while [ -z "$artifactId" ]; do
        readTemp "\e[34martifactId\e[0m: " && artifactId=$_TEMP
    done
    while [ -z "$version" ]; do
        readTemp "\e[34mversion\e[0m: " && version=$_TEMP
    done

    echo "<project>
    <modelVersion>4.0.0</modelVersion>
    <groupId>$groupId</groupId>
    <artifactId>$artifactId</artifactId>
    <version>$version</version>
</project>" > pom.xml
}