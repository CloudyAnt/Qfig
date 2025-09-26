#? Ssh related commands.
#? You need to edit the ssh mapping file by execute 'qmap ssh'. A ssh mapping like: a=user@111.222.333.444:555
#? You also need to edit the pem mapping file by execute 'qmap pem' if needed. A pem mapping like: a=/path/to/pem
#? Use csjump to jump, the ssh mapping should be like: a=jump_user@server_user@server_ip@jump_ip:jump_port

# Resolve ssh & pem mappings
qmap -c ssh _SSH_MAPPING
qmap -c pem _PEM_MAPPING

function +ssh:checkMapping() { #x
    local key="$1"
    local checkPem="$2"
    if [ -z "$key" ]; then
        logError "Please specify the ssh mapping key!" && return 1
    fi
    if [ -z "${_SSH_MAPPING[$key]}" ]; then
        logWarn "No ssh mapping for: $key. Use 'qmap ssh' to add." && return 1
    fi
    if [ "$checkPem" ] && [ -z "${_PEM_MAPPING[$key]}" ]; then
        logWarn "No pem mapping for: $key. Use 'qmap pem' to add." && return 1
    fi
}

function cs() { #? connect server. Usage: cs mapping; cs mapping 'your remote command'
    if ! +base:checkParams "mapping" "$1"; then return 1; fi
    if ! +ssh:checkMapping "$1"; then return 1; fi
    local _SshEndpoint=${_SSH_MAPPING[$1]}

    ssh "ssh://$_SshEndpoint" "$2"
}

function csc() { #? connect server & send command. Usage: csc mapping 'your remote command'
    if ! +base:checkParams "mapping" "$1" "command" "$2"; then return 1; fi
    if ! +ssh:checkMapping "$1"; then return 1; fi
    [ -z "$2" ] && logWarn "Need command" && return # check command
    local _SshEndpoint=${_SSH_MAPPING[$1]}
     
    ssh "ssh://$_SshEndpoint" "$2"
}

function csi() { #? connect server (or send command) with pem. Usage: csi mapping; csi mapping 'your remote command'
    if ! +base:checkParams "mapping" "$1"; then return 1; fi
    if ! +ssh:checkMapping "$1" 1; then return 1; fi
    local _SshEndpoint=${_SSH_MAPPING[$1]}
    local _PemFile=${_PEM_MAPPING[$1]}

    ssh -i "$_PemFile" "ssh://$_SshEndpoint" "$2"
}

function cpt() { #? copy to server. Usage: cpt localFile mapping remoteFile[optional] pem[optional]
    if ! +base:checkParams "local file" "$1" "mapping" "$2"; then return 1; fi
    if ! +ssh:checkMapping "$2"; then return 1; fi
    local _SshEndpoint=${_SSH_MAPPING[$2]}

    local lf="$1"
    local rf="$3"
    if [ -z "$rf" ]; then
        logInfo "Coping file to remote user home as name \e[1m$lf\e[0m"
        rf=$lf
    fi
    local pem=$4
    if [ -z "$pem" ]; then
        scp "$lf" "$_SshEndpoint:$rf"
    else
        [ ! -f "$pem" ] && logError "Specified pem file $pem doesn't exists!" && return 1
        scp -i "$pem" "$lf" "$_SshEndpoint:$rf"
    fi
}

function cpti() { #? copy to server with pem. Usage: cpti localFile mapping remoteFile
    if ! +base:checkParams "local file" "$1" "mapping" "$2" "remote file" "$3"; then return 1; fi
    if ! +ssh:checkMapping "$2" 1; then return 1; fi
    local _SshEndpoint=${_SSH_MAPPING[$2]}
    local _PemFile=${_PEM_MAPPING[$2]}

    logInfo "Transferring $1 to $_SshEndpoint:$3"
    scp -i "$_PemFile" "$1" "$_SshEndpoint:$3"
}

