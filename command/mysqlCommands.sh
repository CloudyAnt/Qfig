#!/usr/bin/env zsh
#? These are commands about Mysql, make sure it's available before activation.
#? You need to edit the mysql mapping file by execute 'qmap mysql'. A ssh mapping like: key=server:port#username#userpass

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
    hostPort="$mapping[1]:"
    host=$(cut -d":" -f1 <<< $hostPort)
    port=$(cut -d":" -f2 <<< $hostPort)
    if [ -z "$port" ]
    then
        mysql -u $mapping[2] -p$mapping[3] -h $host
    else
        mysql -u $mapping[2] -p$mapping[3] -h $host -P $port
    fi
}

function mysqlo() { #? Connect mysql by mapping defined in mysqlMappingFile THEN pass command and output result to files
    [ -z $1 ] || [ -z $_MYSQL_MAPPING[$1] ] && logError "Which mapping?" && return
    [ -z $2 ] && logError "Need Command" && return
    [ -z $3 ] && logError "Need Output File" && return
    unset mapping
    eval "mapping=($_MYSQL_MAPPING[$1])"
    mysql -u $mapping[2] -p$mapping[3] -h $mapping[1] -e "$2 INTO OUTFILE '$3' FIELDS TERMINATED BY ',';"
}
