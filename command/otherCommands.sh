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

function remove_idea_bad_git_track() {
    # include idea, .idea, *.iml, build, target, out 
    echo -e "# idea\n.idea\n*.iml\n\n# build\nbuild\ntarget\nout" > .gitignore
    git add .gitignore
    git rm -r --cached .idea > /dev/null 2>&1
    git rm -r --cached build > /dev/null 2>&1
    git rm -r --cached target > /dev/null 2>&1
    git rm -r --cached out > /dev/null 2>&1
    git rm --cached *.iml > /dev/null 2>&1
}

function recursive() {
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
