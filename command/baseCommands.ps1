#? Basic support of Qfig. String related commands are here.
#? These commands only requires Powershell built-in commands

function qfig { #? Qfig preserved command. -h(help) for more
    param([string]$command, [switch]$help = $false)
    If ($help -Or "help".Equals($command)) {
        logInfo "Usage: qfig <command>`n`n  Available commands:`n"
        "    {0,-10}{1}" -f "help", "Print this help message"
        "    {0,-10}{1}" -f "update", "Update Qfig"
        "    {0,-10}{1}" -f "config", "Edit config to enable commands, etc."
        "    {0,-10}{1}" -f "report", "Report Qfig cared environment"
        "    {0,-10}{1}" -f "v/version", "Show current version"
    } ElseIf ("into".Equals($command)) {
        Set-Location $_QFIG_LOC
    } ElseIf ("update".Equals($command)) {
        logInfo "Fetching.."
        git -C $_QFIG_LOC fetch origin master
        $behindCommits = git -C $_QFIG_LOC rev-list --count .."master@{u}"
        If ($behindCommits -eq 0) {
            logSuccess "Qfig is already up to date"
            Return
        } Else {
            $curHead = Get-CurrentHead 7
            $pullMessage = (git -C $_QFIG_LOC pull --rebase 2>&1) -join "`r`n"
            if (-Not $?) {
                logError "Cannot update Qfig:`n$pullMessage"
            } Else {
                logInfo "Updateing Qfig.."
                $newHead = Get-CurrentHead 7
                Write-Host "`nUpdate head `e[1m$curHead`e[0m -> `e[1m$newHead`e[0m:`n"
                $typeColors = @{"refactor"= 31; "fix" = 32; "feat" = 33; "chore" = 34; "doc" = 35; "test" = 36}
                try {
                    git -C $_QFIG_LOC log --oneline --decorate -10 | ForEach-Object {
                        If ($_ -match "^$curHead.+$") {
                            Throw "Stop print log"
                        } Else {
                            $parts = $_.Split(":")
                            $parts1 = $parts[0].Split(" ")
                            $type = $parts1.Split(" ")[$parts1.Length - 1]
                            $color = $typeColors[$type]
                            if (!$color) { $color = 37 }
                            Write-Host "- [`e[1;${color}m$type`e[0m]$($parts[1])"
                        }
                    }
                } catch {
                    if ($_.Exception -isnot [System.Management.Automation.RuntimeException]) {
                        throw
                    }
                }
                Write-Host
                logSuccess "Qfig updated!. Run '. `$profile' or open a new session to check"
            }
        }
    } ElseIf ("config".Equals($command)) {
        If (-Not (Test-Path -Path "$_QFIG_LOCAL/config" -PathType Leaf)) {
            "# This config was copied from the 'configTemplate'" > $_QFIG_LOCAL/config
            Get-Content $_QFIG_LOC/configTemplate | Select-Object -Skip 1 >> $_QFIG_LOCAL/config
            logInfo "Copied config from configTemplate"
        }
        editFile $_QFIG_LOCAL/config
    } ElseIf ("report".Equals($command)) {
        $msg = "$initMsg`n  OsType: $($PSVersionTable.OS | Out-String)"
        logInfo $msg
    } ElseIf ("v".Equals($command) -Or "version".Equals($command)) {
        $curHead = (git -C $_QFIG_LOC log --oneline --decorate -1).Split(" ")[0]
        $branch = git -C $_QFIG_LOC symbolic-ref --short HEAD
        Write-Host "$branch ($curHead)"
    } Else {
        qfig -command help
    }
}

function funAlias() { #? works like bash 'alias', note that it would spent more time due to usage of Invoke-Expression
    param ([Parameter(Mandatory = $true)][string]$alias, [Parameter(Mandatory = $true)][string]$original, [switch]$hasArgs)
    If ($hasArgs) {
        "function global:$alias() {$original `$args}" | Invoke-Expression
    } Else {
        "function global:$alias() {$original}" | Invoke-Expression
    }
}

funAlias = "Set-Location -"
funAlias ~ "Set-Location $HOME"
funAlias .. "Set-Location ../"

function open() {
    param([string]$dir)
    if ([string]::IsNullOrWhiteSpace($dir)) {
        $dir = "."
    }
    Start-Process $dir
}

