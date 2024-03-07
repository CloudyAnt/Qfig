#? Git related

function combiningGit() { #x
	if ! git diff --cached --quiet --exit-code; then
		# commit first
		git add -A
		git commit
	fi
	git $@ | awk '{if(/^CONFLICT /){print "\033[31m" $0 "\033[0m" }else{print $0}}'
}

alias gaa='git add -A'
alias gaap='git add -p'
alias gamd='git commit --amend'
alias gamdn='git commit --amend --no-edit'
alias gco='git checkout'
alias gco-='git checkout -'
alias gcp='combiningGit cherry-pick'
alias gcpa='git cherry-pick --abort'
alias gcpc='combiningGit cherry-pick --continue'
alias glo='git log --oneline'
alias glog='git log --oneline --abbrev-commit --graph'
#? find dangling commits
alias glogdc='git log --graph --oneline --decorate $( git fsck --no-reflog | awk "/dangling commit/ {print $3}" )'
alias gmg='combiningGit merge'
alias gmg-='combiningGit merge -'
alias gmga='git merge --abort'
alias gmgc='git merge --continue'
alias gpr='combiningGit pull --rebase'
alias grb='combiningGit rebase'
alias grb-='combiningGit rebase -'
alias grba='git rebase --abort'
alias grbc='combiningGit rebase --continue'
alias grmc='git rm --cached'
alias gst='git status'
alias gss='git status -s'
alias gfa='git fetch --all'
forbidAlias gp gpush "git push"
forbidAlias gl "git pull"
forbidAlias gc gct "git commit"
forbidAlias gap gapply
unsetAlias gb

function gt() { #? operate tag. Usage: gtag $tag(optional) $cmd(default 'create') $cmdArg(optional). gtag -h for more
	# CHECK if this is a git repository
    isNotGitRepository && return 1
	if [ -z $1 ]; then
		git tag --points-at # --points-at defaults to HEAD
	elif [ "-h" = "$1" ]; then
		logInfo "Usage: gtag \$tag(optional) \$cmd(default 'create') \$cmdArg(optional).
  \e[1mIf no params passed (gtag), show the tags on current commit\e[0m
  Available commands:\n"
		printf "    %-18s%s\n" "c/create" "Default. Create a tag on current commit"
		printf "    %-18s%s\n" "p/push" "Push the tag to remote"
		printf "    %-18s%s\n" "d/delete" "Delete the tag"
		printf "    %-18s%s\n" "dr/delete-remote" "Delete the remote tag, \$tag is the remote tag name here"
		printf "    %-18s%s\n" "m/move" "Rename the tag"
		printf "    %-18s%s\n" "mr/move-remote" "Rename the remote tag, \$tag is the remote tag name here"
		printf "    %-18s%s\n" "mmr" "move & move-remote"
		printf "    %-18s%s\n" "ddr" "delete & delete-remote"
		printf "    %-18s%s\n" "cp" "create & push"
		printf "    %-18s%s\n" "ddrcp" "delete & delete-remote & create & push. meant to update local and remote tag to current commit"
		printf "    %-18s%s\n" "df/delete-fetch" "delete local tag & fetch remote. meant to align local tag with remote"
	elif git check-ref-format "tags/$1" ; then
		local tag=$1
		if [[ $tag = -* ]]; then
			logError "A tag should not starts with '-'" && return 1
		fi

		local cmd=$2
		if [ -z $cmd ]; then
			cmd="c"
		fi
		case $cmd in
			c|create)
				git tag $tag && logSuccess "Created tag: $tag"
			;;
			p|push)
				git push origin tag $tag
			;;
			cp)
				git tag $tag && logSuccess "Created tag: $tag" && git push origin tag $tag
			;;
			d|delete)
				git tag -d $tag
			;;
			dr|delete-remote)
				git push origin :refs/tags/$tag
			;;
			ddr)
				git tag -d $1 && git push origin :refs/tags/$tag
			;;
			ddrcp)
				git tag -d $tag
				[ 0 -ne $? ] && return
				git push origin :refs/tags/$tag
				[ 0 -ne $? ] && return
				git tag $1
				[ 0 -ne $? ] && return
				logSuccess "Created tag: $tag"
				git push origin tag $tag
			;;
			m|move|mr|move-remote|mmr)
				local newTag=$3
				if [[ -z $newTag || ! $(git check-ref-format "tags/$newTag") || $newTag = -* ]]; then
					logError "Please specify a valid new tag name!" && return 1
				fi
				local goon=1
				if [[ "m" = $cmd || "move" = $cmd || "mmr" = $cmd ]]; then
					git tag $newTag $tag && git tag -d $tag && logSuccess "Renamed tag $tag to $newTag" || goon=""
				fi
				if [ $goon ] && [[ "mr" = $cmd || "move-remote" = $cmd || "mmr" = $cmd ]]; then
					git push origin $newTag :$tag && logSuccess "Renamed remote tag $tag to $newTag"
				fi
			;;
			df|delete-fetch)
				git tag -d $tag
				[ 0 -ne $? ] && return
				git fetch origin tag $tag --no-tags
			;;
			*)
				logError "Unknown command: $cmd"
				gtag -h
				return 1
			;;
		esac
	else
		logError "$1 is not a valid tag name" && return 1
	fi
}

