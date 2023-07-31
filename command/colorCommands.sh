#? commands to operate colors

function rgb2hsl() { #? convert RGB(integers) to HSL(integers). -s to show the rgb color
    local show
    if [ "-s" = "$1" ]; then
        show=1
        shift 1
        [[ "$COLORTERM" = "truecolor" || "$COLORTERM" = "24bit" ]] && logInfo "This terminal may not support 24-bit color (truecolor) !" || :
    fi
    local r=$1
    local g=$2
    local b=$3
    declare -a errComp
    [[ ! "$r" =~ ^[0-9]+$ || $r -lt 0 || $r -gt 255 ]] && errComp+="Red(0~255)"
    [[ ! "$g" =~ ^[0-9]+$ || $g -lt 0 || $g -gt 255 ]] && errComp+="Green(0~255)"
    [[ ! "$b" =~ ^[0-9]+$ || $b -lt 0 || $b -gt 255 ]] && errComp+="Blue(0~255)"

    if [ ${#errComp} -gt 0 ]; then
        local err=$(concat '-, -' $errComp)
        logError $err" is(are) invalid !" && return 1
    fi

    # in zsh, you just use: $((r / 255.)), here is for the compatibility
    local rr=$(echo "$r 255" | awk '{printf "%.3f\n", $1/$2}')
    local gg=$(echo "$g 255" | awk '{printf "%.3f\n", $1/$2}')
    local bb=$(echo "$b 255" | awk '{printf "%.3f\n", $1/$2}')

    local max=$rr
    local min=$rr
    local maxC="R"
    [ $(echo "$gg $max" | awk '{print ($1 > $2)}') -eq 1 ] && max=$gg && maxC="G"
    [ $(echo "$bb $max" | awk '{print ($1 > $2)}') -eq 1 ] && max=$bb && maxC="B"
    [ $(echo "$gg $min" | awk '{print ($1 < $2)}') -eq 1 ] && min=$gg
    [ $(echo "$bb $min" | awk '{print ($1 < $2)}') -eq 1 ] && min=$bb

    local L H S
    L=$(echo "$max $min" | awk '{printf "%.3f\n", ($1+$2)/2}')
    if [ $(echo "$min $max" | awk '{print ($1 == $2)}') -eq 1 ]; then
        H=0
        S=0
    else
        if [ $(echo "$L" | awk '{print ($1 <= 0.5)}') -eq 1 ]; then
            S=$(echo "$max $min" | awk '{printf "%.3f\n", ($1-$2)/($1+$2)}')
        else
            S=$(echo "$max $min" | awk '{printf "%.3f\n", ($1-$2)/(2.0-$1-$2)}')
        fi

        if [ $maxC = "R" ]; then
            H=$(echo "$gg $bb $max $min" | awk '{printf "%.3f\n", ($1-$2)/($3-$4)}')
        elif [ $maxC = "G" ]; then
            H=$(echo "$bb $rr $max $min" | awk '{printf "%.3f\n", 2.0+($1-$2)/($3-$4)}')
        else
            H=$(echo "$rr $gg $max $min" | awk '{printf "%.3f\n", 4.0+($1-$2)/($3-$4)}')
        fi

        H=$(echo "$H" | awk '{h=($1 * 60); if (h < 0) {h += 360}; printf "%.0f\n", h}')
    fi

    S=$(echo $S | awk '{print $1*100}')
    L=$(echo $L | awk '{print $1*100}')
    [ $show ] && printf "$H $S $L \e[48;2;$r;$g;${b}m  \e[0m\n" || echo "$H $S $L"
}

function hsl2rgb() { #? convert HSL(integers) to RGB(integers). -s to show the rgb color
    local show
    if [ "-s" = "$1" ]; then
        show=1
        shift 1
        [[ "$COLORTERM" = "truecolor" || "$COLORTERM" = "24bit" ]] && logInfo "This terminal may not support 24-bit color (truecolor) !" || :
    fi
    local h=$1
    local s=$2
    local l=$3
    declare -a errComp
    [[ ! "$h" =~ ^[0-9]+$ || $h -lt 0 || $h -gt 360 ]] && errComp+="Hue(0~360)"
    [[ ! "$s" =~ ^[0-9]+$ || $s -lt 0 || $s -gt 100 ]] && errComp+="Saturation(0~100)"
    [[ ! "$l" =~ ^[0-9]+$ || $l -lt 0 || $l -gt 100 ]] && errComp+="Lightness(0~100)"

    if [ ${#errComp} -gt 0 ]; then
        local err=$(concat '-, -' $errComp)
        logError $err" is(are) invalid !" && return 1
    fi

    local _s=$s
    s=$(echo $s | awk '{print $1/100}')
    l=$(echo $l | awk '{print $1/100}')
    if [ $_s -eq 0 ]; then
        local G=$(echo "$l" | awk '{printf "%.0f\n", $1*255}')
        echo "$G $G $G" && return
    fi

    local temp1 temp2 hue
    temp2=$(echo "$l $s" | awk '{if ($1 < 0.5) {print $1*(1+$2)} else {print $1+$2-($1*$2)}}')
    temp1=$(echo "$l $temp2" | awk '{print 2*$1-$2}')
    hue=$(echo "$h" | awk '{print $1/60}')

    local awkPattern="{t=\$1+\$2;if (t < 0) {t += 6} else if (t > 6) {t -= 6}; if (t < 1) {
        t=$temp1+($temp2-($temp1))*t
    } else if (t >= 1 && t < 3) {
        t=$temp2
    } else if (t >= 3 && t < 4) {
        t=$temp1+($temp2-($temp1))*(4-t)
    } else {
        t=$temp1
    }; t*=255; printf \"%.0f\",t}"

    local R G B
    R=$(echo "$hue 2" | awk "$awkPattern")
    G=$(echo "$hue 0" | awk "$awkPattern")
    B=$(echo "$hue -2" | awk "$awkPattern")
    [ $show ] && printf "$R $G $B \e[48;2;$R;$G;${B}m  \e[0m\n" || echo "$R $G $B"
}
