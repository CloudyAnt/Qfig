#? Commands about time

function isLeapYear() { #? judge whether it's a leap year (default this year)
    declare -i year
    if [ -z "$1" ]; then
        year=$(date +%Y)
    elif ! [[ $1 =~ ^[0-9]+$ ]]; then
        logError "Not a valid year!" && return 1
    else
        year=$1
    fi

    # A year is a leap year if:
    # - Divisible by 4 AND
    # - NOT divisible by 100 OR divisible by 400
    [ $((year % 4)) -eq 0 ] && { [ $((year % 100)) -ne 0 ] || [ $((year % 400)) -eq 0 ]; }
}

function eut() { #? describe an epoch unix timestamp (default now), -m to indicate a milliseconds
    local millis
    if [ "-m" = "$1" ]; then
        millis=1
        shift 1
    fi

    declare -i stamp
    if [ -z "$1" ]; then
        stamp=$(date +%s)
        # Show current timestamp info and return early
        echo "Current stamp: $stamp"
        date +"LOCAL: %Y-%m-%d %H:%M:%S %z %Z"
        date -u +'  GMT: %Y-%m-%d %H:%M:%S'
        return
    fi

    if [[ ! $1 =~ [0-9]+ ]]; then
        logError "Not an unix timestamp!" && return 1
    fi
    [ $millis ] && stamp=$(($1 / 1000)) || stamp=$1

    declare -i curStamp=$(date +%s)
    declare -i y=0 d=0 h=0 m=0 s=0
    local str

    # Calculate relative time
    if [ $curStamp -eq $stamp ]; then
        echo "Now"
    else
        # Get difference in seconds and direction
        if [ $curStamp -ge $stamp ]; then
            s=$((curStamp - stamp))
            str=" before now ($curStamp)"
        else
            s=$((stamp - curStamp))
            str=" from now ($curStamp)"
        fi

        # Convert to larger units
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

        # Build output string
        local parts=()
        [ $y -ne 0 ] && parts+=("$y years")
        [ $d -ne 0 ] && parts+=("$d days") 
        [ $h -ne 0 ] && parts+=("$h hours")
        [ $m -ne 0 ] && parts+=("$m minutes")
        [ $s -ne 0 ] && parts+=("$s seconds")
        
        # Join parts with spaces
        local IFS=" "
        echo "${parts[*]}$str"
    fi

    # Show timestamp in local and GMT
    if [ $_IS_BSD ]; then
        date -r $stamp +"LOCAL: %Y-%m-%d %H:%M:%S %z %Z"
        date -u -r $stamp +'  GMT: %Y-%m-%d %H:%M:%S'
    else
        # GNU
        date -d @$stamp +"LOCAL: %Y-%m-%d %H:%M:%S %z %Z"
        date -u -d @$stamp +'  GMT: %Y-%m-%d %H:%M:%S'
    fi
}
