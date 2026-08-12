#? Directory shortcuts (goto).
#? Enable with 'goto' in <enabledCommands>. Edit paths via 'qmap goto', then refresh-qfig.
#? Mapping like: pa=/path/to/the/awesome/project  then: goto pa

_GOTO_MAPPING_FILE="$_QFIG_LOCAL/gotoMappingFile"

function +goto:seedMappingFile() { #x
    [ -f "$_GOTO_MAPPING_FILE" ] && return 0
    cat > "$_GOTO_MAPPING_FILE" <<'EOF'
#For each line, the 1st occurrence of separator's left & right will be the key & value respectively.
#The default separator is '=', change it by a line like '#?-'(change to '-'), it can be changed multi times.
# Example: pa=/path/to/the/awesome/project
# Then run: goto pa
EOF
}

function +goto:loadMapping() { #x
    # Custom load so path values may contain spaces (qmap awk does not quote values).
    unsetVar _GOTO_MAPPING
    declare -gA _GOTO_MAPPING
    local line key value
    while IFS= read -r line || [ -n "$line" ]; do
        case "$line" in
            ''|\#*) continue ;;
        esac
        [[ "$line" != *=* ]] && continue
        key="${line%%=*}"
        value="${line#*=}"
        _GOTO_MAPPING[$key]="$value"
    done < "$_GOTO_MAPPING_FILE"
}

function +goto:listKeys() { #x
    # Prints keys space-separated into _TEMP
    local keys="" k
    if [[ "$_CURRENT_SHELL" = "zsh" ]]; then
        for k in "${(@k)_GOTO_MAPPING}"; do
            keys="$keys $k"
        done
    else
        for k in "${!_GOTO_MAPPING[@]}"; do
            keys="$keys $k"
        done
    fi
    _TEMP="${keys# }"
}

function +goto:printHelp() { #x
    logInfo "Usage: goto <key>"
    echo "  Jump to a directory mapped in 'qmap goto'."
    echo "  Options:"
    printf "    %-12s%s\n" "-h, help" "Show this help"
    echo "  After editing the map, run refresh-qfig to reload."
    +goto:listKeys
    if [ -z "$_TEMP" ]; then
        echo "  Shortcuts: (none)"
        return 0
    fi
    echo "  Shortcuts:"
    local k
    if [[ "$_CURRENT_SHELL" = "zsh" ]]; then
        for k in "${(@k)_GOTO_MAPPING}"; do
            printf "    %-12s%s\n" "$k" "${_GOTO_MAPPING[$k]}"
        done
    else
        for k in "${!_GOTO_MAPPING[@]}"; do
            printf "    %-12s%s\n" "$k" "${_GOTO_MAPPING[$k]}"
        done
    fi
}

function +goto:resolvePath() { #x
    # Expand leading ~; result in _TEMP
    local path="$1"
    case "$path" in
        "~") path="$HOME" ;;
        "~/"*) path="$HOME/${path#\~/}" ;;
    esac
    _TEMP="$path"
}

+goto:seedMappingFile
+goto:loadMapping

function goto() { #? jump to a mapped directory. Usage: goto <key>
    if [ -z "$1" ] || [ "$1" = "-h" ] || [ "$1" = "--help" ] || [ "$1" = "help" ]; then
        +goto:printHelp
        return 0
    fi

    local key="$1"
    local mapped="${_GOTO_MAPPING[$key]}"
    if [ -z "$mapped" ]; then
        +goto:listKeys
        logWarn "No goto mapping for: $key. Available: ${_TEMP:-(none)}. Edit with 'qmap goto'."
        return 1
    fi

    +goto:resolvePath "$mapped"
    local target="$_TEMP"
    if [ ! -d "$target" ]; then
        logError "Not a directory: $target"
        return 1
    fi

    cd "$target" || return 1
    logInfo "Entered: $target"
}
