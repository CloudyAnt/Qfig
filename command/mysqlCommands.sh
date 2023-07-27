#!/usr/bin/env zsh
#? These are commands about Mysql, make sure it's available before ues.
#? You need to edit the mysql mapping file by execute 'qmap mysql'. A ssh mapping like: key=server:port#username#userpass

alias mysqll='mysql -uroot -p' # Connect local mysql

_MYSQL_MAPPING_FILE=$_QFIG_LOC/mysqlMappingFile

[ ! -f $_MYSQL_MAPPING_FILE ] && touch $_MYSQL_MAPPING_FILE || :
eval $(awk -F '=' 'BEGIN { s="declare -g -A _MYSQL_MAPPING;" } {
    if (NF >= 3) {
        split($2, parts, "#");
        s = s "_MYSQL_MAPPING[" $1 "]=\"" parts[1] " " parts[2] " " parts[3] "\";";
    }
} END { print s }' $_MYSQL_MAPPING_FILE)

function mysqlc() { #? Connect mysql by mapping
    [ -z "$1" ] || [ -z "${_MYSQL_MAPPING[$1]}" ] && logError "No corrosponding mapping" && return
    declare -a mapping=($(echo ${_MYSQL_MAPPING[$1]}))
    declare -i arrayBase=$(_getArrayBase)
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
    [ -z "$1" ] || [ -z "${_MYSQL_MAPPING[$1]}" ] && logError "No corrosponding mapping" && return
    [ -z "$2" ] && logError "Need Command" && return
    [ -z "$3" ] && logError "Need Output File" && return
    declare -a mapping=(${_MYSQL_MAPPING[$1]})
    declare -i arrayBase=$(_getArrayBase)
    mysql -u $mapping[$((arrayBaes + 1))] -p$mapping[$((arrayBaes + 2))] -h $mapping[1] -e "$2 INTO OUTFILE '$3' FIELDS TERMINATED BY ',';"
}
