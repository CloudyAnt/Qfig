#? Commands to operate json

function jsonget() { #? Usage: jsonget json targetPath, -h for more
    if [ "-h" = $1 ]; then
        logInfo "For json \e[34m{\"users\": [{\"name\": \"chai\"}]}\e[0m, you can get the 1st user's name like: \e[1mjsonget json users.0.name\e[0m.
  For json \e[34m[{\"name\": \"chai\"}]\e[0m, then the operation be like: \e[1mjsonget json 0.name\e[0m
  \e[1mWarning\e[0m that the json syntax check is poor, make sure it's correct before use"
        return 0
    fi
    [[ -z $1 || -z $2 ]] && logError "Usage: jsonget json targetPath. -h for more" && return 1

    local s
    local c
    local escaping=""
    # --- Resolve Path ---
    declare -a tp # target path sections
    declare -i tpi=1 # target path section index
    tp[1]="$"
    for (( i=0 ; i<${#2}; i++ )); do
        c=${2:$i:1}
        if [ $escaping ]; then
            s=$s$c
            escaping=""
            continue
        fi
        if [ '\' = "$c" ]; then
            continue
        fi
        if [ "." = "$c" ]; then
            if [ "" = "$s" ]; then
                logError "Invalid path: section $tpi is empty" && return 1
            else
                tpi=$((tpi + 1))
                tp[$tpi]=$s
                s=""
            fi
        else
            s=$s$c
        fi
    done
    if [ ! -z "$s" ]; then
        tpi=$((tpi + 1))
        tp[$tpi]=$s
    fi

    # --- Resolve Json ---

    local type
    # x = status of json resloving
    local x=0
    local matched=""
    declare -a cpt # current path section types. 
    # possible types be: O(object), A(array), *(others)

    declare -a cp # current path sections
    cp[1]="$"
    declare -i cpi=2 # current path section index
    local err=""
    declare -i ai=0 # current array index

    local firstC=${1:0:1}
    case $firstC in
        {)
            cpt[1]="O"
            x=0
        ;;
        \[)
            cpt[1]="A"
            x=3
            if [[ $cpi -eq $tpi || "$ai" = $tp[$tpi] ]]; then
                matched="1"
            fi
        ;;
        *)
            logError "Invalid json: unrecognized first char: $firstC" && return 1
        ;;
    esac


    function meetComma {
        if [ "O" = $cpt[$(($cpi - 1))] ]; then
            x=0
        elif [ "A" = $cpt[$(($cpi - 1))] ]; then
            x=3
            ai=$((ai + 1))
            cp[$cpi]="$ai"
            if [[ $cpi -eq $tpi || "$ai" = $tp[$tpi] ]]; then
                matched="1"
            fi
        fi
    }

    function meetObjectEnd {
        cpi=$((cpi - 1))
        if [ "O" = $cpt[$cpi] ]; then
            x=5
        else
            err="Internel logic error (E2). Met wrong type '$cpt[$cpi]'" && break
        fi
    }

    function meetArrayEnd {
        cpi=$((cpi - 1))
        if [ "A" = $cpt[$cpi] ]; then
            x=5
        else
            err="Internel logic error (E3). Met wrong type '$cpt[$cpi]'" && break
        fi
    }

    function checkMatch {
        if [[ $matched && $cpi -eq $tpi ]]; then
            if [ "O" = "$cpt[$cpi]" ]; then
                logInfo "Found Object"
            elif [ "A" = "$cpt[$cpi]" ]; then
                logInfo "Found Array"
            else
                logInfo "Found: \e[1m$s\e[0m"
            fi
            break;
        fi
    }

    for (( i=1 ; i<${#1}; i++ )); do
        c=${1:$i:1}
        
        case $x in
            0) # waiting key
                s=""
                if [ '"' = "$c" ]; then
                    x=1
                elif [ '}' = "$c" ]; then
                    meetArrayEnd
                elif [ ! ' ' = "$c" ]; then
                    err="Invalid json (00000): expecting '\"' at index $i (after path: $(joinBy . $cp)), but got '$c'" && break
                fi
            ;;
            1) # appending key 
                if [[ $escaping && ! '\' = "$c" ]]; then
                    s=$s$c
                elif [ '\' = "$c" ]; then
                    escaping="1"
                elif [ '"' = "$c" ]; then
                    cp[$cpi]=$s
                    if [[ $cpi -eq $tpi && $s = $tp[$tpi] ]]; then
                        matched="1"    
                    fi
                    x=2
                else
                    s=$s$c
                fi
            ;;
            2) # waiting colon
                if [ ':' = "$c" ]; then
                    x=3
                elif [ ! ' ' = "$c" ]; then
                    err="Invalid json (20000): expecting ':' at index $i (path: $(joinBy . $cp)), but got '$c'" && break
                fi
            ;;
            3) # waiting value
                cpt[$cpi]="*"
                s=""
                if [ '"' = "$c" ]; then
                    x=4
                elif [[ "$c" =~ '^[0-9]$' ]]; then
                    x=4101
                elif [ 't' = "$c" ]; then
                    local following=${1:$i:4}
                    if [ "ture" = "$following" ]; then
                        x=5
                    else
                        err="Invalid json (30000): (may) expecting 'true' as value of path: $(joinBy . $cp), but it's not" && break
                    fi
                elif [ 'f' = "$c" ]; then
                    local following=${1:$i:5}
                    if [ "false" = "$following" ]; then
                        x=5
                    else
                        err="Invalid json (30001): (may) expecting 'false' as value of path: $(joinBy . $cp), but it's not" && break
                    fi
                elif [ '[' = "$c" ]; then
                    cpt[$cpi]="A"
                    cpi=$((cpi + 1)) 
                    ai=0
                    cp[$cpi]="0"
                    if [[ $cpi -eq $tpi || "$ai" = $tp[$tpi] ]]; then
                        matched="1"
                    fi
                elif [ '{' = "$c" ]; then
                    x=0
                    cpt[$cpi]="O"
                    cpi=$((cpi + 1))
                elif [ ! ' ' = "$c" ]; then
                    err="Invalid json (30002): expecting '\"' at index $i (path: $(joinBy . $cp)), but got '$c'" && break
                fi
            ;;
            4) # appending string value
                if [[ $escaping && ! '\' = "$c" ]]; then
                    s=$s$c
                elif [ '\' = "$c" ]; then
                    escaping="1"
                elif [ '"' = "$c" ]; then
                    x=5
                else
                    s=$s$c
                fi
            ;;
            4101) # appending int value
                if [[ "$c" =~ '^[0-9]$' ]]; then
                    s=$c$c
                elif [ " " = "$c" ]; then
                    x=5
                elif [ "," = "$c" ]; then
                    meetComma
                elif [ "." = "$c" ]; then
                    x=4102
                else
                    err="Invalid json (41010): expecting digit at index $i (path: $(joinBy . $cp)), but got '$c'" && break
                fi
            ;;
            4202) # appending float value
                if [[ "$c" =~ '^[0-9]$' ]]; then
                    s=$c$c
                elif [ " " = "$c" ]; then
                    x=5
                elif [ "," = "$c" ]; then
                    meetComma
                else
                    err="Invalid json (42020): expecting digit at index $i (path: $(joinBy . $cp)), but got '$c'" && break
                fi
            ;;
            5) # waiting comma
                checkMatch
                if [ ',' = "$c" ]; then
                    meetComma
                elif [ '}' = "$c" ]; then
                    meetObjectEnd
                elif [ ']' = "$c" ]; then
                    meetArrayEnd
                elif [ ! ' ' = "$c" ]; then
                    err="Invalid json (50000): expecting ',' (or '}', ']) at index $i (path: $(joinBy . $cp)), but got '$c'" && break
                fi
            ;;
            *)
                err="Internal logic error (E3). Met wrong status $x" && break
            ;;
        esac
    done
    unset -f meetComma
    unset -f meetObjectEnd
    unset -f meetArrayEnd
    unset -f checkMatch

    # TODO check $s and $x
    if [ $err ]; then
        logError $err && return 1
    elif [ ! $matched ]; then
        if [ $cpi -ne 1 ]; then
            logError "Invalid json (x0000), stopped at depth: $cpi (path: $(joinBy . $cp))"
        else
            logInfo "Not found"
        fi
    fi
}