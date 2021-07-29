# This script only contain operations which only use system commands

function qfig { #? enter the Qfig project folder
    cd $Qfig_loc
}

function vimcs { #? edit Qfig commands
    param($prefix)

    $targetFile = "$Qfig_loc/command/" + $prefix + "Commands.ps1"
    If (Test-Path $targetFile) {
        Start-Process NotePad $targetFile
    } Else {
        Write-Warning "$targetFile doesn't exist" 
    }
}

function defaultV() { #? set default value for variable
    param([Parameter(Mandatory)]$name, [Parameter(Mandatory)$value)
    iex "`$cur_value = `$$name"
    
    If ($cur_value.Length -Eq 0) {
        iex "`$$name = $value"
    }
}
