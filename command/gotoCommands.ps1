#? Directory shortcuts (goto).
#? Enable with 'goto' in [enabledCommands] via 'qfig config'. Edit paths via 'qmap goto', then refresh-qfig.
#? Mapping like: pa=/path/to/the/awesome/project  then: goto pa

$_GOTO_MAPPING_FILE = "$_QFIG_LOCAL\gotoMappingFile"

If (-Not (Test-Path $_GOTO_MAPPING_FILE -PathType Leaf)) {
    @"
#For each line, the 1st occurrence of separator's left & right will be the key & value respectively.
#The default separator is '=', change it by a line like '#?-'(change to '-'), it can be changed multi times.
# Example: pa=/path/to/the/awesome/project
# Then run: goto pa
"@ | Set-Content -Path $_GOTO_MAPPING_FILE -Encoding utf8
}

$_GOTO_MAPPING = @{}
Get-Content $_GOTO_MAPPING_FILE | ForEach-Object {
    If ([string]::IsNullOrWhiteSpace($_) -Or $_.StartsWith("#")) { Return }
    $parts = $_.Split("=", 2)
    If ($parts.Length -eq 2) {
        $_GOTO_MAPPING[$parts[0]] = $parts[1]
    }
}

function Get-GotoMappingKeys { #x
    ($_GOTO_MAPPING.Keys | Sort-Object) -join " "
}

function Show-GotoHelp { #x
    logInfo "Usage: goto <key>"
    Write-Host "  Jump to a directory mapped in 'qmap goto'."
    Write-Host "  Options:"
    "    {0,-12}{1}" -f "-h, help", "Show this help"
    Write-Host "  After editing the map, run refresh-qfig / re-source profile to reload."
    If ($_GOTO_MAPPING.Count -eq 0) {
        Write-Host "  Shortcuts: (none)"
        Return
    }
    Write-Host "  Shortcuts:"
    $_GOTO_MAPPING.Keys | Sort-Object | ForEach-Object {
        "    {0,-12}{1}" -f $_, $_GOTO_MAPPING[$_]
    }
}

function Resolve-GotoPath { #x
    param([Parameter(Mandatory)][string]$path)
    If ($path -eq "~") {
        Return $HOME
    }
    If ($path.StartsWith("~/") -Or $path.StartsWith("~\")) {
        Return (Join-Path $HOME $path.Substring(2))
    }
    Return $path
}

function goto() { #? jump to a mapped directory. Usage: goto <key>
    $allArgs = @($args)
    $key = $null
    If ($allArgs.Count -ge 1) { $key = [string]$allArgs[0] }

    If ([string]::IsNullOrWhiteSpace($key) -Or $key -eq "-h" -Or $key -eq "--help" -Or $key -eq "help") {
        Show-GotoHelp
        Return
    }

    If (-Not $_GOTO_MAPPING.ContainsKey($key)) {
        $keys = Get-GotoMappingKeys
        If ([string]::IsNullOrWhiteSpace($keys)) { $keys = "(none)" }
        logWarn "No goto mapping for: $key. Available: $keys. Edit with 'qmap goto'."
        Return
    }

    $target = Resolve-GotoPath $_GOTO_MAPPING[$key]
    If (-Not (Test-Path -LiteralPath $target -PathType Container)) {
        logError "Not a directory: $target"
        Return
    }

    Set-Location -LiteralPath $target
    logInfo "Entered: $target"
}
