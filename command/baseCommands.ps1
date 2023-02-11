# This script only contain operations which only use system commands

function qfig { #? enter the Qfig project folder
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

function ..() {
   Set-Location ../
}

function editCmds() { #? edit Qfig commands
    param($prefix)

    $targetFile = "$Qfig_loc/command/" + $prefix + "Commands.ps1"
    If (Test-Path $targetFile) {
        editFile $targetFile
    } Else {
        logError "$targetFile doesn't exist" 
    }
}

function editFile() {
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