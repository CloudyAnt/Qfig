#? commands to operate colors
function rgb() { #? show rgb color(rgb values or hexadecimal color value). Usage: rgb 100 200 255; rgb 64c8ff
    local r g b hex

    # Handle RGB decimal values
    if [[ "$1" =~ ^[0-9]+$ && "$2" =~ ^[0-9]+$ && "$3" =~ ^[0-9]+$ ]]; then
        r=$1; g=$2; b=$3
        
        # Validate RGB ranges in one pass
        local validation=$(awk -v r="$r" -v g="$g" -v b="$b" '
            BEGIN {
                err = ""
                if (r < 0 || r > 255) err = err "Red(0~255) "
                if (g < 0 || g > 255) err = err "Green(0~255) " 
                if (b < 0 || b > 255) err = err "Blue(0~255)"
                print err
            }
        ')
        
        if [ -n "$validation" ]; then
            logError "${validation% } is(are) invalid !" && return 1
        fi
        hex=$(printf "%02x%02x%02x" "$r" "$g" "$b")
    # Handle hex color value
    elif [[ $1 =~ ^[0-9a-fA-F]{6}$ ]]; then
        r=$(+convertHexColorUnit2Dec ${1:0:2})
        g=$(+convertHexColorUnit2Dec ${1:2:2})
        b=$(+convertHexColorUnit2Dec ${1:4:2})
        hex=$1
    else
        logError "Please specify r, g, b values like '100 200 255' or hex color name like '64c8ff'" && return 1
    fi

    # Check terminal support
    [[ "$COLORTERM" = "truecolor" || "$COLORTERM" = "24bit" || "$OSTYPE" = "msys" ]] || \
        logSilence "This terminal may not support 24-bit color (truecolor)"

    # Display color
    printf "\e[48;2;%d;%d;%dm  \e[0m\n" "$r" "$g" "$b"

    printf "rgb: $r $g $b\n"
    printf "hex: $hex\n"
    # Convert to percentage
    local rP=$(echo "scale=4; $r / 255 * 100" | bc | sed '/\./ s/\.\{0,1\}0\{1,\}$//')
    local gP=$(echo "scale=4; $g / 255 * 100" | bc | sed '/\./ s/\.\{0,1\}0\{1,\}$//')
    local bP=$(echo "scale=4; $b / 255 * 100" | bc | sed '/\./ s/\.\{0,1\}0\{1,\}$//')
    printf "pct: $rP%% $gP%% $bP%%\n"

    # Convert to hsl & hsv
    local hsl=$(echo "$r $g $b" "hsl" | awk -f "$_QFIG_LOC/staff/rgb2hslv.awk")
    local hsv=$(echo "$r $g $b" "hsv" | awk -f "$_QFIG_LOC/staff/rgb2hslv.awk")
    printf "hsl: $hsl\n"
    printf "hsv: $hsv\n"
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
              printf "\e[0m\n"
              return 0;;
            s) show=1;;
            v) value=1;;
            \?) logError "Invalid option: -$OPTARG"; return 1;;
        esac
    done
    shift "$((OPTIND - 1))"

    local r=$1 g=$2 b=$3

    # Validate RGB values
    local validation=$(awk -v r="$r" -v g="$g" -v b="$b" '
        BEGIN {
            err = ""
            if (!(r ~ /^[0-9]+$/ && r >= 0 && r <= 255)) err = err "Red(0~255) "
            if (!(g ~ /^[0-9]+$/ && g >= 0 && g <= 255)) err = err "Green(0~255) "
            if (!(b ~ /^[0-9]+$/ && b >= 0 && b <= 255)) err = err "Blue(0~255)"
            print err
        }
    ')

    if [ -n "$validation" ]; then
        logError "${validation% } is(are) invalid !" && return 1
    fi

    # Check terminal support if showing color
    if [ "$show" ]; then
        [[ "$COLORTERM" = "truecolor" || "$COLORTERM" = "24bit" ]] && : || logSilence "This terminal may not support 24-bit color (truecolor)"
    fi

    # Convert and output
    local type=${value:+hsv}
    type=${type:-hsl}
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
              printf "\e[0m\n"
              return 0;;
            s) show=1;;
            v) value=1;;
            \?) logError "Invalid option: -$OPTARG"; return 1;;
        esac
    done
    shift "$((OPTIND - 1))"

    local h=$1 s=$2 lv=$3

    # Validate HSL/HSV values
    local validation=$(awk -v h="$h" -v s="$s" -v lv="$lv" '
        BEGIN {
            err = ""
            if (!(h ~ /^[0-9]+(\.[0-9]+)?$/ && h >= 0 && h <= 360)) err = err "Hue(0~360) "
            if (!(s ~ /^[0-9]+(\.[0-9]+)?$/ && s >= 0 && s <= 100)) err = err "Saturation(0~100) "
            if (!(lv ~ /^[0-9]+(\.[0-9]+)?$/ && lv >= 0 && lv <= 100)) err = err "Lightness/Value(0~100)"
            print err
        }
    ')

    if [ -n "$validation" ]; then
        logError "${validation% } is(are) invalid !" && return 1
    fi

    # Check terminal support if showing color
    if [ "$show" ]; then
        [[ "$COLORTERM" = "truecolor" || "$COLORTERM" = "24bit" ]] && : || logSilence "This terminal may not support 24-bit color (truecolor)"
    fi

    local type=${value:+hsv}
    type=${type:-hsl}

    # Convert HSL/HSV to RGB
    local rgb=$(echo "$h $s $lv $type" | awk -f "$_QFIG_LOC/staff/hslv2rgb.awk")

    # Output result
    if [ "$show" ]; then
        toArray $rgb && declare -a rgb1=("${_TEMP[@]}")
        local ab=$(getArrayBase)
        local R=${rgb1[$ab]} G=${rgb1[$((ab + 1))]} B=${rgb1[$((ab + 2))]}
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
