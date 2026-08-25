#? Path-based command-line prefix (prompt).
#? Enable with 'prompt' in [enabledCommands]. Edit via 'qmap prompt' or: qprompt <path> <label>
#? Mapping like: ~=🏠  then cwd $HOME shows 🏠>

_PROMPT_MAPPING_FILE="$_QFIG_LOCAL/promptMappingFile"

function +prompt:seedMappingFile() { #x
    [ -f "$_PROMPT_MAPPING_FILE" ] && return 0
    cat > "$_PROMPT_MAPPING_FILE" <<'EOF'
#For each line, the 1st occurrence of separator's left & right will be the key & value respectively.
#The default separator is '=', change it by a line like '#?-'(change to '-'), it can be changed multi times.
# Example: ~=🏠
# Then the prompt shows 🏠> when cwd is home, 🏠/subdir when under home.
# Or set/delete from CLI: qprompt ~ 🏠   |   qprompt -d ~
~=🏠
EOF
}

function +prompt:loadMapping() { #x
    unsetVar _PROMPT_MAPPING
    declare -gA _PROMPT_MAPPING
    local line key value
    while IFS= read -r line || [ -n "$line" ]; do
        case "$line" in
            ''|\#*) continue ;;
        esac
        [[ "$line" != *=* ]] && continue
        key="${line%%=*}"
        value="${line#*=}"
        _PROMPT_MAPPING[$key]="$value"
    done < "$_PROMPT_MAPPING_FILE"
}

function +prompt:listKeys() { #x
    local keys="" k
    if [[ "$_CURRENT_SHELL" = "zsh" ]]; then
        for k in "${(@k)_PROMPT_MAPPING}"; do
            keys="$keys $k"
        done
    else
        for k in "${!_PROMPT_MAPPING[@]}"; do
            keys="$keys $k"
        done
    fi
    _TEMP="${keys# }"
}

function +prompt:printList() { #x
    +prompt:listKeys
    if [ -z "$_TEMP" ]; then
        logInfo "Prompt labels: (none)"
        return 0
    fi
    logInfo "Prompt labels:"
    local k
    if [[ "$_CURRENT_SHELL" = "zsh" ]]; then
        for k in "${(@k)_PROMPT_MAPPING}"; do
            printf "    %-24s%s\n" "$k" "${_PROMPT_MAPPING[$k]}"
        done
    else
        for k in "${!_PROMPT_MAPPING[@]}"; do
            printf "    %-24s%s\n" "$k" "${_PROMPT_MAPPING[$k]}"
        done
    fi
}

function +prompt:printHelp() { #x
    logInfo "Usage: qprompt <path> <label>"
    echo "       qprompt <path>             # preview label for a path"
    echo "       qprompt -d|--delete <path> # delete mapping"
    echo "       qprompt -l|--list          # list mappings"
    echo "  Set a prompt label for a directory. Longest path prefix wins."
    echo "  Options:"
    printf "    %-22s%s\n" "-h, help" "Show this help"
    printf "    %-22s%s\n" "-l, --list" "List all prompt labels"
    printf "    %-22s%s\n" "-d, --delete <path>" "Remove a prompt label"
    echo "  After editing via 'qmap prompt', run refresh-qfig to reload."
}

function +prompt:resolvePath() { #x
    local path="$1"
    case "$path" in
        "~") path="$HOME" ;;
        "~/"*) path="$HOME/${path#\~/}" ;;
        "."|"./") path="$PWD" ;;
        "./"*) path="$PWD/${path#./}" ;;
    esac
    _TEMP="$path"
}

function +prompt:toAbsolute() { #x
    +prompt:resolvePath "$1"
    local target="$_TEMP"
    if [ ! -d "$target" ]; then
        logError "Not a directory: $target"
        return 1
    fi
    _TEMP="$(cd "$target" && pwd)" || return 1
}

function +prompt:canon() { #x
    local p="$1"
    case "$p" in
        "~") p="$HOME" ;;
        "~/"*) p="$HOME/${p#\~/}" ;;
    esac
    if [ "$p" != "/" ]; then
        p="${p%/}"
        [ -z "$p" ] && p="/"
    fi
    _TEMP="$p"
}

