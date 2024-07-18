#!/usr/bin/env zsh
#? These are commands about Mysql, make sure it's available before ues.
#? You need to edit the mysql mapping file by execute 'qmap mysql'. A ssh mapping like: key=server:port#username#userpass

alias mysqll='mysql -uroot -p' # Connect local mysql
qmap -c mysql _MYSQL_MAPPING

function mysqlc() { #? Connect mysql by mapping
    [ -z "$1" ] || [ -z "${_MYSQL_MAPPING[$1]}" ] && logError "No corresponding mapping" && return
    toArray "${_MYSQL_MAPPING[$1]}" "#" && declare -a mapping=("${_TEMP[@]}")
    declare -i arrayBase=$(getArrayBase)
    local hostPort="${mapping[$arrayBase]}:"
    local host=$(cut -d":" -f1 <<< $hostPort)
    local port=$(cut -d":" -f2 <<< $hostPort)
    local username=${mapping[$((arrayBase + 1))]}
    local password=${mapping[$((arrayBase + 2))]}
    if [ -z "$port" ]
    then
        mysql -u $username -p$password -h $host
    else
        mysql -u $username -p$password -h $host -P $port
    fi
}

function mysqlo() { #? Connect mysql by mapping THEN pass command and output result to files
    [ -z "$1" ] || [ -z "${_MYSQL_MAPPING[$1]}" ] && logError "No corresponding mapping" && return
    [ -z "$2" ] && logError "Need Command" && return
    [ -z "$3" ] && logError "Need Output File" && return
    declare -a mapping=(${_MYSQL_MAPPING[$1]})
    declare -i arrayBase=$(getArrayBase)
    mysql -u $mapping[$((arrayBaes + 1))] -p$mapping[$((arrayBaes + 2))] -h $mapping[1] -e "$2 INTO OUTFILE '$3' FIELDS TERMINATED BY ',';"
}
