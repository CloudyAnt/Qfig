#? These commands only requires Powershell built-in commands

function qfig { #? Qfig preserved command. -h(help) for more
    param([string]$command, [switch]$help = $false)
    If ($help -Or "help".Equals($command)) {
        logInfo "Usage: qfig <command>`n`n  Available commands:`n"
        "    {0,-10}{1}" -f "help", "Print this help message"
        "    {0,-10}{1}" -f "update", "Update Qfig"
        "    {0,-10}{1}" -f "into", "Go into Qfig project folder"
        "    {0,-10}{1}" -f "config", "Edit config to enable commands, etc."
        "    {0,-10}{1}" -f "im", "Show initiation message again"
    } ElseIf ("into".Equals($command)) {
        Set-Location $Qfig_loc
    } ElseIf ("update".Equals($command)) {
        $curHead = $(git -C $Qfig_loc log --oneline --decorate -1).Split(" ")[0]
        $pullMessage = $(git -C $Qfig_loc pull --rebase 2>&1) -join "`r`n"
        If ($pullMessage -match ".*error.*" -Or $pullMessage -match ".*fatal.*") {
            logError "Cannot update Qfig:`n$pullMessage"
        } ElseIf ($pullMessage -match ".*up to date.*") {
            logSuccess "Qfig is up to date"
        } Else {
            logInfo "Updateing Qfig.."
            $newHead = $(git -C $Qfig_loc log --oneline --decorate -1).Split(" ")[0]
            Write-Host "`nUpdate head `e[1m$curHead`e[0m -> `e[1m$newHead`e[0m:`n"

            $typeColors = @{"refactor"= 31; "fix" = 32; "feat" = 33; "chore" = 34; "doc" = 35; "test" = 36}
            try {
                git -C $Qfig_loc log --oneline --decorate -10 | ForEach-Object {
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
    } ElseIf ("config".Equals($command)) {
        If (-Not $(Test-Path -Path "$Qfig_loc/config" -PathType Leaf)) {
            "# This config was copied from the 'configTemplate'" > $Qfig_loc/config
            Get-Content $Qfig_loc/configTemplate | Select-Object -Skip 1 >> $Qfig_loc/config
            logInfo "Copied config from configTemplate"
        }
        editFile $Qfig_loc/config
    } ElseIf ("im".Equals($command)) {
        logInfo $initMsg
    } Else {
        qfig -command help
    }
}

function =() {
    cd -
}

function ~() { #? go to home directory
    Set-Location $HOME
}

function ..() { #? go to upper level directory
   Set-Location ../
}

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
        Get-ChildItem $Qfig_loc/command | ForEach-Object {
            $itemName = $_.name
            If ($itemName -match "(.+)Commands`.ps1") {
                $availabeCommandsNotice += " $($Matches[1])"
            }
        }
        $availabeCommandsNotice
        "  Subcommands: explain(default), cat(or read, gc), vim(or edit)"
        Return
    }

    $targetFile = "$Qfig_loc/command/${prefix}Commands.ps1"
    If (-Not (Test-Path $targetFile -PathType Leaf)) {
		If ("local".Equals($prefix)) {
			Write-Output "# Write your only-in-this-device commands below. This file will be ignored by .gitignore" > $targetFile
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
        {"vim", "edit" -contains $_} {
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
                } ElseIf ($_.StartsWith("alias ")) {
                    $parts = $_.Split(" ")
                    $exp = "`e[32alias `e[34m $($parts[1]) `e[39m = `e[36m $($parts[2])"
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
    Invoke-Expression "$preferTextEditor $path"
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
    editFile "$Qfig_loc/$prefix`MappingFile"
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

function Get-StringWidth { #x
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