function qcmds() { #? operate available commands. Usage: qcmds commandsPrefix subcommands. -h for more
    param([string]$prefix, [string]$subCommand, [switch]$help = $false)
    If ($help -Or (-Not $prefix)) {
        logInfo "Basic usage: qcmds toolCommandsPrefix subcommands(optional). e.g., 'qcmds base'"
        $availabeCommandsNotice = "  Available Qfig tool commands(prefix):"
        Get-ChildItem $_QFIG_LOC/command | ForEach-Object {
            $itemName = $_.name
            If ($itemName -match "(.+)Commands`.ps1") {
                $availabeCommandsNotice += " $($Matches[1])"
            }
        }
        $availabeCommandsNotice
        "  Subcommands: explain(default), cat(or read, gc), vim(or edit)"
        Return
    }

    $targetFile = "$_QFIG_LOC/command/${prefix}Commands.ps1"
    If (-Not (Test-Path $targetFile -PathType Leaf)) {
		If ("local".Equals($prefix)) {
            Write-Output "# Write your only-in-this-device commands/scripts below.
			# Changes will be effective in new sessions, to make it effective immidiately by running command '. `$profile'
			# This file will be ignored by .gitignore" > $targetFile
		} Else {
			logError "$targetFile doesn't exist"
			qcmds
			Return
		}
    }

    Switch ($subCommand) {
        {"gc", "cat", "read" -contains $_} {
            Get-Content $targetFile
            Return
        }
        {"edit" -contains $_} {
            editFile $targetFile
            Return
        }
        {"", "explain" -contains $_} {
            Get-Content $targetFile | ForEach-Object {
                If ($_.StartsWith("#? ")) {
                    $exp = "`e[34m▍`e[39m"
                    $parts = $_.Split(" ")
                    for ($i = 1; $i -lt $parts.Count; $i++) {
                        $exp += "$($parts[$i]) "
                    }
                    "$exp`e[0m"
                } ElseIf ($_.StartsWith("function ")) {
                    $parts = $_.Split(" ")
                    If ("#x".Equals($parts[3])) {
                        Return
                    }
                    $suffix = " `e[0m:";
                    If ("#?".Equals($parts[3])) {
                        $suffix += "`e[0;36m"
                    } ElseIf ("#!".Equals($parts[3])){
                        $suffix += "`e[1;31m"
                    }
                    For($i = 4; $i -lt $parts.Length; $i++) {
                        $suffix += " $($parts[$i])"
                    }
                    $prefix = "`e[1;34m$($parts[1]) `e[37;2m";
                    while ($prefix.Length -lt 32) {
                        $prefix += "-"
                    }
                    $prefix = $prefix.Replace("`(`)", "`e[1;37m()`e[0m") + "`e[39;22m"
                    "$prefix$suffix`e[0m"
                } ElseIf ($_.StartsWith("funAlias ")) {
                    $parts = $_.Split(" ")
                    $exp = "`e[32mfunAlias`e[34m $($parts[1])`e[39m = `e[36m$($parts[2])"
                    for ($i = 2; $i -lt $parts.Count; $i++) {
                        $exp += " $($parts[$i])"
                    }
                    "$exp`e[0m"
                }
            }
        }
        Default {
            logError "Unknown subcomand: $subCommand"
            qcmds "-h"
            Return
        }
    }
}

function editFile() { #? edit file using the prefer text editor
    param([Parameter(Mandatory)]$path)
    If ((Test-Path $path) -And (Test-Path $path -PathType Container)) {
        logError "'$path' is a directory!"
        Return
    }
    # set prefer text editor in config <perferTextEditor> label
    Invoke-Expression "$_PREFER_TEXT_EDITOR $path"
}

function defaultV() { #? return default value
    param([Parameter(Mandatory)]$name, [Parameter(Mandatory)]$default)
    Invoke-Expression "`$cur_value = `$$name"
    If ($cur_value.Length -Eq 0) {
        Return $default
    }
    Return $cur_value
}

function defaultGV() { #? set default global value for variable
    param([Parameter(Mandatory)]$name, [Parameter(Mandatory)]$default)
    Invoke-Expression "`$cur_value = `$$name"
    If ($cur_value.Length -Eq 0) {
        $type = $value.GetType().Name
        Invoke-Expression "[$type]`$global`:$name = '$default'"
    } Else {
        $cur_value.Length
    }
}

function logSuccess() { #? log success message
	param([Parameter(Mandatory)]$text, [string]$prefix)
	qfigLog "`e[38;05;118m" $text $prefix
}

function logInfo() { #? log info
	param([Parameter(Mandatory)]$text, [string]$prefix)
	qfigLog "`e[38;05;123m" $text $prefix
}

function logWarn() { #? log warning message
	param([Parameter(Mandatory)]$text, [string]$prefix)
	qfigLog "`e[38;05;226m" $text $prefix
}

function logError() { #? log error message
	param([Parameter(Mandatory)]$text, [string]$prefix)
	qfigLog "`e[38;05;196m" $text $prefix
}

function logSilence() { #? log unconspicuous message
	param([Parameter(Mandatory)]$text)
	Write-Host "`e[2m● $text`e[0m"
}

function qfigLog() { #x
	param([Parameter(Mandatory)]$color, [Parameter(Mandatory)]$text, [string]$prefix)
	if ([string]::isNullOrEmpty($prefix)) {
		$prefix = "●"
	}
	Write-Host "$color$prefix`e[0m $text"
}

function qmap() { #? view or edit a map(which may be recognized by Qfig commands)
    param([Parameter(Mandatory)]$prefix)
    editFile "$_QFIG_LOCAL/$prefix`MappingFile"
}

