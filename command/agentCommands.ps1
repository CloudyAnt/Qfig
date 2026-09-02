#? CLI agent helpers (yolo / auto-approve launcher).
#? Enable with 'agent' in [enabledCommands] via 'qfig config'. Edit agents via 'qmap yolo', then refresh-qfig.
#? 'yolo' runs the mapped binary with auto-approve flags. Danger: agents may run commands without asking.

$_YOLO_MAPPING_FILE = "$_QFIG_LOCAL\yoloMappingFile"
$global:_YOLO_DANGER_WARNED = $false

If (-Not (Test-Path $_YOLO_MAPPING_FILE -PathType Leaf)) {
    @"
#For each line, the 1st occurrence of separator's left & right will be the key & value respectively.
#The default separator is '=', change it by a line like '#?-'(change to '-'), it can be changed multi times.
# default selects which agent 'yolo' uses with no name (must be another key below)
# value = binary + auto-approve flags (space-separated)
default=cursor
cursor=agent --yolo
agent=agent --yolo
claude=claude --dangerously-skip-permissions
codex=codex --yolo
kimi=kimi --yolo
"@ | Set-Content -Path $_YOLO_MAPPING_FILE -Encoding utf8
}

$_YOLO_MAPPING = qmap yolo -Output

function Get-YoloMappingKeys { #x
    ($_YOLO_MAPPING.Keys | Where-Object { $_ -ne "default" } | Sort-Object) -join " "
}

function Show-YoloHelp { #x
    $defKey = $_YOLO_MAPPING["default"]
    If ([string]::IsNullOrWhiteSpace($defKey)) { $defKey = "(unset)" }
    $keys = Get-YoloMappingKeys
    If ([string]::IsNullOrWhiteSpace($keys)) { $keys = "(none)" }
    logInfo "Usage: yolo [agent|default] [args...]"
    Write-Host "  Run a CLI agent with its auto-approve / yolo flags."
    Write-Host "  With no agent name, uses 'default' -> $defKey"
    Write-Host "  Options:"
    "    {0,-12}{1}" -f "-h, help", "Show this help"
    "    {0,-12}{1}" -f "default", "Force default agent; pass remaining args through"
    Write-Host "  Agents (qmap yolo): $keys"
    Write-Host "  After editing the map, run refresh-qfig / re-source profile to reload."
}

function Write-YoloDangerWarnOnce { #x
    If (-Not $global:_YOLO_DANGER_WARNED) {
        logWarn "Auto-approve / skip-permissions enabled for this agent"
        $global:_YOLO_DANGER_WARNED = $true
    }
}

function yolo { #? run a CLI agent with auto-approve / yolo flags. Usage: yolo [agent|default] [args...]
    $allArgs = @($args)
    If ($allArgs.Count -ge 1 -And ($allArgs[0] -eq "-h" -Or $allArgs[0] -eq "--help" -Or $allArgs[0] -eq "help")) {
        Show-YoloHelp
        Return
    }

    $agentKey = $null
    $remaining = @($allArgs)
    $useDefault = $true

    If ($allArgs.Count -ge 1 -And $allArgs[0] -eq "default") {
        $remaining = @($allArgs | Select-Object -Skip 1)
        $useDefault = $true
    } ElseIf ($allArgs.Count -ge 1 -And $allArgs[0] -ne "default" -And $_YOLO_MAPPING.ContainsKey([string]$allArgs[0])) {
        $agentKey = [string]$allArgs[0]
        $remaining = @($allArgs | Select-Object -Skip 1)
        $useDefault = $false
    } ElseIf ($allArgs.Count -ge 1 -And $allArgs[0] -ne "default") {
        $keys = Get-YoloMappingKeys
        If ([string]::IsNullOrWhiteSpace($keys)) { $keys = "(none)" }
        logWarn "Unknown agent '$($allArgs[0])'. Available: $keys. Edit with 'qmap yolo'."
        Return
    }

    If ($useDefault) {
        $agentKey = $_YOLO_MAPPING["default"]
        If ([string]::IsNullOrWhiteSpace($agentKey)) {
            logError "No 'default' agent in map. Use 'qmap yolo' to set default=<name>."
            Return
        }
        logInfo "Using default agent '$agentKey'."
    }

    $mapped = $_YOLO_MAPPING["$agentKey"]
    If ([string]::IsNullOrWhiteSpace($mapped)) {
        $keys = Get-YoloMappingKeys
        If ([string]::IsNullOrWhiteSpace($keys)) { $keys = "(none)" }
        logError "Default agent '$agentKey' is not mapped. Available: $keys. Edit with 'qmap yolo'."
        Return
    }

    $cmdParts = @($mapped -split '\s+' | Where-Object { $_ -ne "" })
    If ($cmdParts.Count -eq 0) {
        logError "Empty command for agent '$agentKey'."
        Return
    }
    $binary = $cmdParts[0]
    If (-Not (Get-Command $binary -ErrorAction SilentlyContinue)) {
        $keys = Get-YoloMappingKeys
        If ([string]::IsNullOrWhiteSpace($keys)) { $keys = "(none)" }
        logError "Binary '$binary' not found on PATH (agent '$agentKey'). Known agents: $keys"
        Return
    }

    Write-YoloDangerWarnOnce
    $flagArgs = @()
    If ($cmdParts.Count -gt 1) {
        $flagArgs = $cmdParts[1..($cmdParts.Count - 1)]
    }
    & $binary @flagArgs @remaining
}
