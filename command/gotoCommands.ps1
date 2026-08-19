#? Directory shortcuts (goto).
#? Enable with 'goto' in <enabledCommands> via 'qfig config'. Edit via 'qmap goto' or: goto <key> <path> / goto -d <key>
#? Mapping like: pa=/path/to/the/awesome/project  then: goto pa

$_GOTO_MAPPING_FILE = "$_QFIG_LOCAL\gotoMappingFile"

If (-Not (Test-Path $_GOTO_MAPPING_FILE -PathType Leaf)) {
    @"
#For each line, the 1st occurrence of separator's left & right will be the key & value respectively.
#The default separator is '=', change it by a line like '#?-'(change to '-'), it can be changed multi times.
# Example: pa=/path/to/the/awesome/project
# Then run: goto pa
# Or set/delete from CLI: goto pa /path/to/dir   |   goto -d pa
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

function Show-GotoList { #x
    If ($_GOTO_MAPPING.Count -eq 0) {
        logInfo "Shortcuts: (none)"
        Return
    }
    logInfo "Shortcuts:"
    $_GOTO_MAPPING.Keys | Sort-Object | ForEach-Object {
        "    {0,-12}{1}" -f $_, $_GOTO_MAPPING[$_]
    }
}

function Show-GotoHelp { #x
    logInfo "Usage: goto <key>"
    Write-Host "       goto <key> <path>          # add or replace shortcut"
    Write-Host "       goto -d|--delete <key>     # delete shortcut"
    Write-Host "       goto -l|--list             # list shortcuts"
    Write-Host "  Jump to a mapped directory, or manage shortcuts."
    Write-Host "  Options:"
    "    {0,-22}{1}" -f "-h, help", "Show this help"
    "    {0,-22}{1}" -f "-l, --list", "List all shortcuts"
    "    {0,-22}{1}" -f "-d, --delete <key>", "Remove a shortcut"
    Write-Host "  After editing via 'qmap goto', run refresh-qfig / re-source profile to reload."
    Show-GotoList
}

function Resolve-GotoPath { #x
    param([Parameter(Mandatory)][string]$path)
    If ($path -eq "~") {
        Return $HOME
    }
    If ($path.StartsWith("~/") -Or $path.StartsWith("~\")) {
        Return (Join-Path $HOME $path.Substring(2))
    }
    $cwd = (Get-Location).Path
    If ($path -eq "." -Or $path -eq "./" -Or $path -eq ".\") {
        Return $cwd
    }
    If ($path.StartsWith("./") -Or $path.StartsWith(".\")) {
        Return (Join-Path $cwd $path.Substring(2))
    }
    Return $path
}

function ConvertTo-GotoAbsolutePath { #x
    param([Parameter(Mandatory)][string]$path)
    $target = Resolve-GotoPath $path
    If (-Not (Test-Path -LiteralPath $target -PathType Container)) {
        logError "Not a directory: $target"
        Return $null
    }
    Return (Resolve-Path -LiteralPath $target).Path
}

function Save-GotoMapping { #x
    # Rewrite mapping file preserving comments/blank/non-map lines.
    # Empty value => delete. Returns $true on success; $false if delete target missing.
    param(
        [Parameter(Mandatory)][string]$key,
        [string]$value
    )
    $lines = @(Get-Content -LiteralPath $_GOTO_MAPPING_FILE)
    $out = [System.Collections.Generic.List[string]]::new()
    $found = $false
    $deleting = [string]::IsNullOrEmpty($value)

    foreach ($line in $lines) {
        If ([string]::IsNullOrWhiteSpace($line) -Or $line.StartsWith("#")) {
            $out.Add($line)
            Continue
        }
        If (-Not $line.Contains("=")) {
            $out.Add($line)
            Continue
        }
        $parts = $line.Split("=", 2)
        If ($parts[0] -eq $key) {
            $found = $true
            If (-Not $deleting) {
                $out.Add("$key=$value")
            }
        } Else {
            $out.Add($line)
        }
    }

    If (-Not $found) {
        If ($deleting) {
            Return $false
        }
        $out.Add("$key=$value")
    }

    $out | Set-Content -LiteralPath $_GOTO_MAPPING_FILE -Encoding utf8
    Return $true
}

function Set-GotoMapping { #x
    param(
        [Parameter(Mandatory)][string]$key,
        [Parameter(Mandatory)][string]$path
    )
    If ($key.Contains("=")) {
        logError "Key must not contain '='"
        Return
    }
    $abs = ConvertTo-GotoAbsolutePath $path
    If ($null -eq $abs) { Return }

    $existed = $_GOTO_MAPPING.ContainsKey($key)
    $previous = If ($existed) { [string]$_GOTO_MAPPING[$key] } Else { "" }
    If (-Not (Save-GotoMapping -key $key -value $abs)) { Return }
    $_GOTO_MAPPING[$key] = $abs
    If ($existed) {
        logSuccess "Updated shortcut '$key' -> $abs"
        logInfo "Previous: $previous (revert with: goto $key '$previous')"
    } Else {
        logSuccess "Added shortcut '$key' -> $abs"
    }
}

function Remove-GotoMapping { #x
    param([Parameter(Mandatory)][string]$key)
    If (-Not $_GOTO_MAPPING.ContainsKey($key)) {
        $keys = Get-GotoMappingKeys
        If ([string]::IsNullOrWhiteSpace($keys)) { $keys = "(none)" }
        logWarn "No goto mapping for: $key. Available: $keys."
        Return
    }
    If (-Not (Save-GotoMapping -key $key -value "")) {
        $keys = Get-GotoMappingKeys
        If ([string]::IsNullOrWhiteSpace($keys)) { $keys = "(none)" }
        logWarn "No goto mapping for: $key. Available: $keys."
        Return
    }
    $_GOTO_MAPPING.Remove($key) | Out-Null
    logSuccess "Deleted shortcut '$key'"
}

function goto() { #? jump to / manage mapped directories. Usage: goto <key> | goto <key> <path> | goto -d <key> | goto -l
    $allArgs = @($args)
    If ($allArgs.Count -eq 0) {
        Show-GotoHelp
        Return
    }

    $first = [string]$allArgs[0]
    If ($first -eq "-h" -Or $first -eq "--help" -Or $first -eq "help") {
        Show-GotoHelp
        Return
    }

    If ($first -eq "-l" -Or $first -eq "--list") {
        Show-GotoList
        Return
    }

    If ($first -eq "-d" -Or $first -eq "--delete") {
        If ($allArgs.Count -lt 2 -Or [string]::IsNullOrWhiteSpace([string]$allArgs[1])) {
            logError "Usage: goto -d|--delete <key>"
            Return
        }
        Remove-GotoMapping -key ([string]$allArgs[1])
        Return
    }

    $key = $first
    If ($allArgs.Count -ge 2) {
        Set-GotoMapping -key $key -path ([string]$allArgs[1])
        Return
    }

    If (-Not $_GOTO_MAPPING.ContainsKey($key)) {
        $keys = Get-GotoMappingKeys
        If ([string]::IsNullOrWhiteSpace($keys)) { $keys = "(none)" }
        logWarn "No goto mapping for: $key. Available: $keys. Set with 'goto $key <path>' or 'qmap goto'."
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
