# Git related commands

function glo {
    git log --oneline
}

function glog {
    git log --oneline --abbrev-commit --graph
}


function gamd {
    git commit --amend
}

function gamdn {
    git commit --amdend --no-edit
}

function gaa {
    git add -A
}

function gaap {
    git add -p
}

function gaaf() { #? git add files in pattern
    param($pattern)
    If ($pattern.Length -Eq 0) {
        Return
    }
    git add "*$pattern*"
}

function glo {
    git log --oneline
}

function gst {
    git status
}

function glist {
    git stash list
}

function gco {
    param($branch)
    git checkout $branch 
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

$gctCommitTypes = "refactor", "fix", "feat", "chore", "doc", "test", "style"
$gitCommitTypeColors = "Red", "Green", "Yellow", "Blue", "Magenta", "Cyan", "Gray"
$gitCommitTypsTip = "1:refactor 2:fix 3:feat 4:chore 5:doc 5:test 7:style"

function gct() { #? commit in process
    # CHECK if this is a git repository
    If (-Not(git rev-parse --is-inside-work-tree 2>&1)) {
        Write-Warning "Not a git repository!"
        Return	
    }

    # CHECK if it's need to commit
    $nothingToCommit = $true
    gst | % {
        If ($_ -Match "Changes to be committed") {
            $nothingToCommit = $false
        }
    } 

    If ($nothingToCommit) {
        Write-Wraning "Nothing to commit!"
        Return
    }

    # GET commit message cache, use default if it not exists
    $git_commit_info_cache_folder = $Qfig_loc/.gcache
    $present_working_repository_cache = $git_commit_info_cache_folder + '/' +  $(git rev-parse --show-toplevel | sed 's|/|_|g') + '.tmp'

    
    If (Test-Path $git_commit_info_cache_folder -PathType Container) {
       md $git_commit_info_cache_folder 
    }
    $info_separator = "!@#!@#!@#"

    If (Test-Path $present_working_repository_cache -PathType Leaf) {
        $present_working_repository_cache_content = (cat $present_working_repository_cache) -split $info_separator
        $commit_name0 = $present_working_repository_cache_content[0]
        $commit_card0 = $present_working_repository_cache_content[1]
        $commit_type0 = $present_working_repository_cache_content[2]
        $commit_desc0 = $present_working_repository_cache_content[3]
        
    }

    defaultV commit_name0 "Unknown"
    defaultV commit_card0 "N/A"
    defaultV commit_type0 "other"
    defaultV commit_desc0 "Unknown"

    # COMMIT step by step
    echo "[1/4] Name? ($commit_name0)"
    read commit_name
    echo "[2/4] Card? ($commit_card0)"
    read commit_card
    echo "[3/4] Type? ($commit_type0) | $gctCommitTypesTip"
    read commit_type

    if echo $commit_type | egrep -q '^[0-9]+$' && [ $commit_type -gt 0 ] && [ $commit_type -le ${#gctCommitTypes} ]
    then
        echo "\033[1;3${commit_type}m$gctCommitTypes[$commit_type]\033[0m"
        commit_type=$gctCommitTypes[$commit_type]
    fi

    echo "[4/4] Note? ($commit_desc0)"
    read commit_desc

    defaultV "commit_name" $commit_name0
    defaultV "commit_card" $commit_card0
    defaultV "commit_type" $commit_type0
    defaultV "commit_desc" $commit_desc0

    # cache new info
    echo "'$commit_name'$info_separator'$commit_number'$info_separator'$commit_type'$info_separator'$commit_desc'" > $present_working_repository_cache

    # commit
    full_commit_message="$commit_name [$commit_number] $commit_type: $commit_desc"
    git commit -m "$full_commit_message"

}
