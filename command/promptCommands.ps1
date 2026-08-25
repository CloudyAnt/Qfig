#? Path-based command-line prefix (prompt).
#? Enable with 'prompt' in [enabledCommands] via 'qfig config'. Edit via 'qmap prompt' or: qprompt <path> <label>
#? Mapping like: ~=🏠  then cwd $HOME shows 🏠>

$_PROMPT_MAPPING_FILE = "$_QFIG_LOCAL\promptMappingFile"

If (-Not (Test-Path $_PROMPT_MAPPING_FILE -PathType Leaf)) {
    @"
#For each line, the 1st occurrence of separator's left & right will be the key & value respectively.
#The default separator is '=', change it by a line like '#?-'(change to '-'), it can be changed multi times.
# Example: ~=🏠
# Then the prompt shows 🏠> when cwd is home, 🏠\subdir when under home.
# Or set/delete from CLI: qprompt ~ 🏠   |   qprompt -d ~
~=🏠
"@ | Set-Content -Path $_PROMPT_MAPPING_FILE -Encoding utf8
}

$_PROMPT_MAPPING = qmap prompt -Output
If ($null -eq $_PROMPT_MAPPING) {
    $_PROMPT_MAPPING = @{}
}

function Get-PromptMappingKeys { #x
    ($_PROMPT_MAPPING.Keys | Sort-Object) -join " "
}

function Show-PromptList { #x
    If ($_PROMPT_MAPPING.Count -eq 0) {
        logInfo "Prompt labels: (none)"
        Return
    }
    logInfo "Prompt labels:"
    $_PROMPT_MAPPING.Keys | Sort-Object | ForEach-Object {
        "    {0,-24}{1}" -f $_, $_PROMPT_MAPPING[$_]
    }
}

function Show-PromptHelp { #x
    logInfo "Usage: qprompt <path> <label>"
    Write-Host "       qprompt <path>             # preview label for a path"
    Write-Host "       qprompt -d|--delete <path> # delete mapping"
    Write-Host "       qprompt -l|--list          # list mappings"
    Write-Host "  Set a prompt label for a directory. Longest path prefix wins."
    Write-Host "  Options:"
    "    {0,-22}{1}" -f "-h, help", "Show this help"
    "    {0,-22}{1}" -f "-l, --list", "List all prompt labels"
    "    {0,-22}{1}" -f "-d, --delete <path>", "Remove a prompt label"
    Write-Host "  After editing via 'qmap prompt', run refresh-qfig / re-source profile to reload."
}

