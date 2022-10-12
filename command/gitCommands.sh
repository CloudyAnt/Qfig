# Git related

alias glog='git log --oneline --abbrev-commit --graph'
alias gamd='git commit --amend'
alias gamdn='git commit --amend --no-edit'
alias gaap='git add -p'
alias glist='git stash list --date=local'
alias glistp='git stash list --pretty=format:"%C(red)%h%C(reset) - %C(dim yellow)(%C(bold magenta)%gd%C(dim yellow))%C(reset) %<(70,trunc)%s %C(green)(%cr) %C(bold blue)<%an>%C(reset)"'
alias gp='logWarn "FORBIDDEN ALIAS"'

## offical
# gaa = git add --A
# gst = git status
# gss = git status -s
# gco = git checkout
# glo = git log --oneline

function grmc() { #? git rm --cached xx
    [ -z $1 ] && return
    git rm --cached $1
}

function gmergec() { #? git merge --continue
    gaa
    git merge --continue
}

function grebasec() { #? git rebase --continue
    gaa
    git rebase --continue
}

function gpr() { #? git pull --rebase
    git pull --rebase
}

function gaaf() { #? git add files in pattern
    [ -z $1 ] && return
    git add "*$1*"
}

function gbco() { #? git branch foo && git checkout foo
    [ -z $1 ] && return
	git branch $1
	git checkout $1
}

function gcm() { #? commit with message
	if [ "$1" = '' ]
	then 
		logWarn "Commit without message?"
		qread confirm
		[ "$confirm" = "y" ] && gaa && git commit -m "" 
	else
		gaa
		git commit -m "$1"
	fi
}

function gcto() { #? commit in one line
    echo commit with message '"['$1']' $2: $3'" ? (y for Yes)'
    qread oneline_commit
    [ "$oneline_commit" = "y" ] && gaa && git commit -m "[$1] $2: $3"
    unset oneline_commit
}

gctCommitTypes=(refactor fix feat chore doc test style)
gctCommitTypesTip=`echo $gctCommitTypes | awk '{for (i = 1; i <= NF; i++) { printf " \033[1;3" i "m" i ":" $i }} END{printf "\033[0m"}'`

function gct() { #? commit in process
    # CHECK if this is a git repository
    [ ! "`git rev-parse --is-inside-work-tree 2>&1`" = 'true' ] && logError "Not a git repository!" && return
    
    # CHECK if it's need to commit
    needToCommit=`gst | awk '/Changes to be committed/{print 1}'`
    [ -z $needToCommit ] && logWarn "Nothing to commit!" && return

    # GET commit message cache, use default if it not exists
    git_commit_info_cache_folder=$Qfig_loc/.gcache
    present_working_repository_cache=$git_commit_info_cache_folder/`git rev-parse --show-toplevel | sed 's|/|_|g'`.tmp

    [ ! -d "$git_commit_info_cache_folder" ] && mkdir $git_commit_info_cache_folder

    info_separator="!@#!@#!@#"

    if [ -f "$present_working_repository_cache" ]
    then
        eval `cat $present_working_repository_cache | awk  -F $info_separator '{print "commit_name0=\"" $1 "\";commit_number0=\"" $2 "\";commit_type0=\"" $3 "\";commit_desc0=\"" $4 "\""}'`
    fi

    defaultV commit_name0 "Unknown"
    defaultV commit_number0 "N/A"
    defaultV commit_type0 "other"
    defaultV commit_desc0 "Unknown"

    # COMMIT step by step
    echo "[1/4] Name? ($commit_name0)"
    qread commit_name
    echo "[2/4] Card? ($commit_number0)"
    qread commit_number
    echo "[3/4] Type? ($commit_type0) |$gctCommitTypesTip"
    qread commit_type

    if echo $commit_type | egrep -q '^[0-9]+$' && [ $commit_type -gt 0 ] && [ $commit_type -le ${#gctCommitTypes} ]
    then
        echo "\033[1;3${commit_type}m$gctCommitTypes[$commit_type]\033[0m"
        commit_type=$gctCommitTypes[$commit_type]   
    fi

    echo "[4/4] Note? ($commit_desc0)"
    qread commit_desc

    defaultV commit_name $commit_name0
    defaultV commit_number $commit_number0
    defaultV commit_type $commit_type0
    defaultV commit_desc $commit_desc0

    # cache new info
    echo "$commit_name$info_separator$commit_number$info_separator$commit_type$info_separator$commit_desc" > $present_working_repository_cache

    # commit
    full_commit_message="$commit_name [$commit_number] $commit_type: $commit_desc"
    git commit -m "$full_commit_message"

}

_git_stash_key="_git_stash_:"

function gstash() { #? git stash
    if [ -z "$1" ] 
    then
        git stash
        return
    fi
    git stash push -m "$_git_stash_key""$1" # stash with specific name
}

function gstashu() { #? git stash unstaged files 
    if [ -z "$1" ] 
    then
        git stash --keep-index
        return
    fi
    git stash push -m "$_git_stash_key""$1" --keep-index # stash with specific name
}

function gapply() { #? git stash apply 
    if [ -z "$1" ] 
    then
        git stash apply
        return
    fi
    key=$(git stash list | grep "$_git_stash_key""$1" | cut -d: -f1)
    [ -z "$key"] && logWarn "The stash key \"$1\" doesn't exist!" && return
    git stash apply $key # apply with specific name
}

function gpop() { #? git stash pop 
    if [ -z "$1" ] 
    then
        git stash pop
        return
    fi
    key=$(git stash list | grep "$_git_stash_key""$1" | cut -d: -f1)
    [ -z "$key"] && logWarn "The stash key \"$1\" doesn't exist!" && return
    git stash pop $key # pop with specific name
}

function gcst() { #? check multi folder commit status
    [ -z "$1" ] && gcst0 `pwd` && return
    present_directory=`pwd`
    for file in $1/* ; do
        gcst0 $file -p
    done
    cd $present_directory
}

function gcst0() { #? check single folder commit status
    [[ ! -d "$1" || ! -d "$1/.git" ]] && return
    cd $1
    [ "-p" = "$2" ] && echo $file | awk -F '/' '{print "\033[1;34m" $NF ":\033[0m" }'
    git status | awk '/Your branch is/{print}' | awk '{sub("Your branch is ", "")} 1' \
        | awk '{sub("up to date", "\033[1;32mUP TO DATE\033[0m")} 1' \
        | awk '{sub("ahead", "\033[1;31mAHEAD\033[0m")} 1' 
}
