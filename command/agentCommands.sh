#? CLI agent helpers (yolo / auto-approve launcher).
#? Enable with 'agent' in [enabledCommands]. Edit agents via 'qmap yolo', then refresh-qfig.
#? 'yolo' runs the mapped binary with auto-approve flags. Danger: agents may run commands without asking.

_YOLO_MAPPING_FILE="$_QFIG_LOCAL/yoloMappingFile"
_YOLO_DANGER_WARNED=""

function +yolo:seedMappingFile() { #x
    # Prefer new name; migrate legacy agentMappingFile if present
    [ -f "$_YOLO_MAPPING_FILE" ] && return 0
    cat > "$_YOLO_MAPPING_FILE" <<'EOF'
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
EOF
}

function +yolo:loadMapping() { #x
    # Custom load so values may contain spaces (qmap awk does not quote values).
    unsetVar _YOLO_MAPPING
    declare -gA _YOLO_MAPPING
    local line key value
    while IFS= read -r line || [ -n "$line" ]; do
        case "$line" in
            ''|\#*) continue ;;
        esac
        [[ "$line" != *=* ]] && continue
        key="${line%%=*}"
        value="${line#*=}"
        _YOLO_MAPPING[$key]=$value
    done < "$_YOLO_MAPPING_FILE"
}

function +yolo:listKeys() { #x
    # Prints known agent keys (excludes default), space-separated into _TEMP
    local keys="" k
    if [[ "$_CURRENT_SHELL" = "zsh" ]]; then
        for k in "${(@k)_YOLO_MAPPING}"; do
            [ "$k" = "default" ] && continue
            keys="$keys $k"
        done
    else
        for k in "${!_YOLO_MAPPING[@]}"; do
            [ "$k" = "default" ] && continue
            keys="$keys $k"
        done
    fi
    _TEMP="${keys# }"
}

function +yolo:printHelp() { #x
    local defKey="${_YOLO_MAPPING[default]}"
    +yolo:listKeys
    logInfo "Usage: yolo [agent|--] [args...]"
    echo "  Run a CLI agent with its auto-approve / yolo flags."
    echo "  With no agent name, uses 'default' -> ${defKey:-(unset)}"
    echo "  Options:"
    printf "    %-12s%s\n" "-h, help" "Show this help"
    printf "    %-12s%s\n" "--" "Force default agent; pass remaining args through"
    echo "  Agents (qmap yolo): ${_TEMP:-(none)}"
    echo "  After editing the map, run refresh-qfig to reload."
}

function +yolo:warnOnce() { #x
    if [ -z "$_YOLO_DANGER_WARNED" ]; then
        logWarn "Auto-approve / skip-permissions enabled for this agent"
        _YOLO_DANGER_WARNED=1
    fi
}

+yolo:seedMappingFile
+yolo:loadMapping

function yolo() { #? run a CLI agent with auto-approve / yolo flags. Usage: yolo [agent|--] [args...]
    if [ "$1" = "-h" ] || [ "$1" = "--help" ] || [ "$1" = "help" ]; then
        +yolo:printHelp
        return 0
    fi

    local agentKey="" useDefault=1
    if [ "$1" = "--" ]; then
        shift
        useDefault=1
    elif [ -n "$1" ] && [ "$1" != "default" ] && [ -n "${_YOLO_MAPPING[$1]+x}" ]; then
        agentKey="$1"
        shift
        useDefault=0
    elif [ -n "$1" ] && [ "$1" != "default" ]; then
        +yolo:listKeys
        logWarn "Unknown agent '$1'. Available: ${_TEMP:-(none)}. Edit with 'qmap yolo'."
        return 1
    fi

    if [ "$useDefault" = 1 ]; then
        agentKey="${_YOLO_MAPPING[default]}"
        if [ -z "$agentKey" ]; then
            logError "No 'default' agent in map. Use 'qmap yolo' to set default=<name>."
            return 1
        fi
        logInfo "Using default agent '$agentKey'."
    fi

    local mapped="${_YOLO_MAPPING[$agentKey]}"
    if [ -z "$mapped" ]; then
        +yolo:listKeys
        logError "Default agent '$agentKey' is not mapped. Available: ${_TEMP:-(none)}. Edit with 'qmap yolo'."
        return 1
    fi

    toArray "$mapped" " "
    local -a cmdParts=("${_TEMP[@]}")
    local arrayBase binary
    arrayBase=$(getArrayBase)
    binary="${cmdParts[$arrayBase]}"

    if [ -z "$binary" ]; then
        logError "Empty command for agent '$agentKey'."
        return 1
    fi
    if ! command -v "$binary" >/dev/null 2>&1; then
        +yolo:listKeys
        logError "Binary '$binary' not found on PATH (agent '$agentKey'). Known agents: ${_TEMP:-(none)}"
        return 1
    fi

    +yolo:warnOnce
    "${cmdParts[@]}" "$@"
}
