#? commands to operate colors
function rgb() { #? show rgb color(rgb values or hexadecimal color value). Usage: rgb 100 200 255; rgb 64c8ff
    local r g b
    if [[ "$1" =~ ^[0-9]+$ && "$2" =~ ^[0-9]+$ && "$3" =~ ^[0-9]+$ ]]; then
        r=$1;g=$2;b=$3
        [[ $r -lt 0 || $r -gt 255 ]] && errComp+="Red(0~255)"
        [[ $g -lt 0 || $g -gt 255 ]] && errComp+="Green(0~255)"
        [[ $b -lt 0 || $b -gt 255 ]] && errComp+="Blue(0~255)"
        if [ ${#errComp} -gt 0 ]; then
            local err=$(concat '-, -' $errComp)
            logError $err" is(are) invalid !" && return 1
        fi
    elif [[ $1 =~ ^[0-9a-fA-F]{6}$ ]]; then
        r=$(+convertHexColorUnit2Dec ${1:0:2})
        g=$(+convertHexColorUnit2Dec ${1:2:2})
        b=$(+convertHexColorUnit2Dec ${1:4:2})
    else
        logError "Please specify r, g, b values like '100 200 255' or hex color name like '64c8ff'" && return 1
    fi

    [[ "$COLORTERM" = "truecolor" || "$COLORTERM" = "24bit" || "$OSTYPE" = "msys" ]] && : || logSilence "This terminal may not support 24-bit color (truecolor)"
    printf "\e[48;2;$r;$g;${b}m  \e[0m\n"
}

function rgb2hslv() { #? convert RGB(integers) to HSL(floats) or HSV(floats). -s to show the rgb color
    local show value
    OPTIND=1
    while getopts "hsv" opt; do
        case $opt in
            h)
              logInfo "Usage: rgb2hslv \$r \$g \$b.\n  \nFlags:\n"
              printf "    %-5s%s\n" "h" "Print this help message"
              printf "    %-5s%s\n" "s" "Show the color in a 24-bit color terminal"
              printf "    %-5s%s\n" "v" "Specify the output to HSV"
              printf "\e[0m"
              echo ""
              return 0;;
            s) show=1;;
            v) value=1;;
            \?) logError "Invalid option: -$OPTARG"; return 1;;
        esac
    done
    shift "$((OPTIND - 1))"
    if [ "$show" ]; then
        [[ "$COLORTERM" = "truecolor" || "$COLORTERM" = "24bit" ]] && : || logSilence "This terminal may not support 24-bit color (truecolor)"
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

    local type
    if [ $value ]; then
        type="hsv"
    else
        type="hsl"
    fi
    echo "$r $g $b $type" | awk -f "$_QFIG_LOC/staff/rgb2hslv.awk"
    [ $show ] && printf " \e[48;2;$r;$g;${b}m  \e[0m\n" || printf "\n"
}

function hslv2rgb() { #? convert HSL(floats) or HSV(floats) to RGB(integers). -s to show the rgb color
    local show value
    OPTIND=1
    while getopts "hsv" opt; do
        case $opt in
            h)
              logInfo "Usage: hslv2rgb \$hue \$saturation \$lightness/\$value.\n  \nFlags:\n"
              printf "    %-5s%s\n" "h" "Print this help message"
              printf "    %-5s%s\n" "s" "Show the color in a 24-bit color terminal"
              printf "    %-5s%s\n" "v" "Specify the input as HSV"
              printf "\e[0m"
              echo ""
              return 0;;
            s) show=1;;
            v) value=1;;
            \?) logError "Invalid option: -$OPTARG"; return 1;;
        esac
    done
    shift "$((OPTIND - 1))"
    if [ "$show" ]; then
        [[ "$COLORTERM" = "truecolor" || "$COLORTERM" = "24bit" ]] && : || logSilence "This terminal may not support 24-bit color (truecolor)"
    fi

    local h s lv h_ s_ lv_
    h=$1;s=$2;lv=$3
    declare -a errComp
    h_=$(echo $h | awk '{if((/^[0-9]+$/ || /^[0-9]+\.[0-9]+$/) && $1 >= 0 && $1 <= 360){print 0}else{print 1}}')
    s_=$(echo $s | awk '{if((/^[0-9]+$/ || /^[0-9]+\.[0-9]+$/) && $1 >= 0 && $1 <= 100){print 0}else{print 1}}')
    lv_=$(echo $lv | awk '{if((/^[0-9]+$/ || /^[0-9]+\.[0-9]+$/) && $1 >= 0 && $1 <= 100){print 0}else{print 1}}')
    [ $h_ -ne 0 ] && errComp+="Hue(0~360)"
    [ $s_ -ne 0 ] && errComp+="Saturation(0~100)"
    [ $lv_ -ne 0 ] && errComp+="Lightness/Value(0~100)"

    if [ ${#errComp} -gt 0 ]; then
        local err=$(concat '-, -' $errComp)
        logError $err" is(are) invalid !" && return 1
    fi

    local type rgb
    if [ $value ]; then
        type="hsv"
    else
        type="hsl"
    fi
    rgb=$(echo "$h $s $lv $type" | awk -f "$_QFIG_LOC/staff/hslv2rgb.awk")
    if [ $show ]; then
        toArray $rgb && declare -a rgb1=("${_TEMP[@]}")
        ab=$(getArrayBase)
        local R=${rgb1[$ab]};G=${rgb1[$((ab + 1))]};B=${rgb1[$((ab + 2))]}
        printf "$rgb \e[48;2;$R;$G;${B}m  \e[0m\n"
    else
        echo "$rgb"
    fi
}

function +convertHexColorUnit2Dec() { #x
    local d1 d2
    d2=$(+convertSingleHex2Dec ${1:0:1})
    d1=$(+convertSingleHex2Dec ${1:1:1})
    echo $(($d2 * 16 + $d1))
}

function +convertSingleHex2Dec() { #x
    [[ $1 = 'a' || $1 = 'A' ]] && echo 10 && return
    [[ $1 = 'b' || $1 = 'B' ]] && echo 11 && return
    [[ $1 = 'c' || $1 = 'C' ]] && echo 12 && return
    [[ $1 = 'd' || $1 = 'D' ]] && echo 13 && return
    [[ $1 = 'e' || $1 = 'E' ]] && echo 14 && return
    [[ $1 = 'f' || $1 = 'F' ]] && echo 15 && return
    echo $1
}