function Resolve-PromptPath { #x
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

function ConvertTo-PromptAbsolutePath { #x
    param([Parameter(Mandatory)][string]$path)
    $target = Resolve-PromptPath $path
    If (-Not (Test-Path -LiteralPath $target -PathType Container)) {
        logError "Not a directory: $target"
        Return $null
    }
    Return (Resolve-Path -LiteralPath $target).Path
}

function Get-PromptCanonPath { #x
    param([Parameter(Mandatory)][string]$path)
    $p = $path
    If ($IsWindows) {
        $p = $p -replace '/', '\'
        $p = $p.TrimEnd('\')
        If ($p -match '^[A-Za-z]:$') {
            $p = "$p\"
        }
        Return $p.ToLowerInvariant()
    }
    $p = $p -replace '\\', '/'
    If ($p -ne "/") {
        $p = $p.TrimEnd('/')
        If ([string]::IsNullOrEmpty($p)) { $p = "/" }
    }
    Return $p
}

function Test-PromptPathPrefix { #x
    param(
        [Parameter(Mandatory)][string]$canonCurrent,
        [Parameter(Mandatory)][string]$canonKey
    )
    If ($canonCurrent -eq $canonKey) {
        Return $true
    }
    $ds = If ($IsWindows) { '\' } Else { '/' }
    $sep = If ($canonKey.EndsWith($ds)) { '' } Else { $ds }
    Return $canonCurrent.StartsWith($canonKey + $sep, [StringComparison]::Ordinal)
}

function ConvertTo-PromptStoredPath { #x
    param([Parameter(Mandatory)][string]$abs)
    $homePath = $HOME.TrimEnd('\', '/')
    $norm = $abs.TrimEnd('\', '/')
    $cmp = If ($IsWindows) { [StringComparison]::OrdinalIgnoreCase } Else { [StringComparison]::Ordinal }
    If ($norm.Equals($homePath, $cmp)) {
        Return "~"
    }
    $homePrefixLen = $homePath.Length
    If ($norm.Length -gt $homePrefixLen) {
        $sep = $norm[$homePrefixLen]
        If (($sep -eq [char]'\' -Or $sep -eq [char]'/') -And $norm.Substring(0, $homePrefixLen).Equals($homePath, $cmp)) {
            $rel = $norm.Substring($homePrefixLen).TrimStart('\', '/')
            Return "~/" + ($rel -replace '\\', '/')
        }
    }
    Return $abs
}

function Expand-PromptStoredPath { #x
    param([Parameter(Mandatory)][string]$stored)
    If ($stored -eq "~") {
        Return $HOME
    }
    If ($stored.StartsWith("~/") -Or $stored.StartsWith("~\")) {
        Return (Join-Path $HOME $stored.Substring(2))
    }
    Return $stored
}

function Find-PromptMappingKey { #x
    param([Parameter(Mandatory)][string]$path)
    $resolved = Resolve-PromptPath $path
    $stored = $null
    If (Test-Path -LiteralPath $resolved -PathType Container) {
        $abs = (Resolve-Path -LiteralPath $resolved).Path
        $stored = ConvertTo-PromptStoredPath $abs
        If ($_PROMPT_MAPPING.ContainsKey($stored)) {
            Return $stored
        }
        $want = Get-PromptCanonPath $abs
    } Else {
        $stored = ConvertTo-PromptStoredPath $resolved
        If ($_PROMPT_MAPPING.ContainsKey($stored)) {
            Return $stored
        }
        If ($_PROMPT_MAPPING.ContainsKey($path)) {
            Return $path
        }
        $want = Get-PromptCanonPath (Expand-PromptStoredPath $stored)
    }
    foreach ($k in @($_PROMPT_MAPPING.Keys)) {
        If ((Get-PromptCanonPath (Expand-PromptStoredPath $k)) -eq $want) {
            Return $k
        }
    }
    Return $null
}

function Get-PromptLabel { #x
    param([Parameter(Mandatory)][string]$currentPath)
    $canonCurrent = Get-PromptCanonPath $currentPath
    $bestLen = -1
    $bestExpanded = $null
    $bestLabel = $null

    foreach ($stored in @($_PROMPT_MAPPING.Keys)) {
        $expanded = Expand-PromptStoredPath $stored
        $canonKey = Get-PromptCanonPath $expanded
        If ((Test-PromptPathPrefix $canonCurrent $canonKey) -And $canonKey.Length -gt $bestLen) {
            $bestLen = $canonKey.Length
            $bestExpanded = $expanded
            $bestLabel = [string]$_PROMPT_MAPPING[$stored]
        }
    }

    If ($null -ne $bestLabel) {
        $rel = [IO.Path]::GetRelativePath($bestExpanded, $currentPath)
        If ($rel -eq '.' -Or [string]::IsNullOrEmpty($rel)) {
            Return $bestLabel
        }
        Return "$bestLabel$([IO.Path]::DirectorySeparatorChar)$rel"
    }

    $homeCanon = Get-PromptCanonPath $HOME
    If (Test-PromptPathPrefix $canonCurrent $homeCanon) {
        $rel = [IO.Path]::GetRelativePath($HOME, $currentPath)
        If ($rel -eq '.' -Or [string]::IsNullOrEmpty($rel)) {
            Return "~"
        }
        Return "~$([IO.Path]::DirectorySeparatorChar)$rel"
    }
    Return $currentPath
}

function Save-PromptMapping { #x
    param(
        [Parameter(Mandatory)][string]$key,
        [string]$value
    )
    $lines = @(Get-Content -LiteralPath $_PROMPT_MAPPING_FILE)
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

    $out | Set-Content -LiteralPath $_PROMPT_MAPPING_FILE -Encoding utf8
    Return $true
}

function Set-PromptMapping { #x
    param(
        [Parameter(Mandatory)][string]$path,
        [Parameter(Mandatory)][string]$label
    )
    If ($path.Contains("=")) {
        logError "Path must not contain '='"
        Return
    }
    If ([string]::IsNullOrWhiteSpace($label)) {
        logError "Label must not be empty"
        Return
    }
    $abs = ConvertTo-PromptAbsolutePath $path
    If ($null -eq $abs) { Return }

    $stored = ConvertTo-PromptStoredPath $abs
    $canonNew = Get-PromptCanonPath $abs
    foreach ($k in @($_PROMPT_MAPPING.Keys)) {
        If ($k -ne $stored -And (Get-PromptCanonPath (Expand-PromptStoredPath $k)) -eq $canonNew) {
            Save-PromptMapping -key $k -value "" | Out-Null
            $_PROMPT_MAPPING.Remove($k) | Out-Null
        }
    }

    $existed = $_PROMPT_MAPPING.ContainsKey($stored)
    $previous = If ($existed) { [string]$_PROMPT_MAPPING[$stored] } Else { "" }
    If (-Not (Save-PromptMapping -key $stored -value $label)) { Return }
    $_PROMPT_MAPPING[$stored] = $label
    If ($existed) {
        logSuccess "Updated prompt '$stored' -> $label"
        logInfo "Previous: $previous (revert with: qprompt $stored '$previous')"
    } Else {
        logSuccess "Added prompt '$stored' -> $label"
    }
}

function Remove-PromptMapping { #x
    param([Parameter(Mandatory)][string]$path)
    $key = Find-PromptMappingKey $path
    If ([string]::IsNullOrEmpty($key)) {
        $keys = Get-PromptMappingKeys
        If ([string]::IsNullOrWhiteSpace($keys)) { $keys = "(none)" }
        logWarn "No prompt mapping for: $path. Available: $keys."
        Return
    }
    If (-Not (Save-PromptMapping -key $key -value "")) {
        $keys = Get-PromptMappingKeys
        If ([string]::IsNullOrWhiteSpace($keys)) { $keys = "(none)" }
        logWarn "No prompt mapping for: $path. Available: $keys."
        Return
    }
    $_PROMPT_MAPPING.Remove($key) | Out-Null
    logSuccess "Deleted prompt '$key'"
}

function qprompt { #? set path prompt labels. Usage: qprompt <path> <label> | qprompt <path> | qprompt -d <path> | qprompt -l
    $allArgs = @($args)
    If ($allArgs.Count -eq 0) {
        Show-PromptList
        logInfo "Run 'qprompt -h' for help."
        Return
    }

    $first = [string]$allArgs[0]
    If ($first -eq "-h" -Or $first -eq "--help" -Or $first -eq "help") {
        Show-PromptHelp
        Return
    }

    If ($first -eq "-l" -Or $first -eq "--list") {
        Show-PromptList
        Return
    }

    If ($first -eq "-d" -Or $first -eq "--delete") {
        If ($allArgs.Count -lt 2 -Or [string]::IsNullOrWhiteSpace([string]$allArgs[1])) {
            logError "Usage: qprompt -d|--delete <path>"
            Return
        }
        Remove-PromptMapping -path ([string]$allArgs[1])
        Return
    }

    If ($allArgs.Count -ge 2) {
        Set-PromptMapping -path $first -label ([string]$allArgs[1])
        Return
    }

    $target = Resolve-PromptPath $first
    If (-Not (Test-Path -LiteralPath $target -PathType Container)) {
        logError "Not a directory: $target"
        Return
    }
    $abs = (Resolve-Path -LiteralPath $target).Path
    logInfo "Prompt for ${abs}: $(Get-PromptLabel $abs)"
}

function prompt { #x
    try {
        $loc = $ExecutionContext.SessionState.Path.CurrentLocation
        If ($loc.Provider.Name -eq "FileSystem") {
            $location = Get-PromptLabel $loc.Path
        } Else {
            $location = $loc.Path
        }
    } catch {
        $location = $ExecutionContext.SessionState.Path.CurrentLocation.Path
    }
    "$location$('>' * ($nestedPromptLevel + 1)) "
}
