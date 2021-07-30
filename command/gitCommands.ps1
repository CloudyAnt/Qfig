# Git related commands

function glo {
    git log --oneline
}

function glog {
    git log --oneline --abbrev-commit --graph }


function gamd {
    git commit --amend
}

function gamdn {
    git commit --amend --no-edit
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
$gctCommitTypeColors = "Red", "Green", "Yellow", "Blue", "Magenta", "Cyan", "Gray"
$gctCommitTypesTip = "1:refactor 2:fix 3:feat 4:chore 5:doc 5:test 7:style"

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
        Write-Warning "Nothing to commit!"
        Return
    }

    # GET commit message cache, use default if it not exists
    $git_commit_info_cache_folder = "$Qfig_loc/.gcache"

    $present_working_folder = git rev-parse --show-toplevel
    If ($present_working_folder -match "^[A-Z]:.+") {
        $present_working_folder = $present_working_folder -replace ":", ""
    }


    $present_working_repository_cache = $git_commit_info_cache_folder + '/' +  $present_working_folder.replace("/", "_") + '.tmp'

    If (-Not(Test-Path $git_commit_info_cache_folder -PathType Container)) {
       md $git_commit_info_cache_folder 
    }
    $info_separator = "!@#!@#!@#"

    If (Test-Path $present_working_repository_cache -PathType Leaf) {
        $repo_cache_content = (cat $present_working_repository_cache) -split $info_separator
        $commit_name0 = $repo_cache_content[0]
        $commit_card0 = $repo_cache_content[1]
        $commit_type0 = $repo_cache_content[2]
        $commit_desc0 = $repo_cache_content[3]
    }

    $commit_name0 = defaultV commit_name0 Unknown
    $commit_card0 = defaultV commit_card0 "N/A" 
    $commit_type0 = defaultV commit_type0 other 
    $commit_desc0 = defaultV commit_desc0 Unknown

    # COMMIT step by step
    echo "[1/4] Name? ($commit_name0)"
    $commit_name = Read-Host
    echo "[2/4] Card? ($commit_card0)"
    $commit_card = Read-Host
    echo "[3/4] Type? ($commit_type0) | $gctCommitTypesTip"
    $commit_type = Read-Host

    try {
        $commit_type_int = [int]$commit_type
        if ($commit_type_int -Gt 0 -And $commit_type_int -Le $gctCommitTypes.Length) {
            $commit_type = $gctCommitTypes[$commit_type - 1]
            echo $commit_type
        }
    } catch {}

    echo "[4/4] Note? ($commit_desc0)"
    $commit_desc = Read-Host

    $commit_name = defaultV commit_name $commit_name0 
    $commit_card = defaultV commit_card $commit_card0
    $commit_type = defaultV commit_type $commit_type0
    $commit_desc = defaultV commit_desc $commit_desc0

    # cache new info
    echo "$commit_name$info_separator$commit_card$info_separator$commit_type$info_separator$commit_desc" > $present_working_repository_cache

    # commit
    $full_commit_message = "$commit_name [$commit_card] $commit_type`: $commit_desc"
    git commit -m "$full_commit_message"

    # unset variables
    clv commit_name0;clv commit_card0;clv commit_type0;clv commit_desc0;
    clv commit_name;clv commit_card;clv commit_type;clv commit_desc;
}

$_git_stash_key = "_git_stash_:"

function gstash() { #? git stash
    param($key)

    If ($key.Length -Eq 0) {
        git stash
    } Else {
        git stash push -m "$_git_stash_key$key" # stash with specific key
    }
}

function gstashunstaged() { #? git stash unstaged files
    param($key)

    If ($key.Length -Eq 0) {
        git stash --keep-index
    } Else {
        git stash push -m "$_git_stash_key$key" --keep-index # stash with specific name
    }
}

function gapply() { #? git stash apply
    param($key)

    If ($key.Length -Eq 0) {
        git stash apply
    } Else {
        $matchedStashes = (git stash list | ? {$_.contains("$git_stash_Key$key") })
        If ($matchedStashes.Length -Eq 0) {
            Write-Warning "Stash with key '$key' doesn't exist!";
            Return
        } Else {
            git stash apply $matchedStashes.split(":")[0] # apply with specific name
        }
    }
}

function gpop() { #? git stash pop
    param($key)

    If ($key.Length -Eq 0) {
        git stash pop
    } Else {
        $matchedStashes = (git stash list | ? {$_.contains("$git_stash_Key$key") })
        If ($matchedStashes.Length -Eq 0) {
            Write-Warning "Stash with key '$key' doesn't exist!";
            Return
        } Else {
            git stash pop $matchedStashes.split(":")[0] # apply with specific name
        }
    }
}
