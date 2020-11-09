# Ssh mapping. You need to edit the sshMappingFile
# a mapping should like: a=user@111.222.333.444:555

_SSH_MAPPING_FILE=$Qfig_loc/sshMappingFile

# Resolve ssh mappings
[ ! -f $_SSH_MAPPING_FILE ] && touch $_SSH_MAPPING_FILE
eval `cat $_SSH_MAPPING_FILE | awk -F '=' 'BEGIN{ s = "declare -A _SSH_MAPPING; _SSH_MAPPING=("} \
{ if ( NF >= 2) s = s " [" $1 "]=" $2; } \
END { s = s ")"; print s}'`


function cs() { #? connect server. syntax: cs mapping 
    [ -z "$1" ] || [ -z $_SSH_MAPPING[$1] ] && return # need mapping
    _SshEndpoint=$_SSH_MAPPING[$1]

    if [[ -z "$2" || ! -f "$2" ]] 
    then
        ssh ssh://$_SshEndpoint
    else
        ssh -i $2 ssh://$_SshEndpoint
    fi
}

function cpt() {
    [ -z "$2" ] || [ -z $_SSH_MAPPING[$2] ] && return # need mapping
    _SshEndpoint=$_SSH_MAPPING[$2]

    if [[ -z "$4" || ! -f "$4" ]] 
    then
        scp $1 $_SshEndpoint:/$3
    else
        scp -i $4 $1 $_SshEndpoint:/$3
    fi
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

function cpf() {
    [ -z "$1" ] || [ -z $_SSH_MAPPING[$1] ] && return # need mapping
    _SshEndpoint=$_SSH_MAPPING[$1]

    if [[ -z "$4" || ! -f "$4" ]] 
    then
        scp $_SshEndpoint:/$2 $3
    else
        scp -i $4 $_SshEndpoint:/$2 $3
    fi
}

function cprf() {
    [ -z "$1" ] || [ -z $_SSH_MAPPING[$1] ] && return # need mapping
    _SshEndpoint=$_SSH_MAPPING[$1]

    if [[ -z "$4" || ! -f "$4" ]] 
    then
        scp -r $_SshEndpoint:/$2 $3
    else
        scp -r -i $4 $_SshEndpoint:/$2 $3
    fi
}