function +gtag() { #x
	declare -i arrayBase=$(getArrayBase)
	if [ $COMP_CWORD -eq $(($arrayBase + 1)) ]; then
		local p2="${COMP_WORDS[$(($arrayBase + 1))]}"
		local tags
		IFS=$'\n' tags=($(git tag --list "$p2*")) rdIFS
		local str=$(concat ' ' "${tags[@]}") # incase the ksyarrays was set, use array parameter expansion (${arr[@]}) here
		COMPREPLY=($(compgen -W "$str" -- $p2))
		return 0
	fi
	return 0
}

complete -F +gtag gtag

function gb() { #? operate branch. Usage: gb $branch(optional, . stands for current branch) $cmd(default 'create') $cmdArg(optional). gb -h for more
	# CHECK if this is a git repository
    isNotGitRepository && return 1

	local branch=$1
	if [ "." = "$branch" ]; then
		branch=$(git branch --show-current)
	fi
	if [ -z $branch ]; then
		git branch --show-current
	elif [ "-h" = "$branch" ]; then
		logInfo "Usage: gb \$branch(optional, \e[1m.\e[0m stands for current branch) \$cmd(default 'create') \$cmdArg(optional).
  \e[1mIf no params passed (gb), show the current branch name\e[0m
  Available commands:\n"
		printf "    %-19s%s\n" "c/create" "Default. Create a branch"
		printf "    %-19s%s\n" "co/checkout" "Checkout the branch"
		printf "    %-19s%s\n" "cc/create-checkout" "Create a branch and checkout it"
		printf "    %-19s%s\n" "d/delete" "Delete the branch"
		printf "    %-19s%s\n" "dr/delete-remote" "Delete the remote branch, \$branch is the remote branch name here"
		printf "    %-19s%s\n" "m/move" "Rename the branch"
		printf "    %-19s%s\n" "t/track" "Show current track or track a remote branch"
		printf "    %-19s%s\n" "ut/untrack" "Unset remote tracking"
	elif git check-ref-format --branch "$branch" >/dev/null 2>&1 ; then
		if [[ $branch = -* ]]; then
			logError "A branch name should not starts with '-'" && return 1
		fi

		local cmd=$2
		if [ -z $cmd ]; then
			if ! git branch | grep -q "$branch"; then
				if confirm "Create non-existing branch $branch"; then
					cmd="c"
				else
					return 0
				fi
			else
				cmd="co"
			fi
		fi
		case $cmd in
			c|create)
				git branch $branch && logSuccess "Created branch: $branch"
			;;
			cc|create-checkout)
				if ! git branch | grep -q "$branch"; then
					git branch $branch
				fi
				git checkout $branch
			;;
			co|checkout)
				git checkout $branch
			;;
			d|delete)
				git branch -D $branch
			;;
			dr|delete-remote)
				confirm -w "Are you sure to delete the remote branch \e[1m$branch\e[0m ?" && git push origin --delete $branch || logInfo "NOT deleted"
			;;
			m|move)
				local newB=$3
				if ! git check-ref-format --branch "$newB" >/dev/null 2>&1 || [[ $newB = -* ]]; then
					logError "Please specify a valid new branch name!" && return 1
				fi
				git branch -m $branch $newB
			;;
			t|track)
				local upstream=$3
				if [ -z "$upstream" ]; then
					git branch -vv | awk "/..$branch /{print}"
				else
					git branch -u $upstream $branch
				fi
			;;
			ut)
				git branch --unset-upstream $branch
			;;
			*)
				logError "Unknown command: $cmd"
				gb -h
				return 1
			;;
		esac
	else
		logError "$1 is not a valid branch name" && return 1
	fi
}

