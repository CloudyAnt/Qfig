# This script only contain operations which only use system commands

function qfig { #? enter the Qfig project folder
    cd $Qfig_loc
}

function ..() {
   cd ../ 
}

function editCmds() { #? edit Qfig commands
    param($prefix)

    $targetFile = "$Qfig_loc/command/" + $prefix + "Commands.ps1"
    If (Test-Path $targetFile) {
        editFile $targetFile
    } Else {
        Write-Warning "$targetFile doesn't exist" 
    }
}

function editFile() {
    param([Parameter(Mandatory)]$path)
    # set prefer text editor in config <perferTextEditor> label
    Invoke-Expression "$preferTextEditor $path"
} 

function defaultV() { #? return default value
    param([Parameter(Mandatory)]$name, [Parameter(Mandatory)]$default)
    iex "`$cur_value = `$$name"
    If ($cur_value.Length -Eq 0) {
        Return $default
    }
    Return $cur_value
}

function defaultGV() { #? set default global value for variable
    param([Parameter(Mandatory)]$name, [Parameter(Mandatory)]$default)
    iex "`$cur_value = `$$name"
    If ($cur_value.Length -Eq 0) {
        $type = $value.GetType().Name
        iex "[$type]`$global`:$name = '$default'"
    } Else {
        $cur_value.Length
    }
}

function logSuccess() {
	param([Parameter(Mandatory)]$text)
	logColor green $text
}

function logInfo() {
	param([Parameter(Mandatory)]$text)
	logColor blue $text
}

function logWarn() {
	param([Parameter(Mandatory)]$text)
	logColor yellow $text
}

function logError() {
	param([Parameter(Mandatory)]$text)
	logColor red $text
}

function logColor() {
	param([Parameter(Mandatory)]$dotColor, [Parameter(Mandatory)]$text)
	Write-Host "●" -ForegroundColor $dotColor -NoNewLine
	Write-Host " $text"
}
