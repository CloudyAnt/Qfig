# This script only contain operations which only use system commands

function qfig { #? enter the Qfig project folder
    cd $Qfig_loc
}

function repower() { #? reload config(Not working now)
    Write-Host "Repowering" -f blue
    . $Qfig_loc/config.ps1
    Write-Host "Repowered!"-f green
}

function ..() {
   cd ../ 
}

function vimcs { #? edit Qfig commands
    param($prefix)

    $targetFile = "$Qfig_loc/command/" + $prefix + "Commands.ps1"
    If (Test-Path $targetFile) {
        If ($IsWindows) {
            Start-Process NotePad $targetFile
        } ElseIf ($IsMacOs -Or $IsLinux) {
            vim $targetFile
        }
    } Else {
        Write-Warning "$targetFile doesn't exist" 
    }
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
