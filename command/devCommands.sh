# These commands require 3rd party programs like maven, mysql, etc.

### Maven

alias mfresh='mvn clean compile'
alias minst='mvn clean install'

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

function gpkg() { logInfo "Packaging.."
    [ "-s" = $1 ] && gradle clean build -x tset || gradle clean build
    logInfo "Target size: "
    du -h target/*.jar
}

function gdhl() { #? hightlight a word in dependency tree
    [ -z "$1" ] && return
    gradle -q dependencies | awk -v word=$1 '{sub(word, sprintf("\033[0;31m%s\033[0m", word)); print}'
}

### MySQL

alias mysqll='mysql -uroot -p' # Connect local mysql 

_MYSQL_MAPPING_FILE=$Qfig_loc/mysqlMappingFile

[ ! -f $_MYSQL_MAPPING_FILE ] && touch $_MYSQL_MAPPING_FILE
eval `cat $_MYSQL_MAPPING_FILE | awk -F '=' 'BEGIN{ s0 = "";s = "declare -A _MYSQL_MAPPING=(";s1 = ""} \
    { if ( NF >= 2) { \
        split($2, parts, "#"); s0 = s0 ";_MYSQL_MAPPING_" $1 "=(\"" parts[1] "\" \"" parts[2] "\" \"" parts[3] "\")"; \
        s = s " [" $1 "]=$_MYSQL_MAPPING_" $1; \
        s1 = s1 ";unset _MYSQL_MAPPING_" $1; \
    }} \
    END { s = s ")"; print s0; print s; print s1}'`

function mysqlc() { #? Connect mysql by mapping defined in mysqlMappingFile
    [ -z $1 ] || [ -z $_MYSQL_MAPPING[$1] ] && logError "Which mapping?" && return
    unset mapping
    eval "mapping=($_MYSQL_MAPPING[$1])"
    mysql -u $mapping[2] -p$mapping[3] -h $mapping[1]
}
 

### JAVA

function jrun() { #? java compile hello.java && java hello
    [ -z $1 ] && logError "Which file to run ?" && return
    [ ! -f "$1" ] && logError "File does not exist !" && return

    file=$1
    fileSuffix=`echo $file | awk -F '.' '{print $2}'`
    [ "java" != "$fileSuffix" ] && logWarn "File is not end with .java" && return

    simpleName=`echo $file | awk -F '.' '{print $1}'`
    javac $file

    # return if javac failed
    [ 1 -eq $? ] && return

    java $simpleName
}

### Oh my zsh

function rezsh() {
    logInfo "Refreshing oh-my-zsh..."
    source ~/.zshrc
    logSuccess "Oh-my-zsh refreshed"
}
