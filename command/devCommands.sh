# These commands require 3rd party programs

### Maven

alias mfresh='mvn clean && mvn compile'
alias minst='mvn install'

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

### Gradle

function gpkg() {
    logInfo "Packaging.."
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

### JAVA

function jrun() { #? java compile hello.java && java hello 
    [ -z $1 ] && logError "Which file to run ?" && return
    file=$1
    
    fileSuffix=`echo $file | awk -F '.' '{print $2}'`
    [ "java" != "$fileSuffix" ] && logWarn "File is not end with .java" && return

    simpleName=`echo $file | awk -F '.' '{print $1}'` 
    javac $file
    java $simpleName
}
