# Ssh mapping. 
# You need to edit the sshMappingFile. A mapping should like: a=user@111.222.333.444:555

_SSH_MAPPING_FILE=$Qfig_loc/sshMappingFile
_PEM_MAPPING_FILE=$Qfig_loc/pemMappingFile

# Resolve ssh & pem mappings
# TODO optimze these 2 mapping
[ ! -f $_SSH_MAPPING_FILE ] && touch $_SSH_MAPPING_FILE
eval `cat $_SSH_MAPPING_FILE | awk -F '=' 'BEGIN{ s = "declare -A _SSH_MAPPING; _SSH_MAPPING=("} \
{ if ( NF >= 2) s = s " [" $1 "]=" $2; } \
END { s = s ")"; print s}'`

[ ! -f $_PEM_MAPPING_FILE ] && touch $_PEM_MAPPING_FILE
eval `cat $_PEM_MAPPING_FILE | awk -F '=' 'BEGIN{ s = "declare -A _PEM_MAPPING; _PEM_MAPPING=("} \
{ if ( NF >= 2) s = s " [" $1 "]=" $2; } \
END { s = s ")"; print s}'`


function cs() { #? connect server. syntax: cs mapping; cs mapping identification[optional] 
    [ -z "$1" ] || [ -z $_SSH_MAPPING[$1] ] && return # need mapping
    _SshEndpoint=$_SSH_MAPPING[$1]

    ssh ssh://$_SshEndpoint $2
}

function csc() { #? connect server & send command. syntax: csc mapping command
    [ -z "$1" ] || [ -z $_SSH_MAPPING[$1] ] && logWarn "Need available mapping" && return # check mapping 
    [ -z "$2" ] && logWarn "Need command" && return # check command 
    _SshEndpoint=$_SSH_MAPPING[$1]
     
    ssh ssh://$_SshEndpoint $2 
}

function csi() { #? connect server (send command) with identification. syntax: csi mapping; csi mapping command[optional]
    [ -z "$1" ] || [ -z $_SSH_MAPPING[$1] ] || [ -z $_PEM_MAPPING[$1] ] && return # need mapping
    _SshEndpoint=$_SSH_MAPPING[$1]
    _PemFile=$_PEM_MAPPING[$1]

    ssh -i $_PemFile ssh://$_SshEndpoint $2
}

function cpt() { #? copy to server. syntax: cpt localFile mapping remoteFile identification[optional]
    [ -z "$2" ] || [ -z $_SSH_MAPPING[$2] ] && return # need mapping
    _SshEndpoint=$_SSH_MAPPING[$2]

    if [[ -z "$4" || ! -f "$4" ]] 
    then
        scp $1 $_SshEndpoint:/$3
    else
        scp -i $4 $1 $_SshEndpoint:/$3
    fi
}

function cpti() { #? copy to server with identification. syntax: cpti localFile mapping remoteFile 
    [ -z "$2" ] || [ -z $_SSH_MAPPING[$2] ] || [ -z $_PEM_MAPPING[$2] ] && logWarn "No Mapping For:$2" && return # need mapping
    _SshEndpoint=$_SSH_MAPPING[$2]
    _PemFile=$_PEM_MAPPING[$2]

    logInfo "Tarnsferring $1 to $_SshEndpoint:/$3"
    scp -i $_PemFile $1 $_SshEndpoint:/$3
}

function cprt() {
    [ -z "$2" ] || [ -z $_SSH_MAPPING[$2] ] && return # need mapping
    _SshEndpoint=$_SSH_MAPPING[$2]

    if [[ -z "$4" || ! -f "$4" ]] 
    then
        scp -r $1 $_SshEndpoint:/$3
    else
        scp -r -i $4 $1 $_SshEndpoint:/$3
    fi
}

function cpf() { #? copy from server. syntax: cpf remoteFile mapping localFile identification[optional]
    [ -z "$2" ] || [ -z $_SSH_MAPPING[$2] ] && return # need mapping
    _SshEndpoint=$_SSH_MAPPING[$2]

    if [[ -z "$4" || ! -f "$4" ]] 
    then
        scp $_SshEndpoint:/$1 $3
    else
        scp -i $4 $_SshEndpoint:/$1 $3
    fi
}

function cpfi() { #? copy from server with identification. syntax: cpfi romoteFile mapping localFile
    [ -z "$2" ] || [ -z $_SSH_MAPPING[$2] ] || [ -z $_PEM_MAPPING[$2] ] && return # need mapping
    _SshEndpoint=$_SSH_MAPPING[$2]
    _PemFile=$_PEM_MAPPING[$2]

    scp -i $_PemFile $_SshEndpoint:/$1 $3
}

function cprf() { #! [UNTESTED] copy folder from sever
    [ -z "$1" ] || [ -z $_SSH_MAPPING[$1] ] && return # need mapping
    _SshEndpoint=$_SSH_MAPPING[$1]

    if [[ -z "$4" || ! -f "$4" ]] 
    then
        scp -r $_SshEndpoint:/$2 $3
    else
        scp -r -i $4 $_SshEndpoint:/$2 $3
    fi
}

function cprfi() { #! [UNTESTED] copy folder from sever
    [ -z "$1" ] || [ -z $_SSH_MAPPING[$1] ] && return # need mapping
    _SshEndpoint=$_SSH_MAPPING[$1]
    _PemFile=$_PEM_MAPPING[$2]

    if [[ -z "$4" || ! -f "$4" ]] 
    then
        scp -r $_PemFile $_SshEndpoint:/$2 $3
    else
        scp -r -i $_PemFile $4 $_SshEndpoint:/$2 $3
    fi
}
