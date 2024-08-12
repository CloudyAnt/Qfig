#!/usr/bin/env zsh
#? These are commands about Mysql, make sure it's available before ues.
#? You need to edit the mysql mapping file by execute 'qmap mysql'. A mapping like: key=server:port#username#userpass

alias mysqll='mysql -uroot -p' # Connect local mysql
qmap -c mysql _MYSQL_MAPPING

function mysqlc() { #x
    [ -z "$1" ] && logError "Please specify the mysql mapping key!" && return 1
    [ -z "${_MYSQL_MAPPING[$1]}" ] && logWarn "No mysql mapping for: $1. Use 'qmap mysql' to add." && return 1
    toArray "${_MYSQL_MAPPING[$1]}" "#" && declare -a mapping=("${_TEMP[@]}")
    declare -i mappingSize=${#mapping[@]}
    if [ $mappingSize -lt 3 ]; then
        logError "Invalid mapping. A mapping should be like:
\e[1mkey=server:port#username#userpass#options\e[0m, options is optional"
        return 1
    fi

    declare -i arrayBase
    arrayBase=$(getArrayBase)
    local hostPort host port username password
    declare -a options=()

    hostPort="${mapping[$arrayBase]}:"
    host=$(cut -d":" -f1 <<< "$hostPort")
    port=$(cut -d":" -f2 <<< "$hostPort")
    username=${mapping[$((arrayBase + 1))]}
    password=${mapping[$((arrayBase + 2))]}

    if [ $mappingSize -gt 3 ]; then
        # add options in mapping
        toArray "${mapping[$((arrayBase + 3))]}" " " && options+=("${_TEMP[@]}")
    fi
    if [ -n "$2" ]; then
        # add options in command line
        toArray "$2" " " && options+=("${_TEMP[@]}")
    fi

    if [ -z "$port" ]
    then
        logInfo "Executing: mysql -u $username -p$password -h $host ${options[*]}"
        mysql -u "$username" -p"$password" -h "$host" "${options[@]}"
    else
        logInfo "Executing: mysql -u $username -p$password -h $host -P $port ${options[*]}"
        mysql -u "$username" -p"$password" -h "$host" -P "$port" "${options[@]}"
    fi
}

function mysqlo() { #? Connect mysql by mapping THEN pass command and output result to files
    [ -z "$2" ] && logError "Need Command" && return 1
    [ -z "$3" ] && logError "Need Output File" && return 1
    mysqlc -e "$2 INTO OUTFILE '$3' FIELDS TERMINATED BY ',';"
}