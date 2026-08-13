#? Directory shortcuts (goto).
#? Enable with 'goto' in <enabledCommands>. Edit via 'qmap goto' or: goto <key> <path> / goto -d <key>
#? Mapping like: pa=/path/to/the/awesome/project  then: goto pa

_GOTO_MAPPING_FILE="$_QFIG_LOCAL/gotoMappingFile"

function +goto:seedMappingFile() { #x
    [ -f "$_GOTO_MAPPING_FILE" ] && return 0
    cat > "$_GOTO_MAPPING_FILE" <<'EOF'
#For each line, the 1st occurrence of separator's left & right will be the key & value respectively.
#The default separator is '=', change it by a line like '#?-'(change to '-'), it can be changed multi times.
# Example: pa=/path/to/the/awesome/project
# Then run: goto pa
# Or set/delete from CLI: goto pa /path/to/dir   |   goto -d pa
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

function +goto:printList() { #x
    +goto:listKeys
    if [ -z "$_TEMP" ]; then
        logInfo "Shortcuts: (none)"
        return 0
    fi
    logInfo "Shortcuts:"
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

function +goto:printHelp() { #x
    logInfo "Usage: goto <key>"
    echo "       goto <key> <path>          # add or replace shortcut"
    echo "       goto -d|--delete <key>     # delete shortcut"
    echo "       goto -l|--list             # list shortcuts"
    echo "  Jump to a mapped directory, or manage shortcuts."
    echo "  Options:"
    printf "    %-22s%s\n" "-h, help" "Show this help"
    printf "    %-22s%s\n" "-l, --list" "List all shortcuts"
    printf "    %-22s%s\n" "-d, --delete <key>" "Remove a shortcut"
    echo "  After editing via 'qmap goto', run refresh-qfig to reload."
    +goto:printList
}

function +goto:resolvePath() { #x
    # Expand leading ~ and . / ./...; result in _TEMP
    local path="$1"
    case "$path" in
        "~") path="$HOME" ;;
        "~/"*) path="$HOME/${path#\~/}" ;;
        "."|"./") path="$PWD" ;;
        "./"*) path="$PWD/${path#./}" ;;
    esac
    _TEMP="$path"
}

function +goto:toAbsolute() { #x
    # Resolve existing directory to absolute path; result in _TEMP
    +goto:resolvePath "$1"
    local target="$_TEMP"
    if [ ! -d "$target" ]; then
        logError "Not a directory: $target"
        return 1
    fi
    _TEMP="$(cd "$target" && pwd)" || return 1
}

function +goto:saveMapping() { #x
    # Rewrite mapping file preserving comments/blank/non-map lines.
    # $1=key  $2=value (empty => delete). Returns 2 if delete target missing.
    local key="$1" value="$2"
    local line k found=0
    local tmpfile
    tmpfile=$(mktemp) || return 1

    while IFS= read -r line || [ -n "$line" ]; do
        case "$line" in
            ''|\#*)
                printf '%s\n' "$line" >> "$tmpfile"
                continue
                ;;
        esac
        if [[ "$line" != *=* ]]; then
            printf '%s\n' "$line" >> "$tmpfile"
            continue
        fi
        k="${line%%=*}"
        if [ "$k" = "$key" ]; then
            found=1
            if [ -n "$value" ]; then
                printf '%s\n' "$key=$value" >> "$tmpfile"
            fi
        else
            printf '%s\n' "$line" >> "$tmpfile"
        fi
    done < "$_GOTO_MAPPING_FILE"

    if [ "$found" = 0 ]; then
        if [ -n "$value" ]; then
            printf '%s\n' "$key=$value" >> "$tmpfile"
        else
            rm -f "$tmpfile"
            return 2
        fi
    fi

    mv "$tmpfile" "$_GOTO_MAPPING_FILE" || return 1
}

function +goto:setMapping() { #x
    local key="$1" path="$2"
    if [ -z "$key" ] || [ -z "$path" ]; then
        logError "Usage: goto <key> <path>"
        return 1
    fi
    if [[ "$key" == *=* ]]; then
        logError "Key must not contain '='"
        return 1
    fi

    +goto:toAbsolute "$path" || return 1
    local abs="$_TEMP"
    local existed=0
    [ -n "${_GOTO_MAPPING[$key]+x}" ] && existed=1

    +goto:saveMapping "$key" "$abs" || return 1
    _GOTO_MAPPING[$key]="$abs"
    if [ "$existed" = 1 ]; then
        logSuccess "Updated shortcut '$key' -> $abs"
    else
        logSuccess "Added shortcut '$key' -> $abs"
    fi
}

function +goto:deleteMapping() { #x
    local key="$1"
    if [ -z "$key" ]; then
        logError "Usage: goto -d|--delete <key>"
        return 1
    fi
    if [ -z "${_GOTO_MAPPING[$key]+x}" ]; then
        +goto:listKeys
        logWarn "No goto mapping for: $key. Available: ${_TEMP:-(none)}."
        return 1
    fi

    +goto:saveMapping "$key" ""
    local rc=$?
    if [ "$rc" = 2 ]; then
        +goto:listKeys
        logWarn "No goto mapping for: $key. Available: ${_TEMP:-(none)}."
        return 1
    elif [ "$rc" != 0 ]; then
        return 1
    fi
    unset "_GOTO_MAPPING[$key]"
    logSuccess "Deleted shortcut '$key'"
}

+goto:seedMappingFile
+goto:loadMapping

function goto() { #? jump to / manage mapped directories. Usage: goto <key> | goto <key> <path> | goto -d <key> | goto -l
    if [ -z "$1" ] || [ "$1" = "-h" ] || [ "$1" = "--help" ] || [ "$1" = "help" ]; then
        +goto:printHelp
        return 0
    fi

    if [ "$1" = "-l" ] || [ "$1" = "--list" ]; then
        +goto:printList
        return 0
    fi

    if [ "$1" = "-d" ] || [ "$1" = "--delete" ]; then
        +goto:deleteMapping "$2"
        return $?
    fi

    local key="$1"
    if [ -n "$2" ]; then
        +goto:setMapping "$key" "$2"
        return $?
    fi

    local mapped="${_GOTO_MAPPING[$key]}"
    if [ -z "$mapped" ]; then
        +goto:listKeys
        logWarn "No goto mapping for: $key. Available: ${_TEMP:-(none)}. Set with 'goto $key <path>' or 'qmap goto'."
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
