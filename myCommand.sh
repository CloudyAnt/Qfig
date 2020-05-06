function es() {
    user=jiaqichai

    server=$1
    if [ "$server" = "" ]
    then
        return
    fi

    host="58.132.205.49"
    case $server in "ot10") port="60100";;
    "ot11") port="60101";;
    "tt16") port="60106";;
    "op126") user=root host="39.96.11.126" port="22";;
    "op208") user=root host="39.97.171.208" port="22";;
    *) return;;
    esac

    ssh -p $port $user@$host
    return
}

function ct() {
    user=chaijiaqi

    echo "What's your name? (chaijiaqi)"
    read name
    echo "What's your card number? (N/A)"
    read cardNumber
    echo "What did you do? (EMPTY)"
    read description

    if [ "$name" = "" ]
    then
        name=$user
    fi

    if [ "$cardNumber" = "" ]
    then
        cardNumber="NA"
    fi

    if [ "$description" = "" ]
    then
        description=""
    fi

    message="$name [$cardNumber] $description"

    git commit -m "$message"
}

function gadd() {
    git add -A
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