function +gb() { #x
	declare -i arrayBase=$(getArrayBase)
	if [ $COMP_CWORD -eq $(($arrayBase + 1)) ]; then
		local p2="${COMP_WORDS[$(($arrayBase + 1))]}"
		local tags
		IFS=$'\n'
		branches=($(git branch --list "$p2*"))
		originBranches=($(git branch -r --list "origin/$p2*"))
		rdIFS

		declare -A _branches_
		declare -i i=$arrayBase
		for ((; i<=$((${#branches[@]} - 1 + $arrayBase)); i++)); do
			branches[$i]=${branches[$i]:2}
			_branches_[branches[$i]]="1"
		done
		i=$arrayBase
		for ((; i<=$((${#originBranches[@]} - 1 + $arrayBase)); i++)); do
			originBranches[$i]=${originBranches[$i]:9} # "  origin/".length = 9
			if [ ! "1" = "${_branches_[originBranches[$i]]}" ]; then
				branches+=(${originBranches[$i]})
			fi
		done

		local str=$(concat ' ' "${branches[@]}") # incase the ksyarrays was set, use array parameter expansion (${arr[@]}) here
		COMPREPLY=($(compgen -W "$str" -- $p2))
		return 0
	fi
	return 0
}

complete -F +gb gb

function gcof() { #? git checkout --- fuzziable edition. Usage: gcof $branch/$tag(fuzziable)
	# CHECK if this is a git repository
    isNotGitRepository && return 1
	[ -z "$1" ] && return

	declare -i arrayBase=$(getArrayBase)
	declare -i i=$arrayBase
	local branches tags refs
	IFS=$'\n'
	branches=($(git branch --list "*$1*"))  # list branches from local
	originBranches=($(git branch -r --list "origin/$1*")) # list branches from origin
	tags=($(git tag --list "*$1*")) # list tags
	rdIFS

	i=$arrayBase
	declare -A _branches_
	for ((; i<=$((${#branches[@]} - 1 + $arrayBase)); i++)); do
		branches[$i]=${branches[$i]:2}
		_branches_[branches[$i]]="1"
	done

	i=$arrayBase
	for ((; i<=$((${#originBranches[@]} - 1 + $arrayBase)); i++)); do
		originBranches[$i]=${originBranches[$i]:9} # "  origin/".length = 9
		if [ ! "1" = "${_branches_[originBranches[$i]]}" ]; then
			branches+=(${originBranches[$i]})
		fi
		_branches_[originBranches[$i]]="1"
	done

	refs=("${branches[@]}" "${tags[@]}")

	if [ ${#refs} -eq 0 ]; then
		logError "No  branch or tag similar to $1" && return 1
	elif [ ${#refs} -eq 1 ]; then
		if [ ${refs[$arrayBase]} = $1 ]; then
			git checkout $1
		else
			confirm -e "Checkout \e[1m${refs[$arrayBase]}\e[0m ?" && git checkout ${refs[$arrayBase]} || :
		fi
	else
		logInfo "Guessed:"
		i=$arrayBase
		declare -i maxLen=0
		declare -a lenOffsets
		for ((; i<=$((${#refs[@]} - 1 + $arrayBase)); i++)); do
			local len=$(getStringWidth ${refs[$i]})
			lenOffsets[$i]=$((len - ${#refs[$i]}))
			if [ $len -gt $maxLen ]; then
				maxLen=$len
			fi
		done

		i=$arrayBase
		declare -i formatLen
		declare -i curLen=0
		local formatted_number formatted_name colored_text
		[ ${#branches[@]} -gt 0 ] && echoe "\e[32m--- \e[1mBranches\e[22m ---\e[0m" || :
		for ((; i<=$((${#refs[@]} - 1 + $arrayBase)); i++)); do
			formatLen=$((maxLen - ${lenOffsets[$i]}))
			formatted_number=$(printf "%3s" $i)
			formatted_name=$(printf "%-${formatLen}s" "${refs[$i]}")
			colored_text="\033[90m$formatted_number:\033[0m$formatted_name"
			printf "$colored_text"
			curLen=$((curLen + ${#colored_text}))
			if [ $curLen -ge 120 ]; then
				printf "\n"
				curLen=0
			fi
			if [[ ${#branches[@]} = $((i - 1 + $arrayBase)) && ${#tags[@]} -gt 0 ]]; then
				[ $curLen -ne 0 ] && printf "\n" || :
				echoe "\e[32m--- \e[1mTags\e[22m -------\e[0m"
				curLen=0
			fi
		done

		[ $curLen -ne 0 ] && printf "\n" || :
		local minI=$arrayBase
		local maxI=$((${#refs} - 1 + $arrayBase))
		logInfo "Choose one by the prefix number" "-"
		readTemp && local number=$_TEMP || return 1
		if [[ $number =~ '^[0-9]+$' && $number -ge $minI && $number -le $maxI ]]; then
			git checkout ${refs[$number]}
		else
			logError "The input is invalid" "!" && return 1
		fi
	fi
}

function +gcof() { #x
	declare -i arrayBase=$(getArrayBase)
	if [ $COMP_CWORD -ne $(($arrayBase + 1)) ]; then
		return 0
	fi

	local latest="${COMP_WORDS[$COMP_CWORD]}"
	local branches tags refs
	IFS=$'\n' branches=($(git branch --list "$latest*")); rdIFS

	declare -i i=$arrayBase
	for ((; i<=$((${#branches[@]} - 1 + $arrayBase)); i++)); do
		branches[$i]=${branches[$i]:2}
	done
	IFS=$'\n' tags=($(git tag --list "$latest*")); rdIFS
	refs=("${branches[@]}" "${tags[@]}")

	local str=""
	i=$arrayBase
	for ((; i<=$((${#refs[@]} - 1 + $arrayBase)); i++)); do
		str=$str" ${refs[$i]}"
	done
	COMPREPLY=($(compgen -W "$str" -- $latest))
	return 0
}

complete -F +gcof gcof

function gaac() { #? git add files which name contains $1
    [ -z "$1" ] && return
    git add "*$1*"
}

function gaanc() { #? git add files which name NOT contains $1
    [ -z "$1" ] && return
    git status --porcelain | awk -v s=$1 '{if($2 !~ s){print $2}}' | xargs git add
}

function gctm() { #? commit with message
	if [ "$1" = '' ]
	then 
		if confirm -w "Commit without message ?"; then
			gaa
			git commit -m ""
		fi
	else
		gaa
		git commit -m "$1"
	fi
}

function gcto() { #? commit in one line
	# CHECK if this is a git repository
    isNotGitRepository && return 1
    echo commit with message '"['$1']' $2: $3'" ? (y for Yes)'
	readTemp; local oneline_commit=$_TEMP
    [ "$oneline_commit" = "y" ] && gaa && git commit -m "[$1] $2: $3"
    unset oneline_commit
}

_git_stash_key="_git_stash_:"

function gx() { #? create new stash with name. Usage: gx stashName(optional), flags: -s(--staged), -u(--include-untracked), -k(--keep-index)
	# CHECK if this is a git repository
    isNotGitRepository && return 1
	# CHECK if merge, rebase, cherry-pick or revert is in progress
	hasObstacleProcess && return 1

	name=$1
	if [[ "$name" =~ ^@.* ]]; then
		logError "Please do not use @ as prefix!" && return 1
	fi

	local ki=""
	local s=""
	local u=""
	OPTIND=1
	while getopts ":suk" opt; do
        case $opt in
			k)
				ki="--keep-index"
				;;
			u)
				u="--include-untracked"
				;;
			s)
				s="--staged"
				;;
			:)
                ;;
			\?)
				;;
        esac
    done
	shift "$((OPTIND - 1))"

    if [ -z "$1" ] 
    then
        git stash $ki $s $u
        return
    fi
    git stash push -m "$_git_stash_key""$1" $ki $s $u # stash with specific name
}

function +gitStashOps() { #x
	# CHECK if this is a git repository
    isNotGitRepository && return 1
	# CHECK if merge, rebase, cherry-pick or revert is in progress
	hasObstacleProcess && return 1
	local subCommand=$1
	local index=""
	local name=""
	if [[ "$2" =~ ^@.* ]]; then
		index=${2:1}
		if [[ -z "$index" || ! $index =~ ^[0-9]+$ ]]; then
			logError "Please specify a valid index (non-negative integer)" && return 1
		fi
		local count
		count=$(git rev-list --walk-reflogs --count refs/stash)
		if [ $index -gt $((count - 1)) ]; then
			logError "There are only $count stash entries!" && return 1
		fi
	else
		name=$2
	fi

	# transfer subCommand string to array
	declare -a subCommandArray
	if [ $_CURRENT_SHELL = "zsh" ]; then
		subCommandArray=(${(s/ /)subCommand})
	elif [[ $_CURRENT_SHELL = "bash" ]]; then
		read -a subCommandArray <<< "$subCommand"
	else
		return 1
	fi
	
	if [ $index ]; then
		# operate by index
		git stash ${subCommandArray[@]} stash@{$index}
	elif [ -z "$name" ]; then
		# operate the top
		git stash ${subCommandArray[@]}
	else
		# operate by key
		local key=$(git stash list | grep "$_git_stash_key""$name" | cut -d: -f1)
		[ -z "$key" ] && logWarn "The stash key \"$name\" doesn't exist!" && return
		git stash ${subCommandArray[@]} $key # apply with specific name
	fi
}

alias gxl='git stash list --date=local'
alias gxlf='git stash list --pretty=format:"%C(red)%h%C(reset) - %C(dim yellow)(%C(bold magenta)%gd%C(dim yellow))%C(reset) %<(70,trunc)%s %C(green)(%cr) %C(bold blue)<%an>%C(reset)"'
alias gxs='+gitStashOps show'
alias gxsp='+gitStashOps "show -p"'
alias gxa='+gitStashOps apply'
alias gxp='+gitStashOps pop'
alias gxd='+gitStashOps drop'

function gstm() { #? check multi git folder commit status
	function gcsm0() {
		[[ ! -d "$1" || ! -d "$1/.git" ]] && return
		[ "-p" = "$2" ] && echo $1 | awk -F '/' '{print "\033[1;34m" $NF ":\033[0m" }'
		git -C $1 status | awk '/Your branch is/{print}' | awk '{sub("Your branch is ", "")} 1' \
			| awk '{sub("up to date", "\033[1;32mUP TO DATE\033[0m")} 1' \
			| awk '{sub("ahead", "\033[1;31mAHEAD\033[0m")} 1' 
	}

    local folder=$1
	if [ -z $folder ]; then
		folder="."
	fi

	local file
	for file in $folder/* ; do
		gcsm0 $file -p
	done

	unset -f gcsm0
}

function ghttpproxy() { #? Usage: gttpproxy proxy. unsert proxy if 'proxy' is empty
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

function gpush() { #? git push with automatic branch creation
	isNotGitRepository && return 1
	local current_branch=$(git rev-parse --abbrev-ref HEAD)
	local src=$1
	local dst=$2
	[ "$src" = "" ] && src=$current_branch || :
	[ "$dst" = "" ] && dst=$src || :
	if git rev-parse --verify --quiet "${dst}@{u}" >/dev/null; then
		logInfo "Push starting.."
		git push origin $src:$dst
		if [ $? = 0 ]; then
			logSuccess "Push done"
		else
			logWarn "Push seems failed, check the above message"
		fi
	elif confirm "No upstream branch, create it ?"; then
		logInfo "Creating upstream branch.."
		git push -u origin $src:$dst
		if [ $? = 0 ]; then
			logSuccess "Upstream branch just created"
		else
			logError "Failed to create upstream branch \e[1m$dst\e[0m"
		fi
	fi
}

function gtop() { #? go to the top level of current repo
    # CHECK if this is a git repository
    isNotGitRepository && return 1
	local gitTopLevel=$(git rev-parse --show-toplevel)
	if [[ 'go' = $1 || 'g' = $1 ]]; then
		logInfo "Go to:\n$gitTopLevel"
		cd $gitTopLevel
	else
		echo $gitTopLevel
	fi
}

function gct() { #? git commit step by step
	# READ flags
	local setPattern=""
	local verbose=""
	while getopts "phv" opt; do
		case $opt in
			h)
				logInfo "A command to git-commit step by step\n\n  Available flags:"
				printf "    %-6s%s\n" "-h" "Print this help message and return"
				printf "    %-6s%s\n" "-p" "Specify the pattern"
				printf "    %-6s%s\n" "-v" "Show more verbose info"
				echo
				echoe "  \e[34;1mPattern Hint\e[0m:\n  Example: \e[34m<step1:default> <#step2:default option2 option3>: <step3@[^\\:]+>\e[0m. \
The \e[1m#\e[0m in step2 behind char \e[1m<\e[0m indicates it's a branch-scope step. \
The \e[1m[^\\:]+\e[0m in step3 behind char \e[1m@\e[0m sepcifies the regex this step value must match. \e[1m\ \e[0mescape the character behind it.\n"
				echoe "  \e[34;1mCommit Hint\e[0m:\n  Input then press \e[1mEnter\e[0m to set value for a step, \e[34mthe last-time value or default value will be appended\e[0m if the input is empty. \
You can also \e[34mchoose one option by input number\e[0m if there are multi options specified for current step.\n"
				echoe "  \e[34;1mRecommended pattern\e[0m:\n  $(cat $_QFIG_LOC/staff/defGctPattern)"
				return
				;;
			p) # specify pattern
				setPattern=1
				;;
			v) # display verbose infos
				verbose=1
				;;
			\?)
				logError "Invalid option: -$OPTARG" && return 1
				;;
		esac
	done

    # CHECK if this is a git repository
    isNotGitRepository && return 1
	# CHECK if merge, rebase, cherry-pick or revert is in progress
	hasObstacleProcess && return 1

	# CHECK options
	declare -i arrayBase=$(getArrayBase)

    # GET pattern & cache, use default if it not exists
	local git_toplevel=$(git rev-parse --show-toplevel)
    local git_commit_info_cache_folder=$_QFIG_LOC/.gcache/$(echo -n $git_toplevel | md5x)
	[ ! -d "$git_commit_info_cache_folder" ] && mkdir -p $git_commit_info_cache_folder
	local pattern_tokens_file=$git_commit_info_cache_folder/pts
	local r_step_values_cache_file=$git_commit_info_cache_folder/rsvc # r = repository
	local b_step_values_cache_file=$git_commit_info_cache_folder/bsvc-$(git branch --show-current) # b = branch

	# SET pattern
	local repoPattern=".gctpattern"
	local boldRepoPattern="\e[1m$repoPattern\e[0m"
	local gctpattern_file=$git_toplevel/$repoPattern
	local saveToRepo=""
	if [ -f "$gctpattern_file" ]; then
		[ $setPattern ] && logError "Can not specify pattern when $boldRepoPattern exists, modify it to achieve this" && return 1

		# read from .gctpattern
		local pattern=$(cat $gctpattern_file)
		[ $verbose ] && logSilence "Using $boldRepoPattern \e[90mpattern: $pattern"
		[ -f "$pattern_tokens_file" ] && [ "?:$pattern" = "$(head -n 1 $pattern_tokens_file)" ] || setPattern=1
	else
		if [ $setPattern ]; then
			# specify local pattern
			logInfo "Please specify the pattern(Rerun with -h to get hint):"
			readTemp && local pattern=$_TEMP || return 1
		elif [ ! -f "$pattern_tokens_file" ]; then
			setPattern=1
			if confirm -p "?" "Use default pattern \e[34;3;38m$(cat $_QFIG_LOC/staff/defGctPattern)\e[0m ?"; then
				logInfo "Using default pattern"
				pattern=$(cat $_QFIG_LOC/staff/defGctPattern)
			else
				logInfo "Then please specify the pattern(Rerun with -p to change, -h to get hint):"
				readTemp && local pattern=$_TEMP || return 1
			fi
		elif [ $verbose ]; then
			logSilence "Using local pattern: ${$(head -n 1 $pattern_tokens_file):2}"
		fi
		if [ $setPattern ]; then # whether save to .gctpattern
			logInfo "Save it in $boldRepoPattern(Not recommanded for repo that already have lots of commits) ? \e[90mY for Yes, others for No.\e[0m" "?"
			readTemp && local saveToRepo=$_TEMP || return 1
		fi
	fi

	# RESOLVE pattern
	if [ $setPattern ]; then
		# The script do not support early sh, better use the current shell
        if [[ "$_CURRENT_SHELL" = "zsh" ]]; then
			resolveResult=$(zsh $_QFIG_LOC/staff/resolveGctPattern.sh "$pattern")
		else
			# Since only zsh and bash are supported, I assert it's bash
			resolveResult=$(bash $_QFIG_LOC/staff/resolveGctPattern.sh "$pattern")
		fi
		resolveResult=$($_QFIG_LOC/staff/resolveGctPattern.sh "$pattern")
		if [ $? -eq 0 ]; then
			echo "?:$pattern" > $pattern_tokens_file
			echoe "$resolveResult" >> $pattern_tokens_file
			[ -f "$r_step_values_cache_file" ] && rm $r_step_values_cache_file
			[ -f "$b_step_values_cache_file" ] && rm $b_step_values_cache_file
			[[ 'y' = "$saveToRepo" || 'Y' = "$saveToRepo" ]] && echo $pattern > $gctpattern_file && logInfo "Pattern saved in $boldRepoPattern"
			logSuccess "New pattern resolved!"
		else
			logError "Invalid pattern: $resolveResult" && return 1
		fi
	fi

    # CHECK if it's need to commit
	if git diff --cached --quiet --exit-code; then
		logWarn "Nothing to commit!" && return 1
	fi

	# GET pattern tokens
	declare -a tokens
	IFS=$'\n' tokens=($(cat $pattern_tokens_file | rmCr)); rdIFS # CR for Windows should be eliminated 
	stepsCount=0
	for t in ${tokens[@]}; do
		if [[ "$t" = 1:* ]]; then
			stepsCount=$((stepsCount + 1))	
		fi
	done
	
	# APPEND message step by step
	local message=""
	declare -i curStepNum=0
	declare -i rCurStepNum=$((arrayBase - 1)) # repo scope step count
	declare -i bCurStepNum=$((arrayBase - 1)) # branch scope step count
	local rStepValues
	local bStepValues
	[ -f $r_step_values_cache_file ] && IFS=$'\n' rStepValues=($(cat $r_step_values_cache_file | rmCr)); rdIFS || rStepValues=()
	[ -f $b_step_values_cache_file ] && IFS=$'\n' bStepValues=($(cat $b_step_values_cache_file | rmCr)); rdIFS || bStepValues=()
	local newRStepValues=""
	local newBStepValues=""
	local stepKey=""
	local stepRegex=""
	local stepOptions=""
	declare -i proceedStep=0
	declare -i branchScope=0
	local stepPrompt
	local stepDefValue
	local partial
	local i

	i=$((arrayBase + 0))
	[[ "$(uname -s)" =~ CYGWIN* || "$(uname -s)" =~ MINGW* ]] && NL="\r\n" || NL="\n" # Windows use \r\n as newline
	for ((; i<=$((${#tokens[@]} - 1 + $arrayBase)); i++)); do
		t=${tokens[$i]}
		case $t in
			0:*)
				message+=${t:2}
				stepKey=""
			;;
			1:*)
				stepKey=${t:2}
				if ! [[ ${tokens[$((i + 1))]} =~ 11:* || ${tokens[$((i + 1))]} =~ 12:* ]]; then
					proceedStep=1
				fi
			;;
			10:*)
				branchScope=1
			;;
			11:*)
				if [ $stepKey ]; then
					stepRegex=${t:3}
					if ! [[ ${tokens[$((i + 1))]} =~ 12* ]]; then
						proceedStep=1
					fi
				fi
			;;
			12:*)
				if [ $stepKey ]; then
					stepOptions=($(echo ${t:3}))
					proceedStep=1
				fi
			;;
		esac

		if [[ $proceedStep -eq 1 && ! -z $stepKey ]]; then
			curStepNum=$((curStepNum + 1))
			stepPrompt="\e[33m[$curStepNum/$stepsCount]\e[0m "

			if [ $branchScope -eq 1 ]; then
				bCurStepNum=$((bCurStepNum + 1))
				stepDefValue="${bStepValues[$bCurStepNum]:1}" # cached value start with '>'
				stepPrompt+="\e[4m$stepKey?\e[0m "
			else
				rCurStepNum=$((rCurStepNum + 1))
				stepDefValue="${rStepValues[$rCurStepNum]:1}" # cached value start with '>'
				stepPrompt+="$stepKey? "
			fi

			if [ $stepRegex ]; then
				stepPrompt+="\e[2m$stepRegex\e[22m "
			fi
			if [ ! -z "$stepOptions" ]; then
				[ -z "$stepDefValue" ] && stepDefValue=${stepOptions[$arrayBase]}
				stepPrompt+="($stepDefValue) "
				if [ 1 -lt "${#stepOptions[@]}" ]; then
					# append option id
					stepPrompt+="|$(echo ${stepOptions[@]} | awk '{for (i = 1; i <= NF; i++) { if (i < 7) printf " \033[1;3" i "m" i ":" $i;
				else printf " \033[1;37m" i ":" $i;}} END{printf "\033[0m"}')"
				fi
			else
				[ ! -z "$stepDefValue" ] && stepPrompt+="($stepDefValue) " 
			fi
			echoe "$stepPrompt"

			# READ and record value
			while
				readTemp && local partial=$_TEMP || return 1
				if [ -z "$partial" ]; then
					partial=$stepDefValue
				elif [ 1 -lt "${#stepOptions[@]}" ]; then
					# select by option id
					if [[ $partial =~ ^[0-9]+$ && $partial -le ${#stepOptions} ]]
					then
						local partial0=$partial
						partial=$((partial - 1 + arrayBase))
						echoe "\e[2mChosen:\e[0m \e[1;3${partial0}m${stepOptions[$partial]}\e[0m"
						partial=${stepOptions[$partial]}
					fi
				fi
				if [[ $partial && $stepRegex && ! $partial =~ $stepRegex ]]; then
					logWarn "Value not matching \e[1;31m$stepRegex\e[0m. Please re-enter:"
					true
				else
					false
				fi
			do :; done

			message+=$partial
			if [ $branchScope -eq 1 ]; then
				newBStepValues+=">$partial$NL" # start width '>' to avoid empty line
			else
				newRStepValues+=">$partial$NL" # start width '>' to avoid empty line
			fi

			# RESET step metas
			stepKey=""
			stepRegex=""
			stepOptions=""
			proceedStep=0
			branchScope=0
		fi
	done

	echoe "$newRStepValues" > $r_step_values_cache_file
	echoe "$newBStepValues" > $b_step_values_cache_file

	# COMMIT 
	git commit -m "$message"
}

function isNotGitRepository() { #x
	if [ "`git rev-parse --is-inside-work-tree 2>&1`" = 'true' ]; then
		return 1
	fi
	logError "Not a git repository!"
}

function hasObstacleProcess() { #x
	local obstacleProgress
	if [ -f .git/MERGE_HEAD ]; then
        obstacleProgress=Merge
	elif [ -d .git/rebase-apply ] || [ -d .git/rebase-merge ] || [ -d .git/rebasing ]; then
		obstacleProgress=Rebase
	elif [ -f .git/CHERRY_PICK_HEAD ]; then
		obstacleProgress=Cherry-pick
	elif [ -f .git/REVERT_HEAD ]; then
		obstacleProgress=Revert
	fi
	if [ $obstacleProgress ]; then
		confirm -w "\e[1m$obstacleProgress\e[0m in progress, continue ?"  && return 1 || :
	else
		return 1
	fi
}
