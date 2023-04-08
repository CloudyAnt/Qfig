# Git related commands

function gbco() {
    param([Parameter(Mandatory)]$name)
    git branch $name
    git checkout $name
}

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
    git commit --amend --no-edit
}

function gaa {
    git add -A
}

function gaap {
    git add -p
}

function gaaf() {
    #? git add files in pattern
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

function gmergec() {
    #? git merge --continue
    gaa
    git merge --continue
}

function grebasec() {
    #? git rebase --continue
    gaa
    git rebase --continue
}

function gpr() {
    #? git pull --rebase
    git pull --rebase
}

$_git_stash_key = "_git_stash_:"

function gstash() {
    #? git stash
    param($key)

    If ($key.Length -Eq 0) {
        git stash
    }
    Else {
        git stash push -m "$_git_stash_key$key" # stash with specific key
    }
}

function gstashunstaged() {
    #? git stash unstaged files
    param($key)

    If ($key.Length -Eq 0) {
        git stash --keep-index
    }
    Else {
        git stash push -m "$_git_stash_key$key" --keep-index # stash with specific name
    }
}

function gapply() {
    #? git stash apply
    param($key)

    If ($key.Length -Eq 0) {
        git stash apply
    }
    Else {
        $matchedStashes = (git stash list | ? { $_.contains("$git_stash_Key$key") })
        If ($matchedStashes.Length -Eq 0) {
            Write-Warning "Stash with key '$key' doesn't exist!";
            Return
        }
        Else {
            git stash apply $matchedStashes.split(":")[0] # apply with specific name
        }
    }
}

function gpop() {
    #? git stash pop
    param($key)

    If ($key.Length -Eq 0) {
        git stash pop
    }
    Else {
        $matchedStashes = (git stash list | ? { $_.contains("$git_stash_Key$key") })
        If ($matchedStashes.Length -Eq 0) {
            Write-Warning "Stash with key '$key' doesn't exist!";
            Return
        }
        Else {
            git stash pop $matchedStashes.split(":")[0] # apply with specific name
        }
    }
}

function ghttpproxy() {
    param($proxy)
    If ($proxy.Length -Eq 0) {
        git config --global --unset http.proxy
        git config --global --unset https.proxy
        logSuccess "Clean git http/https proxy"
    }
    else {
        git config --global http.proxy $proxy
        git config --global https.proxy $proxy
        logSuccess "Set git http/https proxy as $proxy"
    }
}

function gpush() {
    If (-Not "true".Equals((git rev-parse --is-inside-work-tree 2>&1) -join "`r`n")) {
        logError "Not a git repository!"
        Return
    }
    $message = git push 2>&1 | Out-String
    If ($?) {
        logSuccess "$message"
    }
    Else {
        If ($message -match ".*has no upstream branch.*") {
            logInfo "Creating upstream branch"
            $branch = git rev-parse --abbrev-ref HEAD
            $message = git push -u origin | Out-String
            If ($?) {
                logSuccess "Upstream branch just created`n$message"
            }
            Else {
                logError "Failed to create upstream branch `e[1m$branch`e[0m:`n$message"
            }
        }
        Else {
            logError "$message"
        }
    }
}


function gct() {
    #? git commit step by step
    param([switch]$help = $false, [switch]$pattern_set = $false, [switch]$verbose = $false)
    If ($help) {
        logInfo "A command to git-commit step by step`n`n  Available flags:"
        "    {0,-15}{1}" -f "-help", "Print this help message"
        "    {0,-15}{1}" -f "-pattern_set", "Specify the pattern"
        "    {0,-15}{1}" -f "-verbose", "Show more verbose info"
        "`n  Recommend pattern: $(Get-Content $Qfig_loc/staff/defGctPattern)"
        Return
    }

    # CHECK if this is a git repository
    If (-Not "true".Equals((git rev-parse --is-inside-work-tree 2>&1) -join "`r`n")) {
        logError "Not a git repository!"
        Return
    }
    $gst = git status 2>&1
    $obstacleProgress = ""
    If (($gst -match ".*All conflicts fixed but you are still merging.*") -Or ($gst -match ".*You have unmerged paths.*")) {
        $obstacleProgress = "Merge"
    } ElseIf ($gst -match ".*interactive rebase in progress;.*") {
        $obstacleProgress = "Rebase"
    } ElseIf ($gst -match ".*You are currently cherry-picking.*") {
        $obstacleProgress = "Cherry-pick"
    } ElseIf ($gst -match ".*You are currently reverting.*") {
        $obstacleProgress = "Revert"
    }
    If ($obstacleProgress) {
        logWarn "$obstacleProgress in progress, continue ? \e[90mY for Yes, others for No.\e[0m" "!"
		$yn = Read-Host
        If (-Not ("y".Equals($yn) -Or "Y".Equals($yn))) {
            Return
        }
    }

    # GET pattern & cache, use default if it not exists
    $git_toplevel = git rev-parse --show-toplevel
    $working_directory = $git_toplevel.replace("/", "_").replace(":", "__")
    $git_commit_info_cache_folder = "$Qfig_loc/.gcache/$working_directory"
    $null = New-Item -Path $git_commit_info_cache_folder -Force -ItemType Container

    $pattern_tokens_file = "$git_commit_info_cache_folder/pts"
    $r_step_values_cache_file = "$git_commit_info_cache_folder/rsvc" # r = repository
    $b_step_values_cache_file = "$git_commit_info_cache_folder/bsvc-$(git branch --show-current)" # b = branch

    # SET pattern
    $repoPattern = ".gctpattern"
    $boldRepoPattern = "`e[1m$repoPattern`e[0m"
    $gctpattern_file = "$git_toplevel/$repoPattern"
    $saveToRepo = 0

    IF (Test-Path $gctpattern_file -PathType Leaf) {
        If ($pattern_set) {
            logError "Can not specify pattern cause $boldRepoPattern exists, modify it to achieve this"
            Return
        }
        $pattern = Get-Content $gctpattern_file
        If ($verbose) {
            logSilence "Using $boldRepoPattern `e[2mpattern: $pattern"
        }
        If (-Not ((Test-Path $pattern_tokens_file -PathType Leaf) -And ("?:$pattern".Equals($(Get-Content $pattern_tokens_file -TotalCount 1))))) {
            $pattern_set = $true
        }
    }
    Else {
        If ($pattern_set) {
            logInfo "Please specify the pattern(Rerun with -h to get hint):"
            $pattern = Read-Host
        }
        ElseIf (-Not (Test-Path $pattern_tokens_file -PathType Leaf)) {
            $pattern_set = $true
            logInfo "Use default pattern `e[34;3;38m$(Get-Content $Qfig_loc/staff/defGctPattern)`e[0m ? `e[2mY for Yes, others for No.`e[0m" "?"
            $yn = Read-Host
            If ("y".Equals($yn) -Or "Y".Equals($yn)) {
                logInfo "Using default pattern"
                $pattern = Get-Content "$Qfig_loc/staff/defGctPattern"
            }
            Else {
                logInfo "Then please specify the pattern(Rerun with -p to change, -h to get hint):"
                $pattern = Read-Host
            }
        }
        ElseIf ($verbose) {
            logSilence "Using local pattern: $((Get-Content $pattern_tokens_file -TotalCount 1).subString(2))"
        }
        If ($pattern_set) { # whether save to .gctpattern
            # logInfo "Save it in $boldRepoPattern(It may be shared through your git repo) ? `e[2mY for Yes, others for No.`e[0m" "?"
            # $saveToRepo = Read-Host
        }
    }

    # RESOLVE pattern
    If ($pattern_set) {
        $resolveResult = . $Qfig_loc/staff/resolveGctPattern.ps1 $pattern
        If ($?) {
            Write-Output "?:$pattern" > $pattern_tokens_file
            Write-Output $($resolveResult -join "`r`n") >> $pattern_tokens_file
            If (Test-Path $r_step_values_cache_file -PathType Leaf) {
                Remove-Item $r_step_values_cache_file
            }
            If (Test-Path $b_step_values_cache_file -PathType Leaf) {
                Remove-Item $b_step_values_cache_file
            }
            # If ("y".Equals($saveToRepo) -Or "Y".Equals($saveToRepo)) {
            #     Write-Output $pattern > $gctpattern_file
            #     logInfo "Pattern saved in $boldRepoPattern"
            # }
            logSuccess "New pattern resolved!"
        }
        Else {
            logError "Invalid pattern: $resolveResult"
            Return
        }
    }

    # CHECK if it's need to commit
    $needToCommit = $false
    gst | % {
        If ($_ -match "Changes to be committed.+") {
            $needToCommit = $true
            Return
        }
    }
    If (-Not $needToCommit) {
        logWarn "Nothing to commit!"
        Return
    }

    # GET pattern tokens
    $tokens = (Get-Content $pattern_tokens_file).split("`n")
    $stepsCount = 0
    Foreach ($t in $tokens) {
        if ($t.startsWith("1:")) {
            $stepsCount += 1
        }
    }
	
    # APPEND message step by step
    $message = ""
    If (Test-Path $r_step_values_cache_file -PathType Leaf) {
        $rStepValues = (Get-Content $r_step_values_cache_file).split("`n")
    } Else {
        $rStepValues = @()
    }
    If (Test-Path $b_step_values_cache_file -PathType Leaf) {
        $bStepValues = (Get-Content $b_step_values_cache_file).split("`n")
    } Else {
        $bStepValues = @()
    }
    $newRStepValues = ""
    $newBStepValues = ""
    $curStepNum = -1
    $rCurStepNum = -1
    $bCurStepNum = -1
    $stepKey = ""
    $stepRegex = ""
    $stepOptions = @()	
    $proceedStep = $false
    $branchScope = $false
    For ($i = 0; $i -lt $tokens.Length; $i++) {
        $t = $tokens[$i]
        Switch -Wildcard ($t) {
            0:* {
                $message += $t.SubString(2)
                $stepKey = ""
            }
            1:* {
                $stepKey = $t.Substring(2)
                If (-Not ($tokens[$i + 1] -match "11:*" -Or $tokens[$i + 1] -match "12:*")) {
                    $proceedStep = $true
                }
            }
            10:* {
                $branchScope = $true
            }
            11:* {
                If ($stepKey) {
                    $stepRegex = $t.Substring(3)
                    If (-Not $tokens[$i + 1] -match "12:*") {
                        $proceedStep = $true
                    }
                }
            }
            12:* {
                If ($stepKey) {
                    $stepOptions = $t.Substring(3).Split(" ")
                    $proceedStep = $true
                }
            }
        }

        If ($proceedStep -And -Not [string]::IsNullOrEmpty($stepKey)) {
            $curStepNum++
            $stepPrompt = "`e[1;33m[$($curStepNum + 1)/$stepsCount]`e[0m "

            if ($branchScope) {
                $bCurStepNum++
                if ($bStepValues[$bCurStepNum]) {
                    $stepDefValue = $bStepValues[$bCurStepNum].subString(1)
                } Else {
                    $stepDefValue = ""
                }
                $stepPrompt += "`e[4m$stepKey`?`e[0m "
            } Else {
                $rCurStepNum++
                if ($rStepValues[$rCurStepNum]) {
                    $stepDefValue = $rStepValues[$rCurStepNum].subString(1)
                } Else {
                    $stepDefValue = ""
                }
                $stepPrompt += "$stepKey`? "
            }

            if ($stepRgex) {
                $stepPrompt += "`e[2m$stepRegex`e[22m "
            }
            If ($stepOptions.Length -Gt 0) {
                if ([string]::isNullOrEmpty($stepDefValue)) {
                    $stepDefValue = $stepOptions[0]
                }
                $stepPrompt += "($stepDefValue)"
                If (1 -Lt $stepOptions.Length) {
                    $stepPrompt += " | "
                    $j = 1
                    $stepOptions | % {
                        $stepPrompt += "`e[1;3${j}m${j}:$_ "
                        $j += 1
                    }
                    $stepPrompt += "`e[0m"
                }
            }
            ElseIf (-Not [string]::isNullOrEmpty($stepDefValue)) {
                $stepPrompt += "($stepDefValue)"
            }
            Write-Host $stepPrompt

            # READ and record value
            Do {
                $partial = Read-Host
                If ([string]::isNullOrEmpty($partial)) {
                    $partial = $stepDefValue
                }
                ElseIf (1 -Lt $stepOptions.Length -And $partial -match "^[1-9]+$" -And $partial -Le $stepOptions.Length) {
                    $partial = [int32]$partial
                    Write-Host "`e[2mChosen:`e[0m `e[1;3${partial}m$($stepOptions[$partial  - 1])`e[0m"
                    $partial = $stepOptions[$partial - 1]
                }
                If ($partial -And $stepRegex -And -Not ($partial -match $stepRegex)) {
                    logWarn "Value not matching `e[1;31m$stepRegex`e[0m. Please re-enter:" "!"
                    $continue = $true
                }
                Else {
                    $continue = $false
                }
            } While ($continue)

            $message += $partial
            if ($branchScope) {
                $newBStepValues += ">$partial`n"
            } Else {
                $newRStepValues += ">$partial`n"
            }

            # RESET step metas
            $stepKey = ""
            $stepRegex = ""
            $stepOptions = @()	
            $proceedStep = $false
            $branchScope = $false
        }
    }

    Write-Output $newRStepValues > $r_step_values_cache_file
    Write-Output $newBStepValues > $b_step_values_cache_file

    git commit -m "$message"
}
