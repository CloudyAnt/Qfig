#? Commands about time

function isLeapYear() { #? judge whether a year (current year if no specify) if leap year
    declare -i year
    if [ -z $1 ]; then
        year=$(date +%Y)
    elif ! [[ $1 =~ [0-9]+ ]]; then
        logError "Not a valid year!" && return 1
    else
        year=$1
    fi

    if [ $((year % 4)) -eq 0 ]; then
        if [ $((year % 100)) -eq 0 ]; then
            if [ $((year % 400)) -eq 0 ]; then
                return 0
            else
                return 1
            fi
        else
            return 0
        fi
    else
        return 1
    fi
}

function eut() { #? epoch unix timestamp, -m to indicate a millisenconds
    local millis
    if [ "-m" = "$1" ]; then
        millis=1
        shift 1
    fi
    local cur
    declare -i stamp
    if [ -z "$1" ]; then
        stamp=$(date +%s)
        cur=1
    else
        if [[ ! $1 =~ [0-9]+ ]]; then
            logError "Not an unix timestamp!" && return 1
        fi
        [ $millis ] && stamp=$(($1 / 1000)) || stamp=$1
    fi

    declare -i curStamp y d h m s
    y=0;d=0;h=0;m=0;s=0
    local str ago
    curStamp=$(date +%s)
    if [ "$cur" ]; then
        echo "Current stamp: $curStamp"
        date +"LOCAL: %Y-%m-%d %H:%M:%S %z %Z"
        date -u +'  GMT: %Y-%m-%d %H:%M:%S'
        return
    fi

    # calculate relative
    if [ $curStamp -ge $stamp ]; then
        s=$((curStamp - stamp))
        str="Ago"
        ago=1
    else
        s=$((stamp - curStamp))
        str="From now"
    fi

    if [ $s -ge 60 ]; then
        m=$(($s / 60))
        s=$(($s % 60))
    fi
    if [ $m -ge 60 ]; then
        h=$(($m / 60))
        m=$(($m % 60))
    fi
    if [ $h -ge 24 ]; then
        d=$(($h / 24))
        h=$(($h % 24))
    fi
    if [ $d -ge 365 ]; then
        y=$(($d / 365))
        d=$(($d % 365))
    fi
    str="$y years $d days $h hours $m minutes $s seconds $str"
    echo $str

    if [ $_IS_BSD ]; then
        date -r $stamp +"LOCAL: %Y-%m-%d %H:%M:%S %z %Z"
        date -u -r $stamp +'  GMT: %Y-%m-%d %H:%M:%S'
    else
        # GNU
        date -d @$stamp +"LOCAL: %Y-%m-%d %H:%M:%S %z %Z"
        date -u -d @$stamp +'  GMT: %Y-%m-%d %H:%M:%S'
    fi
}