function md5() { #? calculate md5. Supporting pipe.
	param([Parameter(Mandatory, ValueFromPipeline)]$text)
	process {
		# converts string to MD5 hash in hyphenated and uppercase format

		$md5 = new-object -TypeName System.Security.Cryptography.MD5CryptoServiceProvider
		$utf8 = new-object -TypeName System.Text.UTF8Encoding
		$hash = [System.BitConverter]::ToString($md5.ComputeHash($utf8.GetBytes($text)))

		# to remove hyphens and downcase letters add:
		$hash = $hash.ToLower() -replace '-', ''
		Return $hash
	}
}

function desktop() { #? show desktop path (no params) or go to desktop (by -go flag)
    param([switch]$go = $false)
    $DesktopPath = [Environment]::GetFolderPath("Desktop")
    If ($go) {
        Set-Location $DesktopPath
    } Else {
        Return $DesktopPath
    }
}

function which() { #? equivalent to shell 'which'
    # get types by [Enum]::GetNames("System.Management.Automation.CommandTypes")
    param([Parameter(Mandatory)][string]$command)
    $cmdObject = Get-Command $command 2>&1
    If ($?) {
        $type = $cmdObject.CommandType.ToString()
        If ("Function".Equals($type)) {
            "function $command() {$($cmdObject.Definition)}"
        } ElseIf ("Application".Equals($type)) {
            "`e[1mApplication:`e[0m $($cmdObject.Definition)"
        } ElseIf ("Alias".Equals($type)) {
            "`e[1mAlias of:`e[0m $($cmdObject.Definition)"
        } ElseIf ("Cmdlet".Equals($type)) {
            # e.g. Where-Object
            "`e[1mCmdlet:`e[0m`n$($cmdObject.Definition)"
        } Else {
            Write-Host "Command type: $type`nDefinition:`n"
            $($cmdObject.Definition)
        }
    }
}

function Get-CurrentHead() { #x
    param([switch]$remote = $false, [int16]$len = 9)
    $branch=git -C $_QFIG_LOC rev-parse --abbrev-ref HEAD
    If ($remote) {
        $commit=git -C $_QFIG_LOC rev-parse "$branch$u"
    } Else {
        $commit=git -C $_QFIG_LOC rev-parse "$branch"
    }
    $commit.Substring(0, $len)
}

function Get-StringWidth() { #x
    param (
        [Parameter(Mandatory = $true)]
        [string]$InputString
    )

    $width = 0
    Foreach ($char in [char[]]$InputString) {
        $unicode = [int][char]$char

        if (($unicode -ge 0x0020 -and $unicode -le 0x007E) -or ($unicode -ge 0xFF61 -and $unicode -le 0xFF9F)) {
            # half-width
            $width += 1
        } elseif (($unicode -ge 0x4E00 -and $unicode -le 0x9FFF) -or
                  ($unicode -ge 0x3040 -and $unicode -le 0x309F) -or
                  ($unicode -ge 0x30A0 -and $unicode -le 0x30FF) -or
                  ($unicode -ge 0xFF01 -and $unicode -le 0xFF5E)) {
            # full-width
            $width += 2
        } else {
            # others
            $width += 2
        }
    }

    Return $width
}

function confirm() {
    param ([string]$msg, [string]$prefix, [switch]$enterForYes = $false, [switch]$warning = $false)

    If ([string]::IsNullOrEmpty($msg)) {
        $msg = "Are you sure ?"
    }

    If ($warning) {
        If ([string]::IsNullOrEmpty($prefix)) {
            $prefix = "!"
        }
        logWarn "$msg `e[90mInput yes/Yes to confirm.`e[0m" $prefix
        $yn = Read-Host
        If ("yes".Equals($yn) -Or "Yes".Equals($yn)) {
            return $true
        }
    } Else {
        If ($enterForYes) {
            logInfo "$msg `e[90mPress Enter or Input y/Y for Yes, others for No.`e[0m" $prefix
        } Else {
			logInfo "$msg `e[90mInput y/Y for Yes, others for No.`e[0m" $prefix
        }
        $yn = Read-Host
        If (("Y", "y", "Yes", "yes" -contains $yn) -Or ($enterForYes -And [string]::IsNullOrEmpty($yn))) {
            return $true
        }
    }
    return $false
}
function tail() {
    param([Parameter(Mandatory)][string]$targetFile, [int16]$lines = 10, [switch]$follow)
    if (-Not (Test-Path -Path $targetFile -PathType Leaf)) {
        logError "target file $targetFile is not valid!"
        Return
    }
    if ($follow) {
        Get-Content $targetFile -tail $lines -wait
    } else {
        Get-Content $targetFile -tail $lines
    }
}

Function du() {
    param($Path = ".")
    forEach ($File in (Get-ChildItem $Path)) {
        if ($File.PSisContainer){   
            $Size = [Math]::Round((Get-ChildItem $File.FullName -Recurse | Measure-Object -Property Length -Sum).Sum / 1KB,2)
            $Type = "Folder"
        } else {
            $Size = $File.Length
            $Type = ""
        } [PSCustomObject]@{
            Name = $File.Name
            Type = $Type
            Size = $Size
        }
    }
}
