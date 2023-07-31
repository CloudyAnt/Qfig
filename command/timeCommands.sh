#? Commands about time

function exunixt() { #? explain an unix timestamp, -m to indicate a millisenconds
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

    declare -i curStamp d h m s
    d=0;h=0;m=0;s=0
    local str
    curStamp=$(date +%s)
    echo "Current stamp: $curStamp"
    if [ ! "$cur" ]; then
        if [ $curStamp -ge $stamp ]; then
            s=$((curStamp - stamp))
            str="Ago"
        else
            s=$((stamp - curStamp))
            str="From now"
        fi

        if [ $s -ge 60 ]; then
            m=$(($s / 60))
            s=$(($s % 60))
        fi
        str="$s seconds  $str"
        if [ $m -ge 60 ]; then
            h=$(($m / 60))
            m=$(($m % 60))
        fi
        str="$m minutes  $str"
        if [ $h -ge 24 ]; then
            d=$(($h / 24))
            h=$(($h % 24))
        fi
        str="$d days  $h house  $str"

        echo $str
    fi
}