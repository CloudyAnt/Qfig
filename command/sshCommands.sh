# ssh mapping
# a mapping should like: a=111.222.333.444:555

TDMT_LOCAL_SERVER_USER=jiaqichai

TDMT_SSH_MAPPING_FILE=$TDMT_LOC/sshMappingFile

# Resolve ssh mappings
[ ! -f $TDMT_SSH_MAPPING_FILE ] && touch $TDMT_SSH_MAPPING_FILE
eval `cat $TDMT_SSH_MAPPING_FILE | awk -F '=' 'BEGIN{ s = "declare -A TDMT_SSH_MAPPING; TDMT_SSH_MAPPING=("} \
{ if ( NF >= 2) s = s " [" $1 "]=" $2; } \
END { s = s ")"; print s}'`


function cs() { #? if mapping 'a:0.0.0.0:80' exist, 'ca a' will try to '0.0.0.0:80'
    [ -z "$1" ] || [ -z $TDMT_SSH_MAPPING[$1] ] && return

    HostAndPort=$TDMT_SSH_MAPPING[$1]
    
    ssh ssh://$TDMT_LOCAL_SERVER_USER@$HostAndPort
}


function csi() { #? identified cs & login as root
    [ -z "$1" ] || [ -z $TDMT_SSH_MAPPING[$1] ] && return

    HostAndPort=$TDMT_SSH_MAPPING[$1]

    ssh -i $TDMT_SERVER_ID ssh://root@$HostAndPort
}
