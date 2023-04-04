# These are commands about maven, make sure maven is available before activation. 

alias mfresh='mvn clean && mvn compile'
alias minst='mvn clean && mvn install'

function mpkg() { #? maven package & tell the size of jar in ./target
    while getopts ":p:s" opt; do
        case $opt in
            s) # Skip tset
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

function mdhl() { #? hightlight a word in dependency tree
    [ -z "$1" ] && return
    mvn dependency:tree | awk -v word=$1 '{sub(word, sprintf("\033[0;31m%s\033[0m", word)); print}'
}
