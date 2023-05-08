# These commands which only use system commands

function qfig { #? Qfig preserved command
    param([string]$command)
    If ("help".Equals($command)) {
        logInfo "Usage: qfig <command>`n`n  Available commands:`n"
        "    {0,-10}{1}" -f "help", "Print this help message"
        "    {0,-10}{1}" -f "update", "Update Qfig"
        "    {0,-10}{1}" -f "into", "Go into Qfig project folder"
        "    {0,-10}{1}" -f "config", "Edit config to enable commands, etc."
    } ElseIf ("into".Equals($command)) {
        Set-Location $Qfig_loc
    } ElseIf ("update".Equals($command)) {
        $pullMessage = $(git -C $Qfig_loc pull --rebase 2>&1) -join "`r`n"
        If ($pullMessage -match ".*error.*" -Or $pullMessage -match ".*fatal.*") {
            logError "Cannot update Qfig:`n$pullMessage"
        } ElseIf ($pullMessage -match ".*up to date.*") {
            logSuccess "Qfig is up to date"
        } Else {
            logSuccess "Latest changes has been pulled. Run '. `$profile' or open a new session to check"
        }
    } ElseIf ("config".Equals($command)) {
        If (-Not $(Test-Path -Path "$Qfig_loc/config" -PathType Leaf)) {
            "# This config was copied from the 'configTemplate'" > $Qfig_loc/config
            Get-Content $Qfig_loc/configTemplate | Select-Object -Skip 1 >> $Qfig_loc/config
            logInfo "Copied config from configTemplate"
        }
        editFile $Qfig_loc/config
    } Else {
        qfig -command help
    }
}

function ..() { #？go to upper level folder
   Set-Location ../
}

function qcmds() { #? operate available commands. syntax: qcmds commandsPrefix subcommands. -h for more
    param([string]$prefix, [string]$subCommand, [switch]$help = $false)
    If ($help -Or (-Not $prefix)) {
        logInfo "Basic syntax: qcmds toolCommandsPrefix subcommands(optional). e.g., 'qcmds base'"
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
                If ($_.StartsWith("function")) {
                    $parts = $_.Split(" ")
                    If ("#x".Equals($parts[3])) {
                        Return
                    }
                    If ("#?".Equals($parts[3])) {
                        $exp = "`e[0m:`e[0;36m"
                    } ElseIf ("#!".Equals($parts[3])){
                        $exp = "`e[0m:`e[1;31m"
                    } Else {
                        Return
                    }
                    For($i = 4; $i -lt $parts.Length; $i++) {
                        $exp += " $($parts[$i])"
                    }
                    $line = $("{0,-30}{1}" -f "`e[1;34m$($parts[1])`e[0m", $exp).Replace("`(`)", "`e[1;37m()`e[0m")
                    "$line`e[0m"
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
    If (Test-Path $path) {
        If (Test-Path $path -PathType Leaf) {
            # set prefer text editor in config <perferTextEditor> label
            Invoke-Expression "$preferTextEditor $path"
        } Else {
            logError "'$path' is a directory!"
        }
    } Else {
        logError "'$path' is NOT a file!"
    }
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

function logSuccess() {
	param([Parameter(Mandatory)]$text, [string]$prefix)
	qfigLog "`e[38;05;118m" $text $prefix
}

function logInfo() {
	param([Parameter(Mandatory)]$text, [string]$prefix)
	qfigLog "`e[38;05;123m" $text $prefix
}

function logWarn() {
	param([Parameter(Mandatory)]$text, [string]$prefix)
	qfigLog "`e[38;05;226m" $text $prefix
}

function logError() {
	param([Parameter(Mandatory)]$text, [string]$prefix)
	qfigLog "`e[38;05;196m" $text $prefix
}

function logSilence() {
	param([Parameter(Mandatory)]$text)
	Write-Host "`e[2m● $text`e[0m"
}

function qfigLog() {
	param([Parameter(Mandatory)]$color, [Parameter(Mandatory)]$text, [string]$prefix)
	if ([string]::isNullOrEmpty($prefix)) {
		$prefix = "●"
	}
	Write-Host "$color$prefix`e[0m $text"
}

function qmap() {
    param([Parameter(Mandatory)]$prefix)
    editFile "$Qfig_loc/$prefix`MappingFile"
}

function md5() {
	param([Parameter(Mandatory, ValueFromPipeline)]$text)
	process {
		#converts string to MD5 hash in hyphenated and uppercase format

		$md5 = new-object -TypeName System.Security.Cryptography.MD5CryptoServiceProvider
		$utf8 = new-object -TypeName System.Text.UTF8Encoding
		$hash = [System.BitConverter]::ToString($md5.ComputeHash($utf8.GetBytes($text)))

		#to remove hyphens and downcase letters add:
		$hash = $hash.ToLower() -replace '-', ''
		Return $hash
		$null = $sapi.Speak($Text)
	}
}
