#? Commands to operate json.
#? No 3rd program needed.

function jsonget() { #? get value by path. Usage: jsonget $json $targetPath, -h for more
    if [ "-h" = $1 ]; then
        logInfo "For json \e[34m{\"users\": [{\"name\": \"chai\"}]}\e[0m, you can get the 1st user's name like: \e[1mjsonget json users.0.name\e[0m
  For json \e[34m[{\"name\": \"chai\"}]\e[0m, then the operation be like: \e[1mjsonget json 0.name\e[0m
  Use '\.' to escape .
  \e[1mNote\e[0m that the json syntax check will stop after target found"
        return 0
    fi
    [[ -z $1 || -z $2 ]] && logError "Usage: jsonget json targetPath. -h for more" && return 1
    # --- CHECK options ---
	declare -i arrayBase
	[[ -o ksharrays ]] && arrayBase=0 || arrayBase=1 # if KSH_ARRAYS option set, array based on 0, and '{}' are required to access index

    local s
    local c
    local escaping=""
    # --- RESOLVE path ---
    declare -a tp # target path sections
    declare -i tpi=$arrayBase # target path section index
    tp[$arrayBase]="$"
    local i
    for (( i=0; i<${#2}; i++ )); do
        c=${2:$i:1}
        if [ $escaping ]; then
            s=$s$c
            escaping=""
            continue
        fi
        if [ '\' = "$c" ]; then
            escaping=1
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
    if [ $escaping ]; then
        logError "Invalid path: '\' was used to escape '.' or '\', do you mean '\ \b\' (double slashes) at index $((i - 1)) ?" && return 1
    fi
    if [ ! -z "$s" ]; then
        tpi=$((tpi + 1))
        tp[$tpi]=$s
    fi

    # --- RESOLVE json ---

    local type
    # x = status of json resloving
    local x=0
    local matched=""
    local found=""
    declare -a cpt # current path section types. 
    # possible types be: O(object), A(array), S(string), I(integer), F(float), TRUE, FALSE, NULL

    declare -a cp # current path sections
    declare -a cpm # current path matches
    cp[$arrayBase]="$"
    cpm[$arrayBase]=1
    declare -i cpi=$((arrayBase + 1)) # current path section index
    local err=""
    declare -i ai=0 # current array index
    declare -i fc=0 # current float fractional part digits count
    local finding=1

    local firstC=${1:0:1}
    if [ '!' = $firstC ]; then
        finding=""
        firstC=${1:1:1}
        i=2
    else
        i=1
    fi
    case $firstC in
        {)
            cpt[$arrayBase]="O"
            x=0
        ;;
        \[)
            cpt[$arrayBase]="A"
            x=3
            if [[ "$ai" = ${tp[$cpi]} ]]; then
                cpm[$cpi]=4
            else
                cpm[$cpi]=-4
            fi
        ;;
        *)
            logError "Invalid json: unrecognized first char: $firstC" && return 1
        ;;
    esac

    function concatCP {
        concat -.-1-$cpi $cp
    }

    function meetComma {
        local prevType=${cpt[$(($cpi - 1))]}
        if [ "O" = $prevType ]; then
            x=0
        elif [ "A" = $prevType ]; then
            x=3
            ai=$((ai + 1))
            cp[$cpi]="$ai"
            if [[ ${cpm[$((cpi - 1))]} -ge 0 && "$ai" = ${tp[$cpi]} ]]; then
                cpm[$cpi]=3
            else
                cpm[$cpi]=-3
            fi
        else
            err="Internal login error (E4). Unexpected previous path type $prevType"
        fi
    }

    function meetObjectEnd {
        preCpi=$((cpi - 1))
        if [ "O" = ${cpt[$preCpi]} ]; then
            cpi=$((cpi - 1))
            x=5
        else
            err="Invalid json (x0002): not expecting '}' at index $i (path: $(concatCP))" && break
        fi
    }

    function meetArrayEnd {
        preCpi=$((cpi - 1))
        if [ "A" = ${cpt[$preCpi]} ]; then
            if [ "" = $s ]; then
                if [ $ai -gt 0 ]; then
                    err="Invalid json (x0004): not expecting ']' at index $i (path: $(concatCP))" && break
                else
                    cpm[$cpi]=-51
                fi
            else
                cp[$cpi]="$ai"
                if [[ ${cpm[$((cpi - 1))]} -ge 0 && "$ai" = ${tp[$cpi]} ]]; then
                    cpm[$cpi]=5
                    checkMatch
                else
                    cpm[$cpi]=-5
                fi
            fi
            cpi=$((cpi - 1))
            x=5
        else
            err="Invalid json (x0003): not expecting ']' at index $i (path: $(concatCP))" && break
        fi
    }

    function checkMatch {
        if [[ finding && ${cpm[$cpi]} && ${cpm[$cpi]} -ge 0 && $cpi -eq $tpi ]]; then
            found=1
            case ${cpt[$cpi]} in
		        O)
                    echo "\e[34mO:\e[0mObject"
                ;;
                A)
                    echo "\e[34mA:\e[0mArray"
                ;;
                S|I|F)
                    echo "\e[34m${cpt[$cpi]}:\e[0m$s"
                ;;
                TRUE|FALSE|NULL)
                    echo "\e[34m${cpt[$cpi]}\e[0m"
                ;;
                *)
                    err="Internal logic error (E5). Unexpected type ${cpt[$cpi]}"
                ;;
            esac
            break;
        fi
    }

    for (( ; i<${#1}; i++)); do
        c=${1:$i:1}
        
        case $x in
            0) # waiting key
                s=""
                if [ '"' = "$c" ]; then
                    x=1
                elif [ '}' = "$c" ]; then
                    meetObjectEnd
                elif ! [[ ' ' = "$c" || $'\t' = "$c" || $'\n' = "$c" ]]; then
                    err="Invalid json (00000): expecting '\"' at index $i (after path: $(concatCP)), but got '$c'" && break
                fi
            ;;
            1) # appending key 
                if [ '"' = "$c" ]; then
                    if [ $escaping ]; then
                        err="Invalid json (40001): string ended by '\' at index index $i (path: $(concatCP))" && break
                    fi
                    cp[$cpi]=$s
                    if [[ ${cpm[$((cpi - 1))]} -ge 0 && $s = ${tp[$cpi]} ]]; then
                        cpm[$cpi]=6
                    else
                        cpm[$cpi]=-6
                    fi
                    x=2
                elif [[ $escaping ]]; then
                    s=$s$c
                    escaping=""
                elif [ '\' = "$c" ]; then
                    escaping="1"
                else
                    s=$s$c
                fi
            ;;
            2) # waiting colon
                if [ ':' = "$c" ]; then
                    x=3
                elif ! [[ ' ' = "$c" || $'\t' = "$c" || $'\n' = "$c" ]]; then
                    err="Invalid json (20000): expecting ':' at index $i (path: $(concatCP)), but got '$c'" && break
                fi
            ;;
            3) # waiting value
                s=""
                cpt[$cpi]="?"
                if [ '"' = "$c" ]; then
                    x=4
                    cpt[$cpi]="S"
                elif [[ "$c" =~ '^[0-9]$' ]]; then
                    x=41
                    fc=0
                    s=$s$c
                    cpt[$cpi]="I"
                elif [ 't' = "$c" ]; then
                    local following=${1:$i:4}
                    if [ "true" = "$following" ]; then
                        s=$following
                        x=5
                        i=$((i + 3)) # there is a i++
                        cpt[$cpi]="TRUE"
                    else
                        err="Invalid json (30000): (may) expecting 'true' as value of path: $(concatCP), but it's '$following'" && break
                    fi
                elif [ 'f' = "$c" ]; then
                    local following=${1:$i:5}
                    if [ "false" = "$following" ]; then
                        s=$following
                        x=5
                        i=$((i + 4)) # there is a i++
                        cpt[$cpi]="FALSE"
                    else
                        err="Invalid json (30001): (may) expecting 'false' as value of path: $(concatCP), but it's '$following'" && break
                    fi
                elif [ 'n' = "$c" ]; then
                    local following=${1:$i:4}
                    if [ "null" = "$following" ]; then
                        s=$following
                        x=5
                        i=$((i + 3)) # there is a i++
                        cpt[$cpi]="NULL"
                    else
                        err="Invalid json (30003): (may) expecting 'null' as value of path: $(concatCP), but it's '$following'" && break
                    fi
                elif [ '[' = "$c" ]; then
                    cpt[$cpi]="A"
                    cpi=$((cpi + 1)) 
                    ai=0
                    cp[$cpi]="0"
                    if [[ ${cpm[$((cpi - 1))]} -ge 0 && "$ai" = ${tp[$cpi]} ]]; then
                        cpm[$cpi]=2
                    else
                        cpm[$cpi]=-2
                    fi
                elif [ '{' = "$c" ]; then
                    x=0
                    cpt[$cpi]="O"
                    cpi=$((cpi + 1))
                elif [ ']' = "$c" ]; then
                    meetArrayEnd
                elif ! [[ ' ' = "$c" || $'\t' = "$c" || $'\n' = "$c" ]]; then
                    err="Invalid json (30002): expecting '\"' at index $i (path: $(concatCP)), but got '$c'" && break
                fi
            ;;
            4) # appending string value
                if [ '"' = "$c" ]; then
                    if [ $escaping ]; then
                        err="Invalid json (40001): string ended by '\' at index index $i (path: $(concatCP))" && break
                    fi
                    x=5
                elif [[ $escaping ]]; then
                    s=$s$c
                    escaping=""
                elif [ '\' = "$c" ]; then
                    escaping=1
                else
                    s=$s$c
                fi
            ;;
            41) # appending int value
                if [[ "$c" =~ '^[0-9]$' ]]; then
                    s=$s$c
                elif [[ ' ' = "$c" || $'\t' = "$c" || $'\n' = "$c" ]]; then
                    x=5
                elif [ "," = "$c" ]; then
                    meetComma
                    checkMatch
                elif [ "." = "$c" ]; then
                    x=42
                    s=$s$c
                    cpt[$cpi]="F"
                elif [ '}' = "$c" ]; then
                    checkMatch
                    meetObjectEnd
                elif [ ']' = "$c" ]; then
                    meetArrayEnd
                else
                    err="Invalid json (41001): expecting digit at index $i (path: $(concatCP)), but got '$c'" && break
                fi
            ;;
            42) # appending float value
                if [[ "$c" =~ '^[0-9]$' ]]; then
                    s=$s$c
                    fc=$((fc + 1))
                elif [[ ' ' = "$c" || $'\t' = "$c" || $'\n' = "$c" ]]; then
                    x=5
                elif [ "," = "$c" ]; then
                    [ $fc -eq 0 ] && err="Invalid json (42002): expecting digit (fractional part) at index $i (path: $(concatCP)), but got '$c'" && break
                    meetComma
                    checkMatch
                elif [ '}' = "$c" ]; then
                    [ $fc -eq 0 ] && err="Invalid json (42003): expecting digit (fractional part) at index $i (path: $(concatCP)), but got '$c'" && break
                    checkMatch
                    meetObjectEnd
                elif [ ']' = "$c" ]; then
                    [ $fc -eq 0 ] && err="Invalid json (42004): expecting digit (fractional part) at index $i (path: $(concatCP)), but got '$c'" && break
                    meetArrayEnd
                else
                    err="Invalid json (42001): expecting digit at index $i (path: $(concatCP)), but got '$c'" && break
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
                elif ! [[ ' ' = "$c" || $'\t' = "$c" || $'\n' = "$c" ]]; then
                    err="Invalid json (50000): expecting ',' (or '}', ']) at index $i (path: $(concatCP)), but got '$c'" && break
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
    unset -f concatCP

    if [ $err ]; then
        logError $err && return 1
    elif [ "${cpm[$tpi]}" -gt 0 ]; then
        if [ ! $found ]; then
            logError "Invalid json (x0005), matched but stopped (value resolvation not finished) at depth: $(($tpi - $arrayBase)) (path: $(concat -.-1-$tpi $tp))" && return 1
        else
            # Found
        fi
    else
        if [ $cpi -ne $arrayBase ]; then
            logError "Invalid json (x0000), stopped at depth: $(($tpi - $arrayBase)) (path: $(concat -.-1-$cpi $cp))" && return 1
        else
            echo "\e[1mNot found\e[0m"
        fi
    fi
}

function jsoncheck() { #? json checking. Usage: jsoncheck $json
    [ -z $1 ] && return
    local res
    res=$(jsonget "!$1" "-")
    if [ 0 -ne $? ]; then
        echo $res >&2 && return 1
    fi
}