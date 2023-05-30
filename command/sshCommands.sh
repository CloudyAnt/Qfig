#? Ssh related commands.
#? You need to edit the ssh mapping file by execute 'qmap ssh'. A ssh mapping like: a=user@111.222.333.444:555
#? You also need to edit the pem mapping file by execute 'qmap pem' if needed. A pem mapping like: a=/path/to/pem

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


function cs() { #? connect server. Usage: cs mapping; cs mapping identification[optional]
    [ -z "$1" ] || [ -z $_SSH_MAPPING[$1] ] && logWarn "No ssh mapping for: $1" && return # need mapping
    local _SshEndpoint=$_SSH_MAPPING[$1]

    ssh ssh://$_SshEndpoint $2
}

function csc() { #? connect server & send command. Usage: csc mapping command
    [ -z "$1" ] || [ -z $_SSH_MAPPING[$1] ] && logWarn "No ssh mapping for: $1" && return # check mapping 
    [ -z "$2" ] && logWarn "Need command" && return # check command 
    local _SshEndpoint=$_SSH_MAPPING[$1]
     
    ssh ssh://$_SshEndpoint $2 
}

function csi() { #? connect server (or send command) with identification. Usage: csi mapping; csi mapping 'your remote command'
    [ -z "$1" ] || [ -z $_SSH_MAPPING[$1] ] || [ -z $_PEM_MAPPING[$1] ] && logWarn "No ssh/pem mapping for: $1" && return # need mapping
    local _SshEndpoint=$_SSH_MAPPING[$1]
    local _PemFile=$_PEM_MAPPING[$1]

    ssh -i $_PemFile ssh://$_SshEndpoint $2
}

function cpt() { #? copy to server. Usage: cpt localFile mapping remoteFile identification[optional]
    [ -z "$2" ] || [ -z $_SSH_MAPPING[$2] ] && logWarn "No ssh mapping for: $2" && return # need mapping
    local _SshEndpoint=$_SSH_MAPPING[$2]

    if [[ -z "$4" || ! -f "$4" ]] 
    then
        scp $1 $_SshEndpoint:/$3
    else
        scp -i $4 $1 $_SshEndpoint:/$3
    fi
}

function cpti() { #? copy to server with identification. Usage: cpti localFile mapping remoteFile
    [ -z "$2" ] || [ -z $_SSH_MAPPING[$2] ] || [ -z $_PEM_MAPPING[$2] ] && logWarn "No ssh/pem Mapping For: $2" && return # need mapping
    local _SshEndpoint=$_SSH_MAPPING[$2]
    local _PemFile=$_PEM_MAPPING[$2]

    logInfo "Tarnsferring $1 to $_SshEndpoint:/$3"
    scp -i $_PemFile $1 $_SshEndpoint:/$3
}

function cprt() { #? recursively copy entire directories to server. Usage: cprt dir mapping remoteDir identification[optional]
    [ -z "$2" ] || [ -z $_SSH_MAPPING[$2] ] && logWarn "No ssh Mapping For: $2" && return # need mapping
    local _SshEndpoint=$_SSH_MAPPING[$2]

    if [[ -z "$4" || ! -f "$4" ]] 
    then
        scp -r $1 $_SshEndpoint:/$3
    else
        scp -r -i $4 $1 $_SshEndpoint:/$3
    fi
}

function cpf() { #? copy from server. Usage: cpf remoteFile mapping localFile identification[optional]
    [ -z "$1" ] || [ -z $_SSH_MAPPING[$1] ] && logWarn "No ssh Mapping For: $1" && return # need mapping
    local _SshEndpoint=$_SSH_MAPPING[$1]

    if [[ -z "$4" || ! -f "$4" ]] 
    then
        scp $_SshEndpoint:/$2 $3
    else
        scp -i $4 $_SshEndpoint:/$2 $3
    fi
}

function cpfi() { #? copy from server with identification. Usage: cpfi romoteFile mapping localFile
    [ -z "$1" ] || [ -z $_SSH_MAPPING[$1] ] || [ -z $_PEM_MAPPING[$1] ] && logWarn "No ssh/pem Mapping For: $1" && return # need mapping
    local _SshEndpoint=$_SSH_MAPPING[$1]
    local _PemFile=$_PEM_MAPPING[$1]

    scp -i $_PemFile $_SshEndpoint:/$2 $3
}

function cprf() { #! [UNTESTED] copy folder from sever
    [ -z "$1" ] || [ -z $_SSH_MAPPING[$1] ] && logWarn "No ssh Mapping For: $1" && return # need mapping
    local _SshEndpoint=$_SSH_MAPPING[$1]

    if [[ -z "$4" || ! -f "$4" ]] 
    then
        scp -r $_SshEndpoint:/$2 $3
    else
        scp -r -i $4 $_SshEndpoint:/$2 $3
    fi
}

function cprfi() { #! [UNTESTED] copy folder from sever
    [ -z "$1" ] || [ -z $_SSH_MAPPING[$1] ] && logWarn "No ssh/pem Mapping For: $1" && return # need mapping
    local _SshEndpoint=$_SSH_MAPPING[$1]
    local _PemFile=$_PEM_MAPPING[$1]

    if [[ -z "$4" || ! -f "$4" ]] 
    then
        scp -r $_PemFile $_SshEndpoint:/$2 $3
    else
        scp -r -i $_PemFile $4 $_SshEndpoint:/$2 $3
    fi
}
