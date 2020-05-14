function es() {
    es_user=jiaqichai

    es_server=$1
    if [ "$es_server" = "" ]
    then
        return
    fi

    es_host="58.132.205.49"
    case $es_server in "ot10") es_port="60100";;
    "ot11") es_port="60101";;
    "tt16") ps_port="60106";;
    "op126") es_user=es_root es_host="39.96.11.126" es_port="22";;
    "op208") es_user=root es_host="39.97.171.208" es_port="22";;
    *) return;;
    esac

    ssh -p $es_port $es_user@$es_host
    return
}

function msct(){
    git add .
    echo "Commit with message: [chai] $1 $2 ?"
    read c
    if [ "$c" == "Y"]
    then
        git commit -m "[chai] $1: $2"
    else
        echo "Not commit"
    fi
}

# Git related operations
function gadd() {
    git add -A
}

function gct() {
    defaultV default_commit_name chaijiaqi
    defaultV default_commit_number N/A 
    defaultV default_commit_desc Unknown

    echo "What's your name? ($default_commit_name)"
    read commit_name
    echo "What's your card number? ($default_commit_number)"
    read commit_number
    echo "What did you do? ($default_commit_desc)"
    read commit_desc

    defaultV commit_name $default_commit_name
    defaultV commit_number $default_commit_number
    defaultV commit_desc $default_commit_desc

    default_commit_name=$commit_name
    default_commit_number=$commit_number
    default_commit_desc=$commit_desc

    commit_message="$commit_name [$commit_number] $commit_desc"

    git commit -m "$commit_message"
    
    unset commit_name
    unset commit_number
    unset commit_desc
    unset commit_message
}

# if variable with name $1 is blank, give it value $2
function defaultV() {
    value_name=$1
    default_value=$2

    [ -z "$value_name" ] && return

    eval "real_value=\$$value_name"

    [ -z "$real_value" ] && eval "$value_name='$default_value'"

    unset value_name
    unset default_value
    unset real_value
}


# temporary
function old_addgi() {
    echo -e "# idea\n.idea\n*.iml\n\n# build\nbuild\ntarget\nout" > .gitignore
    git add .gitignore
    git rm -r --cached .idea > /dev/null 2>&1
    git rm -r --cached build > /dev/null 2>&1
    git rm -r --cached target > /dev/null 2>&1
    git rm -r --cached out > /dev/null 2>&1
    git rm --cached *.iml > /dev/null 2>&1

    echo "Commit and Push? (y | others)"
    read c
    if [ "$c" != "y" ]
    then
        return
    fi
    unset $c


    git commit -m "[chaijiaqi, N/A] refactor: remove unnecessary git track"
    git push
}

function forexec() {
    begin=`pwd`
    command=$1

    if [ "$begin" = "" ]
    then
        return
    fi

    for d in *; do
        cd "$begin/$d"
        `$command`
    done

    cd $begin
}
