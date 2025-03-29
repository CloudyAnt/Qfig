#? commands to operate colors

function rgb() { #? show rgb color(rgb values or hexadecimal color value). Usage: rgb 100 200 255; rgb 64c8ff;
    local r g b hex
    local noHsl noHsv noPct
    OPTIND=1
    while getopts "hlvp" opt; do
        case $opt in
            h)
              logInfo "Usage: rgb \$red \$green \$blue."
              logInfo "Usage: rgb \$hexadecimal."
              return 0;;
            l) noHsl=1;;
            v) noHsv=1;;
            p) noPct=1;;
            \?) logError "Invalid option: -$OPTARG"; return 1;;
        esac
    done
    shift "$((OPTIND - 1))"

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
        hex=$1
        r=$(+convertHexColorUnit2Dec ${hex:0:2})
        g=$(+convertHexColorUnit2Dec ${hex:2:2})
        b=$(+convertHexColorUnit2Dec ${hex:4:2})
    # Handle short hex color value
    elif [[ $1 =~ ^[0-9a-fA-F]{3}$ ]]; then
        r=$(+convertHexColorUnit2Dec "${1:0:1}${1:0:1}")
        g=$(+convertHexColorUnit2Dec "${1:1:1}${1:1:1}")
        b=$(+convertHexColorUnit2Dec "${1:2:1}${1:2:1}")
        hex=$(printf "%02x%02x%02x" "$r" "$g" "$b")
    else
        logError "Invalid input ! Valid input examples: 100 200 255; 64c8ff; 6cf" && return 1
    fi

    # Check terminal support
    [[ "$COLORTERM" = "truecolor" || "$COLORTERM" = "24bit" || "$OSTYPE" = "msys" ]] || \
        logSilence "This terminal may not support 24-bit color (truecolor)"

    # Display color
    local cs="\\e[48;2;$r;$g;${b}m \\e[0m "

    printf "${cs}rgb: $r $g $b\n"
    printf "${cs}hex: #$hex\n"

    # Convert to percentage
    if [ -z "$noPct" ]; then
        local rP=$(echo "scale=4; $r / 255 * 100" | bc | sed '/\./ s/\.\{0,1\}0\{1,\}$//')
        local gP=$(echo "scale=4; $g / 255 * 100" | bc | sed '/\./ s/\.\{0,1\}0\{1,\}$//')
        local bP=$(echo "scale=4; $b / 255 * 100" | bc | sed '/\./ s/\.\{0,1\}0\{1,\}$//')
        printf "${cs}pct: $rP%% $gP%% $bP%%\n"
    fi

    # Convert to hsl & hsv
    if [ -z "$noHsl" ]; then
        local hsl=$(echo "$r $g $b" "hsl" | awk -f "$_QFIG_LOC/staff/rgb2hslv.awk")
        printf "${cs}hsl: $hsl\n"
    fi
    if [ -z "$noHsv" ]; then
        local hsv=$(echo "$r $g $b" "hsv" | awk -f "$_QFIG_LOC/staff/rgb2hslv.awk")
        printf "${cs}hsv: $hsv\n"
    fi
}


function +convertHslv2Rgb() { #x
    local value
    OPTIND=1
    while getopts "v" opt; do
        case $opt in
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
    toArray $rgb && declare -a rgb1=("${_TEMP[@]}")
    local ab=$(getArrayBase)
    local R=${rgb1[$ab]} G=${rgb1[$((ab + 1))]} B=${rgb1[$((ab + 2))]}
    if [ "$type" = "hsl" ]; then
        rgb -l $R $G $B
    else
        rgb -v $R $G $B
    fi
}
function rgbPct() { #? convert RGB in percentage to RGB in decimal. Usage: rgbPct 39.21 78.43 100; rgbPct 39.21% 78.43% 100%;
    local r=$1 g=$2 b=$3 invalidComps=()
    r=$(+convertPct2Dec $r)
    if [ $? -ne 0 ]; then
        invalidComps+=("Red")
    fi
    g=$(+convertPct2Dec $g)
    if [ $? -ne 0 ]; then
        invalidComps+=("Green")
    fi
    b=$(+convertPct2Dec $b)
    if [ $? -ne 0 ]; then
        invalidComps+=("Blue")
    fi
    local invalidCompsStr=$(concat "-, -" "${invalidComps[@]}")
    if [ ${#invalidComps[@]} -gt 0 ]; then
        logError "Invalid input ! $invalidCompsStr should be a number between 0 and 100." && return 1
    fi
    rgb -p $r $g $b
}

function hsl() { #? convert HSL(floats) to RGB(integers). Usage: hsl 100 50 50;
    +convertHslv2Rgb $1 $2 $3
}

function hsv() { #? convert HSV(floats) to RGB(integers). Usage: hsv 100 50 50;
    +convertHslv2Rgb -v $1 $2 $3
}

function +convertPct2Dec() { #x
    local pct=$1
    if [[ $1 =~ ^[0-9]+(\.[0-9]+)?(%)?$ ]]; then
        if [[ $1 =~ .*%$ ]]; then
            pct=${pct%?}
        fi
        if (( $(echo "$pct > 100" | bc -l) )) || (( $(echo "$pct < 0" | bc -l) )); then
            return 1
        fi
        pct=$(echo "scale=4; $pct / 100 * 255" | bc | awk '{print int($0 + 0.5)}')
        echo $pct
    else
        return 1
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
