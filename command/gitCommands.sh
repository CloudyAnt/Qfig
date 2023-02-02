# Git related

alias glog='git log --oneline --abbrev-commit --graph'
alias gamd='git commit --amend'
alias gamdn='git commit --amend --no-edit'
alias gaap='git add -p'
alias glist='git stash list --date=local'
alias glistp='git stash list --pretty=format:"%C(red)%h%C(reset) - %C(dim yellow)(%C(bold magenta)%gd%C(dim yellow))%C(reset) %<(70,trunc)%s %C(green)(%cr) %C(bold blue)<%an>%C(reset)"'
alias gp='forbiddenAlias gp "git push"'
alias gl='forbiddenAlias gl "git pull"'

## offical
# gaa = git add --A
# gst = git status
# gss = git status -s
# gco = git checkout
# glo = git log --oneline
# gcm = git checkout $(git_main_branch)

function grmc() { #? git rm --cached xx
    [ -z $1 ] && return
    git rm --cached $1
}

function gmergec() { #? git merge --continue
    gaa
    git merge --continue
}

function grbt() { #? git rebase $branch && git tag $branch
    [ -z $1 ] && return
	git rebase $1
	git tag $1	
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

function gctm() { #? commit with message
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
    [ -z "$key" ] && logWarn "The stash key \"$1\" doesn't exist!" && return
    git stash apply $key # apply with specific name
}

function gpop() { #? git stash pop 
    if [ -z "$1" ] 
    then
        git stash pop
        return
    fi
    key=$(git stash list | grep "$_git_stash_key""$1" | cut -d: -f1)
    [ -z "$key" ] && logWarn "The stash key \"$1\" doesn't exist!" && return
    git stash pop $key # pop with specific name
}

function gcst() { #! [DEPRECATED] check multi folder commit status
    [ -z "$1" ] && gcst0 `pwd` && return
    present_directory=`pwd`
    for file in $1/* ; do
        gcst0 $file -p
    done
}

function gcst0() { #! [DEPRECATED] check single folder commit status
    [[ ! -d "$1" || ! -d "$1/.git" ]] && return
    [ "-p" = "$2" ] && echo $file | awk -F '/' '{print "\033[1;34m" $NF ":\033[0m" }'
    git -C $1 status | awk '/Your branch is/{print}' | awk '{sub("Your branch is ", "")} 1' \
        | awk '{sub("up to date", "\033[1;32mUP TO DATE\033[0m")} 1' \
        | awk '{sub("ahead", "\033[1;31mAHEAD\033[0m")} 1' 
}

function ghttpproxy() {
    if [ -z "$1" ]
    then
        git config --global --unset http.proxy
        git config --global --unset https.proxy
        logSuccess "Clean git http/https proxy"
    else
        git config --global http.proxy $1
        git config --global https.proxy $1
        logSuccess "Set git http/https proxy as $1"
    fi
}

function gct() { #? git commit step by step
	# READ flags
	setPattern=""
	while getopts "ph" opt; do
		case $opt in
			h)
				logInfo "A Command to git-commit step by step. specify pattern in .gctpattern or use -p to specify a local pattern
Pattern hint: use '[a:b c d]' to define a step named as a with b, c, d options(the first is default value). Use '\\' to escape
Pattern example: [name] \[[card]\] [type:a b c]: [msg:Default]"
				return
				;;
			p) # specify pattern
				setPattern=1
				;;
			\?)
				logError "Invalid option: -$OPTARG" && return 1
				;;
		esac
	done

    # CHECK if this is a git repository
    [ ! "`git rev-parse --is-inside-work-tree 2>&1`" = 'true' ] && logError "Not a git repository!" && return 1

    # GET pattern & cache, use default if it not exists
	git_toplevel=$(git rev-parse --show-toplevel)
    git_commit_info_cache_folder=$Qfig_loc/.gcache
	[ ! -d "$git_commit_info_cache_folder" ] && mkdir $git_commit_info_cache_folder
	pattern_tokens_file=$git_commit_info_cache_folder/$(echo $git_toplevel | sed 's|/|_|g').ptk
	step_values_cache_file=$git_commit_info_cache_folder/$(echo $git_toplevel | sed 's|/|_|g').svc

	# SET pattern
	repoPattern=".gctpattern"
	boldRepoPattern="\033[1m$repoPattern\033[0m"
	gctpattern_file=$git_toplevel/$repoPattern
	saveToRepo=""
	if [ -f "$gctpattern_file" ]; then
		[ $setPattern ] && logError "Can not specify pattern cause $boldRepoPattern exists, modify it to achieve this" && return 1

		# read from .gctpattern
		pattern=$(cat $gctpattern_file)
		logInfo "Using pattern in $boldRepoPattern"
		[ -f "$pattern_tokens_file" ] && [ "?:$pattern" = "$(head -n 1 $pattern_tokens_file)" ] || setPattern=1
	else
		if [ $setPattern ]; then
			# specify local pattern
			logInfo "Please specify the pattern:"
			qread pattern
		elif [ ! -f "$pattern_tokens_file" ]; then
			setPattern=1
			logInfo "Use default pattern \033[34;3;38m$(cat $Qfig_loc/staff/defaultPattern)\033[0m ? \033[90mY for Yes, others for No.\033[0m" "?"
			qread yn
			if [[ 'y' = "$yn" || 'Y' = "$yn" ]]; then
				logInfo "Using default pattern"
				pattern=$(cat $Qfig_loc/staff/defaultPattern)
			else
				logInfo "Then please specify the pattern(Run with -p to change, -h to get hint):"
				qread pattern
			fi
		fi
		if [ $setPattern ]; then
			# whether save to .gctpattern
			logInfo "Save it in $boldRepoPattern(It may be shared through your git repo) ? \033[90mY for Yes, others for No.\033[0m" "?"
			qread saveToRepo
		fi
	fi

	# RESOLVE pattern
	if [ $setPattern ]; then
		resolveResult=$($Qfig_loc/staff/resolveGctPattern.sh $pattern)
		if [ $? -eq 0 ]; then
			echo "?:$pattern" > $pattern_tokens_file
			echo $resolveResult >> $pattern_tokens_file
			[ -f "$step_values_cache_file" ] && rm $step_values_cache_file
			[[ 'y' = "$saveToRepo" || 'Y' = "$saveToRepo" ]] && echo $pattern > $gctpattern_file && logInfo "Pattern saved in $boldRepoPattern"
			logSuccess "New pattern resolved!"
		else
			logError "Invalid pattern: $resolveResult" && return 1
		fi
	fi

    # CHECK if it's need to commit
    needToCommit=`gst | awk '/Changes to be committed/{print 1}'`
    [ -z $needToCommit ] && logWarn "Nothing to commit!" && return 1

	# GET pattern tokens
	IFS=$'\n' tokens=($(cat $pattern_tokens_file)) IFS=' '

	stepsCount=0
	for t in ${tokens[@]}; do
		if [[ "$t" = 1:* ]]; then
			stepsCount=$((stepsCount + 1))	
		fi
	done
	
	# APPEND message step by step
	message=""
	curStepNum=0	
	[ -f $step_values_cache_file ] && IFS=$'\n' stepValues=($(cat $step_values_cache_file)) IFS=' ' || stepValues=()
	newStepValues=""
	for t in ${tokens[@]}; do
		if [[ "$t" = 1:* ]]; then
			curStepNum=$((curStepNum + 1))
			stepPrompt="\033[33;1;38m[$curStepNum/$stepsCount]\033[0m "
			stepDefValue="${stepValues[$curStepNum]:1}" # caced value start with '>'
			keyAndOptions=(${(@s/:/)${t:2}})
			stepKey=${keyAndOptions[1]}
			stepOptions=(${(@s/ /)${keyAndOptions[2]}})

			# APPEND and show prompt
			stepPrompt+="$stepKey? "
			if [ ! -z "$stepOptions" ]; then
				[ -z "$stepDefValue" ] && stepDefValue=${stepOptions[1]}
				stepPrompt+="($stepDefValue) " 
				if [ 1 -lt "${#stepOptions[@]}" ]; then
					# append option id
					stepPrompt+="|$(echo $stepOptions | awk '{for (i = 1; i <= NF; i++) { printf " \033[1;3" i "m" i ":" $i }} END{printf "\033[0m"}')"
				fi
			else
				[ ! -z "$stepDefValue" ] && stepPrompt+="($stepDefValue) " 
			fi
			echo "$stepPrompt"

			# READ and record value
			qread partial
			if [ 1 -lt "${#stepOptions[@]}" ]; then
				# select by option id
				if echo $partial | egrep -q '^[0-9]+$' && [ $partial -gt 0 ] && [ $partial -le ${#stepOptions} ]
				then
					echo "Selected: \033[1;3${partial}m$stepOptions[$partial]\033[0m"
					partial=$stepOptions[$partial]
				fi
			fi
			[ -z "$partial" ] && partial=$stepDefValue
			message+=$partial
			newStepValues+=">$partial\n" # start width '>' to avoid empty line
		elif [[ "$t" = 0:* ]]; then
			message+=${t:2}
		fi
	done

	echo $newStepValues > $step_values_cache_file

	# COMMIT 
	git commit -m "$message"
}