function +prompt:toStored() { #x
    local abs="$1"
    local home="${HOME%/}"
    abs="${abs%/}"
    [ -z "$abs" ] && abs="/"
    if [ "$abs" = "$home" ]; then
        _TEMP="~"
        return 0
    fi
    if [[ "$abs" == "$home"/* ]]; then
        _TEMP="~/${abs#"$home"/}"
        return 0
    fi
    _TEMP="$abs"
}

function +prompt:findKey() { #x
    local path="$1"
    +prompt:resolvePath "$path"
    local resolved="$_TEMP"
    local stored want k
    if [ -d "$resolved" ]; then
        local abs
        abs="$(cd "$resolved" && pwd)" || return 1
        +prompt:toStored "$abs"
        stored="$_TEMP"
        +prompt:canon "$abs"
        want="$_TEMP"
    else
        +prompt:toStored "$resolved"
        stored="$_TEMP"
        +prompt:canon "$stored"
        want="$_TEMP"
    fi
    if [ -n "${_PROMPT_MAPPING[$stored]+x}" ]; then
        _TEMP="$stored"
        return 0
    fi
    if [ -n "${_PROMPT_MAPPING[$path]+x}" ]; then
        _TEMP="$path"
        return 0
    fi
    if [[ "$_CURRENT_SHELL" = "zsh" ]]; then
        for k in "${(@k)_PROMPT_MAPPING}"; do
            +prompt:canon "$k"
            if [ "$_TEMP" = "$want" ]; then
                _TEMP="$k"
                return 0
            fi
        done
    else
        for k in "${!_PROMPT_MAPPING[@]}"; do
            +prompt:canon "$k"
            if [ "$_TEMP" = "$want" ]; then
                _TEMP="$k"
                return 0
            fi
        done
    fi
    _TEMP=""
    return 1
}

function +prompt:isPrefix() { #x
    # $1=canonCurrent $2=canonKey. 0 if current is key or under key.
    local current="$1" key="$2" prefix
    [ "$current" = "$key" ] && return 0
    prefix="$key"
    [ "$prefix" = "/" ] && prefix=""
    [[ "$current" == "$prefix"/* ]]
}

function +prompt:resolveLabel() { #x
    local current="${1:-$PWD}"
    +prompt:canon "$current"
    local canonCurrent="$_TEMP"
    local bestLen=-1 bestKey="" bestLabel="" k canonKey

    if [[ "$_CURRENT_SHELL" = "zsh" ]]; then
        for k in "${(@k)_PROMPT_MAPPING}"; do
            +prompt:canon "$k"
            canonKey="$_TEMP"
            if +prompt:isPrefix "$canonCurrent" "$canonKey" && [ "${#canonKey}" -gt "$bestLen" ]; then
                bestLen="${#canonKey}"
                bestKey="$canonKey"
                bestLabel="${_PROMPT_MAPPING[$k]}"
            fi
        done
    else
        for k in "${!_PROMPT_MAPPING[@]}"; do
            +prompt:canon "$k"
            canonKey="$_TEMP"
            if +prompt:isPrefix "$canonCurrent" "$canonKey" && [ "${#canonKey}" -gt "$bestLen" ]; then
                bestLen="${#canonKey}"
                bestKey="$canonKey"
                bestLabel="${_PROMPT_MAPPING[$k]}"
            fi
        done
    fi

    if [ -n "$bestLabel" ]; then
        if [ "$canonCurrent" = "$bestKey" ]; then
            _TEMP="$bestLabel"
        elif [ "$bestKey" = "/" ]; then
            _TEMP="${bestLabel}${canonCurrent}"
        else
            _TEMP="${bestLabel}/${canonCurrent#"$bestKey"/}"
        fi
        return 0
    fi

    +prompt:canon "$HOME"
    local homeCanon="$_TEMP"
    if [ "$canonCurrent" = "$homeCanon" ]; then
        _TEMP="~"
    elif [[ "$canonCurrent" == "$homeCanon"/* ]]; then
        _TEMP="~/${canonCurrent#"$homeCanon"/}"
    else
        _TEMP="$current"
    fi
}

function +prompt:escapeBash() { #x
    local s="$1"
    local bs='\' dollar='$' tick='`' bang='!'
    s="${s//$bs/$bs$bs}"
    s="${s//$dollar/$bs$dollar}"
    s="${s//$tick/$bs$tick}"
    s="${s//$bang/$bs$bang}"
    _TEMP="$s"
}

function +prompt:escapeZsh() { #x
    local s="$1"
    local pct='%' dollar='$' bs='\'
    s="${s//$pct/$pct$pct}"
    s="${s//$dollar/$bs$dollar}"
    _TEMP="$s"
}

function +prompt:saveMapping() { #x
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
    done < "$_PROMPT_MAPPING_FILE"

    if [ "$found" = 0 ]; then
        if [ -n "$value" ]; then
            printf '%s\n' "$key=$value" >> "$tmpfile"
        else
            rm -f "$tmpfile"
            return 2
        fi
    fi

    mv "$tmpfile" "$_PROMPT_MAPPING_FILE" || return 1
}

function +prompt:setMapping() { #x
    local path="$1" label="$2"
    if [ -z "$path" ] || [ -z "$label" ]; then
        logError "Usage: qprompt <path> <label>"
        return 1
    fi
    if [[ "$path" == *=* ]]; then
        logError "Path must not contain '='"
        return 1
    fi

    +prompt:toAbsolute "$path" || return 1
    local abs="$_TEMP"
    +prompt:toStored "$abs"
    local stored="$_TEMP"
    +prompt:canon "$abs"
    local canonNew="$_TEMP" k
    local -a stale=()

    if [[ "$_CURRENT_SHELL" = "zsh" ]]; then
        for k in "${(@k)_PROMPT_MAPPING}"; do
            if [ "$k" != "$stored" ]; then
                +prompt:canon "$k"
                if [ "$_TEMP" = "$canonNew" ]; then
                    stale+=("$k")
                fi
            fi
        done
    else
        for k in "${!_PROMPT_MAPPING[@]}"; do
            if [ "$k" != "$stored" ]; then
                +prompt:canon "$k"
                if [ "$_TEMP" = "$canonNew" ]; then
                    stale+=("$k")
                fi
            fi
        done
    fi
    for k in "${stale[@]}"; do
        +prompt:saveMapping "$k" ""
        unset "_PROMPT_MAPPING[$k]"
    done

    local existed=0 previous=""
    if [ -n "${_PROMPT_MAPPING[$stored]+x}" ]; then
        existed=1
        previous="${_PROMPT_MAPPING[$stored]}"
    fi

    +prompt:saveMapping "$stored" "$label" || return 1
    _PROMPT_MAPPING[$stored]="$label"
    if [ "$existed" = 1 ]; then
        logSuccess "Updated prompt '$stored' -> $label"
        logInfo "Previous: $previous (revert with: qprompt $stored '$previous')"
    else
        logSuccess "Added prompt '$stored' -> $label"
    fi
}

function +prompt:deleteMapping() { #x
    local path="$1"
    if [ -z "$path" ]; then
        logError "Usage: qprompt -d|--delete <path>"
        return 1
    fi
    +prompt:findKey "$path"
    local key="$_TEMP"
    if [ -z "$key" ]; then
        +prompt:listKeys
        logWarn "No prompt mapping for: $path. Available: ${_TEMP:-(none)}."
        return 1
    fi

    +prompt:saveMapping "$key" ""
    local rc=$?
    if [ "$rc" = 2 ]; then
        +prompt:listKeys
        logWarn "No prompt mapping for: $path. Available: ${_TEMP:-(none)}."
        return 1
    elif [ "$rc" != 0 ]; then
        return 1
    fi
    unset "_PROMPT_MAPPING[$key]"
    logSuccess "Deleted prompt '$key'"
}

function +prompt:update() { #x
    +prompt:resolveLabel "$PWD"
    local label="$_TEMP"
    if [[ "$_CURRENT_SHELL" = "zsh" ]]; then
        +prompt:escapeZsh "$label"
        PROMPT="${_TEMP}> "
    else
        +prompt:escapeBash "$label"
        PS1="${_TEMP}> "
    fi
}

+prompt:seedMappingFile
+prompt:loadMapping

if [[ "$_CURRENT_SHELL" = "zsh" ]]; then
    typeset -ga precmd_functions
    case " ${precmd_functions[*]} " in
        *" +prompt:update "*) ;;
        *) precmd_functions+=(+prompt:update) ;;
    esac
else
    case ";${PROMPT_COMMAND};" in
        *"+prompt:update"*) ;;
        *) PROMPT_COMMAND="+prompt:update${PROMPT_COMMAND:+; $PROMPT_COMMAND}" ;;
    esac
fi

function qprompt() { #? set path prompt labels. Usage: qprompt <path> <label> | qprompt <path> | qprompt -d <path> | qprompt -l
    if [ -z "$1" ]; then
        +prompt:printList
        logInfo "Run 'qprompt -h' for help."
        return 0
    fi

    if [ "$1" = "-h" ] || [ "$1" = "--help" ] || [ "$1" = "help" ]; then
        +prompt:printHelp
        return 0
    fi

    if [ "$1" = "-l" ] || [ "$1" = "--list" ]; then
        +prompt:printList
        return 0
    fi

    if [ "$1" = "-d" ] || [ "$1" = "--delete" ]; then
        +prompt:deleteMapping "$2"
        return $?
    fi

    if [ -n "$2" ]; then
        +prompt:setMapping "$1" "$2"
        return $?
    fi

    +prompt:resolvePath "$1"
    local target="$_TEMP"
    if [ ! -d "$target" ]; then
        logError "Not a directory: $target"
        return 1
    fi
    target="$(cd "$target" && pwd)" || return 1
    +prompt:resolveLabel "$target"
    logInfo "Prompt for ${target}: $_TEMP"
}
