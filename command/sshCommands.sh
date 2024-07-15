#? Ssh related commands.
#? You need to edit the ssh mapping file by execute 'qmap ssh'. A ssh mapping like: a=user@111.222.333.444:555
#? You also need to edit the pem mapping file by execute 'qmap pem' if needed. A pem mapping like: a=/path/to/pem

_SSH_MAPPING_FILE=$_QFIG_LOCAL/sshMappingFile
_PEM_MAPPING_FILE=$_QFIG_LOCAL/pemMappingFile

# Resolve ssh & pem mappings
[ ! -f $_SSH_MAPPING_FILE ] && touch $_SSH_MAPPING_FILE
eval `cat $_SSH_MAPPING_FILE | awk -F '=' 'BEGIN{ s = "declare -g -A _SSH_MAPPING; _SSH_MAPPING=("} \
{ if ( NF >= 2) s = s " [" $1 "]=" $2; } \
END { s = s ")"; print s}'`

[ ! -f $_PEM_MAPPING_FILE ] && touch $_PEM_MAPPING_FILE
eval `cat $_PEM_MAPPING_FILE | awk -F '=' 'BEGIN{ s = "declare -g -A _PEM_MAPPING; _PEM_MAPPING=("} \
{ if ( NF >= 2) s = s " [" $1 "]=" $2; } \
END { s = s ")"; print s}'`

function checkMapping() {
    local key="$1"
    local checkPem="$2"
    if [ -z "$key" ]; then
        logError "Please specify the ssh mapping key!" && return 1
    fi
    if [ -z "${_SSH_MAPPING[$key]}" ]; then
        logWarn "No ssh mapping for: $key" && return 1
    fi
    if [ "$checkPem" ] && [ -z "${_PEM_MAPPING[$key]}" ]; then
        logWarn "No pem mapping for: $key" && return 1
    fi
}

function cs() { #? connect server. Usage: cs mapping; cs mapping 'your remote command'
    if ! checkMapping "$1"; then return 1; fi
    local _SshEndpoint=${_SSH_MAPPING[$1]}

    ssh "ssh://$_SshEndpoint" "$2"
}

function csc() { #? connect server & send command. Usage: csc mapping 'your remote command'
    if ! checkMapping "$1"; then return 1; fi
    [ -z "$2" ] && logWarn "Need command" && return # check command
    local _SshEndpoint=${_SSH_MAPPING[$1]}
     
    ssh "ssh://$_SshEndpoint" "$2"
}

function csi() { #? connect server (or send command) with pem. Usage: csi mapping; csi mapping 'your remote command'
    if ! checkMapping "$1" 1; then return 1; fi
    local _SshEndpoint=${_SSH_MAPPING[$1]}
    local _PemFile=${_PEM_MAPPING[$1]}

    ssh -i "$_PemFile" "ssh://$_SshEndpoint" "$2"
}

function cpt() { #? copy to server. Usage: cpt localFile mapping remoteFile pem[optional]
    if ! checkMapping "$2"; then return 1; fi
    local _SshEndpoint=${_SSH_MAPPING[$2]}

    [ ! -f "$4" ] && logError "Specified pem file $4 doesn't exists!" && return 1
    if [ -z "$4" ]
    then
        scp "$1" "$_SshEndpoint:/$3"
    else
        scp -i "$4" "$1" "$_SshEndpoint:/$3"
    fi
}

function cpti() { #? copy to server with pem. Usage: cpti localFile mapping remoteFile
    if ! checkMapping "$2" 1; then return 1; fi
    local _SshEndpoint=${_SSH_MAPPING[$2]}
    local _PemFile=${_PEM_MAPPING[$2]}

    logInfo "Transferring $1 to $_SshEndpoint:/$3"
    scp -i "$_PemFile" "$1" "$_SshEndpoint:/$3"
}

function cprt() { #? recursively copy entire directories to server. Usage: cprt dir mapping remoteDir pem[optional]
    if ! checkMapping "$2"; then return 1; fi
    local _SshEndpoint=${_SSH_MAPPING[$2]}

    [ ! -f "$4" ] && logError "Specified pem file $4 doesn't exists!" && return 1
    if [ -z "$4" ]
    then
        scp -r "$1" "$_SshEndpoint:/$3"
    else
        scp -r -i "$4" "$1" "$_SshEndpoint:/$3"
    fi
}

function cpf() { #? copy from server. Usage: cpf remoteFile mapping localFile pem[optional]
    if ! checkMapping "$1"; then return 1; fi
    local _SshEndpoint=${_SSH_MAPPING[$1]}

    [ ! -f "$4" ] && logError "Specified pem file $4 doesn't exists!" && return 1
    if [ -z "$4" ]
    then
        scp "$_SshEndpoint:/$2" "$3"
    else
        scp -i "$4" "$_SshEndpoint:/$2" "$3"
    fi
}

function cpfi() { #? copy from server with pem. Usage: cpfi remoteFile mapping localFile
    if ! checkMapping "$1" 1; then return 1; fi
    local _SshEndpoint=${_SSH_MAPPING[$1]}
    local _PemFile=${_PEM_MAPPING[$1]}

    scp -i "$_PemFile" "$_SshEndpoint:/$2" "$3"
}

function cprf() { #? copy folder from sever. cprf folder mapping localFile pem[optional]
    if ! checkMapping "$1"; then return 1; fi
    local _SshEndpoint=${_SSH_MAPPING[$1]}

    [ ! -f "$4" ] && logError "Specified pem file $4 doesn't exists!" && return 1
    if [ -z "$4" ]
    then
        scp -r "$_SshEndpoint:/$2" "$3"
    else
        scp -r -i "$4" "$_SshEndpoint:/$2" "$3"
    fi
}

function cprfi() { #? copy folder from sever. Usage: cprfi folder mapping localFile
    if ! checkMapping "$1" 1; then return 1; fi
    local _SshEndpoint=${_SSH_MAPPING[$1]}
    local _PemFile=${_PEM_MAPPING[$1]}

    scp -r -i "$_PemFile" "$4" "$_SshEndpoint:/$2" "$3"
}

function sshcopyid() { #? copy ssh id to server
    if ! checkMapping "$1"; then return 1; fi
    local _SshEndpoint=${_SSH_MAPPING[$1]}

    ssh-copy-id "$_SshEndpoint"
}