function cprt() { #? recursively copy entire directories to server. Usage: cprt dir mapping remoteDir pem[optional]
    if ! +base:checkParams "local dir" "$1" "mapping" "$2" "remote dir" "$3"; then return 1; fi
    if ! +ssh:checkMapping "$2"; then return 1; fi
    local _SshEndpoint=${_SSH_MAPPING[$2]}

    if [ -z "$4" ]
    then
        scp -r "$1" "$_SshEndpoint:$3"
    else
        [ ! -f "$4" ] && logError "Specified pem file $4 doesn't exists!" && return 1
        scp -r -i "$4" "$1" "$_SshEndpoint:$3"
    fi
}

function cpf() { #? copy from server. Usage: cpf remoteFile mapping localFile pem[optional]
    if ! +base:checkParams "remote file" "$1" "mapping" "$2" "local file" "$3"; then return 1; fi
    if ! +ssh:checkMapping "$1"; then return 1; fi
    local _SshEndpoint=${_SSH_MAPPING[$1]}

    if [ -z "$4" ]
    then
        scp "$_SshEndpoint:$2" "$3"
    else
        [ ! -f "$4" ] && logError "Specified pem file $4 doesn't exists!" && return 1
        scp -i "$4" "$_SshEndpoint:$2" "$3"
    fi
}

function cpfi() { #? copy from server with pem. Usage: cpfi remoteFile mapping localFile
    if ! +base:checkParams "remote file" "$1" "mapping" "$2" "local file" "$3"; then return 1; fi
    if ! +ssh:checkMapping "$1" 1; then return 1; fi
    local _SshEndpoint=${_SSH_MAPPING[$1]}
    local _PemFile=${_PEM_MAPPING[$1]}

    scp -i "$_PemFile" "$_SshEndpoint:$2" "$3"
}

function cprf() { #? copy folder from sever. cprf remoteDir mapping localDir pem[optional]
    if ! +base:checkParams "remote dir" "$1" "mapping" "$2" "local dir" "$3"; then return 1; fi
    if ! +ssh:checkMapping "$1"; then return 1; fi
    local _SshEndpoint=${_SSH_MAPPING[$1]}

    if [ -z "$4" ]
    then
        scp -r "$_SshEndpoint:$2" "$3"
    else
        [ ! -f "$4" ] && logError "Specified pem file $4 doesn't exists!" && return 1
        scp -r -i "$4" "$_SshEndpoint:$2" "$3"
    fi
}

function cprfi() { #? copy folder from sever. Usage: cprfi remoteDir mapping localDir
    if ! +base:checkParams "remote dir" "$1" "mapping" "$2" "local dir" "$3"; then return 1; fi
    if ! +ssh:checkMapping "$1" 1; then return 1; fi
    local _SshEndpoint=${_SSH_MAPPING[$1]}
    local _PemFile=${_PEM_MAPPING[$1]}

    scp -r -i "$_PemFile" "$4" "$_SshEndpoint:$2" "$3"
}

function sshcopyid() { #? copy ssh id to server
    if ! +base:checkParams "mapping" "$1" ; then return 1; fi
    if ! +ssh:checkMapping "$1"; then return 1; fi
    local _SshEndpoint=${_SSH_MAPPING[$1]}

    ssh-copy-id "$_SshEndpoint"
}

function csjump() { #? connect server through a jump server
    if ! +base:checkParams "mapping" "$1"; then return 1; fi
    if ! +ssh:checkMapping "$1" 1; then return 1; fi
    local _SshEndpoint=${_SSH_MAPPING[$1]}
    local _PemFile=${_PEM_MAPPING[$1]}

    if [[ "$_SshEndpoint" =~  ^[[:alnum:]_-]+@[[:alnum:]_-]+@[[:alnum:]._-]+@[[:alnum:]._-]+$ ]]; then
      ssh -i "$_PemFile" "$_SshEndpoint"
    elif [[ "$_SshEndpoint" =~  ^[[:alnum:]_-]+@[[:alnum:]_-]+@[[:alnum:]._-]+@[[:alnum:]._-]+:([[:digit:]]+)$ ]]; then
      # specify a port
      local port=$(getMatch 1)
      ssh -p "$port" -i "$_PemFile" "${_SshEndpoint%:*}"
    else
      logError "Invalid ssh mapping !"
    fi
}