#? Encodings related coomands
enable-qcmds math

function chr2uni() { #? convert characters to unicodes(4 digits with '\u' prefix)
	local hexes
	hexes=($(echo $(chr2ucp "$@")))
	for hex in "${hexes[@]}"; do
		hex=$(alignLeft $hex 0 4)
		printf "\\\u$hex"
	done
	printf "\n"
}

function chr2uni8() { #? convert characters to unicodes(4 digits with '\u' prefix or 8 digits with '\U' prefix)
	local hexes
	hexes=($(echo $(chr2ucpx "$@")))
	for hex in "${hexes[@]}"; do
		if [ ${#hex} -gt 4 ]; then
			hex=$(alignLeft $hex 0 8)
			printf "\\\U$hex"
		else
			hex=$(alignLeft $hex 0 4)
			printf "\\\u$hex"
		fi
	done
    printf "\n"
}

#? 'echo' convert '\u' or '\U' prefixed hexdecimals to chars, makes a function 'unicode2char' unnecessary

function ucp2chr() { #? convert unicode code points to characters
	declare -i codesCount=0;
	declare -i charsCount=0;
	local ls=""
	local err=""
	local arg
	for arg in "$@"
	do
		codesCount=$((codesCount + 1))
		if ! [[ $arg =~ ^[0-9a-fA-F]+$ ]]; then
			err="The $codesCount""th arg '$arg' is not hexdecimal" && break
			break
		elif [[ 0x$arg -lt 0x0 || 0x$arg -gt 0x10FFFF ]]; then
			err="The $codesCount""th arg '$arg' is out of range [0, 10FFFF]" && break
		elif [ $ls ]; then
			if [[ 0x$arg -lt 0xDC00 || 0x$arg -gt 0xDFFF ]]; then
				err="The $codesCount""th unicode is not a trailing surrogate, while the previous arg $ls is a leading surrogate" && break
			fi
			local uni=$(sp2ucp $ls $arg)
			printf "\U$uni"
			charsCount=$((charsCount + 1))
			ls=""
		elif [[ 0x$arg -ge 0xD800 && 0x$arg -le 0xDBFF ]]; then
			ls=$arg
		elif [[ 0x$arg -ge 0xDC00 && 0x$arg -le 0xDFFF ]]; then
			err="The $codesCount""th unicode is a trailing surrogate, however is was not followed by a leading surrogate" && break
		elif [ ${#arg} -gt 4 ]; then
			if [ ${#arg} -gt 8 ]; then
				arg=${arg:$((${#arg} - 8))}
			fi
			printf "\U$arg"
			charsCount=$((charsCount + 1))
		else
			printf "\u$arg"
			charsCount=$((charsCount + 1))
		fi
	done
	[ $charsCount -gt 0 ] && printf "\n"
	if [ $err ]; then
		logError $err
		return 1
	fi
}

function chr2ucpx() { #? convert characters to unicode code points (try to elimiate surrogate pairs)
	[ -z "$1" ] && return
	local hexes lps
	hexes=($(echo $(chr2ucp "$1")))
	for hex in "${hexes[@]}"; do
		if [ $lps ]; then
			if [[ 0x$hex -ge 0xDC00 && 0x$hex -le 0xDFFF ]]; then
				hex=$(sp2ucp $lps $hex)
				printf "$hex "
			else
				printf "$lps $hex "
			fi
			lps=""
		elif [[ 0x$hex -ge 0xD800 && 0x$hex -le 0xDBFF ]]; then
			lps="$hex"
		else
			printf "$hex "
		fi
	done
    printf "\n"
}

function chr2ucp() { #? convert characters to unicode code points (may contain surrogate pair under GitBash and Cygwin)
	[ -z "$1" ] && return
	local all c i
	all=$@
	for (( i=0 ; i<${#all}; i++ )); do
		c=${all:$i:1}
		printf "%x " "'$c"
	done
	printf "\n"
}


function ucp2sp() { #? convert 1 unicode (range [10000, 10FFFF]) to surrogate pair (range [D800, DBFF] and [DC00, DFFF])
	[ -z "$1" ] && return
	if ! [[ $1 =~ ^[0-9a-fA-F]+$ ]]; then
		logWarn "$1 is not hexdecimal" && return
	fi

	if [[ 0x$1 -lt 0x10000 || 0x$1 -gt 0x10FFFF ]]; then
		if [ '-p' = $2 ]; then # print when out of range
			echo $1
		else
			logWarn "$1 is out of range [10000, 10FFFF]"
		fi
	else
		local offset row column high low
		offset=$((0x$1 - 0x10000))
		row=$(($offset / 0x400))
		column=$(($offset % 0x400))
		high=$((0xD800 + $row))
		low=$((0xDC00 + $column))
		dec2hex $high $low
	fi
}

function sp2ucp() { #? convert 1 surrogate pair (range [D800, DBFF] and [DC00, DFFF]) to unicode (range [10000, 10FFFF])
	[[ -z $1 || -z $2 ]] && logWarn "A surrogate pair needs 2 units" && return
	if ! [[ $1 =~ ^[0-9a-fA-F]+$ && $2 =~ ^[0-9a-fA-F]+$ ]]; then
		logWarn "$1 or $2 is not hexdecimal" && return
	fi

	if [[ 0x$1 -lt 0xD800 || 0x$1 -gt 0xDBFF ]]; then
		logWarn "1st (high-surrogate) unit $1 is out of range [D800, DBFF]" && return
	fi
	if [[ 0x$2 -lt 0xDC00 || 0x$2 -gt 0xDFFF ]]; then
		logWarn "2nd (low-surrogate) unit $2 is out of range [DC00, DFFF]" && return
	fi

	local highOffset lowOffset uni
	highOffset=$((0x$1 - 0xD800))
	lowOffset=$((0x$2 - 0xDC00))
	uni=$(($highOffset * 1024 + $lowOffset + 0x10000))
	dec2hex $uni
}

function ucp2utf8() { #? covert unicode code points to utf8 code units, -h for more.
	local arg out part bytesInterval silent
	declare -i index=1
    bytesInterval=" "
	OPTIND=1
	while getopts ":hus" opt; do
        case $opt in
			h)
				logInfo "Usage: confirm \$flags(optional) \$msg(optional).\n  Flags:\n"
				printf "    %-5s%s\n" "h" "Print this help message"
				printf "    %-5s%s\n" "u" "Rm spaces between bytes of one hex"
				printf "    %-5s%s\n" "s" "To be silent when error occurs"
				return 0
				;;
            u)
				bytesInterval=""
                ;;
			s)
				silent=1
				;;
            \?)
                echo "Invalid option: -$OPTARG" && return
                ;;
        esac
    done
	shift "$((OPTIND - 1))"

	declare -i uni
	for arg in "$@"
	do
		if ! [[ $arg =~ ^[0-9a-fA-F]+$ ]]; then
			[ "$silent" ] && : || logError $index"th param '$arg' is not decimal"
			return 1
		fi
		uni=0x$arg
		part=""
		if [[ 0x$arg -le 0xF ]]; then
			part="${part}0$arg"
		elif [[ 0x$arg -le 0x7F ]]; then
			part="$part$arg"
		elif [[ 0x$arg -le 0x7FF ]]; then
			part="$part$(dec2hex $((0xC0 + ($uni >> 6))))$bytesInterval"
			part="$part$(dec2hex $((0x80 + ($uni & 0x3F))))"
		elif [[ 0x$arg -le 0xFFFF ]]; then
			part="$part$(dec2hex $((0xE0 + ($uni >> 12))))$bytesInterval"
			part="$part$(dec2hex $((0x80 + ($uni >> 6 & 0x3F))))$bytesInterval"
			part="$part$(dec2hex $((0x80 + ($uni & 0x3F))))"
		elif [[ 0x$arg -le 0x10FFFF ]]; then
			part="$part$(dec2hex $((0xF0 + ($uni >> 18))))$bytesInterval"
			part="$part$(dec2hex $((0x80 + ($uni >> 12 & 0x3F))))$bytesInterval"
			part="$part$(dec2hex $((0x80 + ($uni >> 6 & 0x3F))))$bytesInterval"
			part="$part$(dec2hex $((0x80 + ($uni & 0x3F))))"
		else
			[ "$silent" ] && : || logError $index"th param '$arg' is out of range"
			return 1
		fi
		if [ $index -gt 1 ]; then
			out="$out $part"
		else
			out=$part
		fi
		index=$((index + 1))
	done
	echo $out
}

function ucp2utf16() { #? covert hex unicode code points to utf16 code units, -h for more
	local bytesInterval le opt silent
    bytesInterval=" "
	OPTIND=1
	while getopts ":husl" opt; do
        case $opt in
			h)
				logInfo "Usage: confirm \$flags(optional) \$msg(optional).\n  Flags:\n"
				printf "    %-5s%s\n" "h" "Print this help message"
				printf "    %-5s%s\n" "u" "Rm spaces between bytes of one hex"
				printf "    %-5s%s\n" "l" "Change to litte endian"
				printf "    %-5s%s\n" "s" "To be silent when error occurs"
				return 0
				;;
            u)
				bytesInterval=""
                ;;
			s)
				silent=1
				;;
			l)
				le=1
				;;
            \?)
                echo "Invalid option: -$OPTARG" && return
                ;;
        esac
    done
	shift "$((OPTIND - 1))"

	local arg out byte1 byte2 sp separator
	declare -i index=1
	declare -i byteIndex=1
	declare -i uni
	declare -i arrayBase=$(getArrayBase)

	function _process() {
		[ $byteIndex -eq 1 ] && separator="" || separator=" "
		byte1=$(dec2hex $(($uni >> 8)))
		byte2=$(dec2hex $(($uni & 0xFF)))
		[[ 0x$byte1 -le 0xF ]] && byte1="0$byte1" || :
		[[ 0x$byte2 -le 0xF ]] && byte2="0$byte2" || :
		[ $le ] && out+="$separator$byte2$bytesInterval$byte1" || out+="$separator$byte1$bytesInterval$byte2"
	}

	for arg in "$@"
	do
		if ! [[ $arg =~ ^[0-9a-fA-F]+$ ]]; then
			[ "$silent"] && : || logError $index"th param '$arg' is not decimal" && unset -f _process
			return 1
		fi

		if [[ 0x$arg -le 0xFFFF ]]; then
			uni=0x$arg
			_process
			byteIndex=$((byteIndex + 1))
		elif [[ 0x$arg -le 0x10FFFF ]]; then
			sp=($(echo $(ucp2sp $arg)))
			uni=0x${sp[$arrayBase]}
			_process
			byteIndex=$((byteIndex + 1))

			uni=0x${sp[$((arrayBase + 1))]}
			_process
			byteIndex=$((byteIndex + 1))
		else
			[ "$silent"] && : || logError $index"th param '$arg' is out of range" && unset -f _process
			return 1
		fi
		index=$((index + 1))
	done
	unset -f _process
	echo $out
}

function utf82ucp() { #? covert utf8 bytes to unicode code points. If badly stopped return 1. If invalid return 2 and can't be silented
	local silent
	OPTIND=1
	while getopts ":hs" opt; do
        case $opt in
			h)
				logInfo "Usage: confirm \$flags(optional) \$msg(optional).\n  Flags:\n"
				printf "    %-5s%s\n" "h" "Print this help message"
				printf "    %-5s%s\n" "s" "To be silent when error occurs"
				return 0
				;;
			s)
				silent=1
				;;
            \?)
                echo "Invalid option: -$OPTARG" && return
                ;;
        esac
    done
	shift "$((OPTIND - 1))"

    [ -z "$1" ] && return
    local arg hex out
    declare -i i bn bc n offs
    i=0;bn=0;bc=0;n=0;offs=0
    for arg in "$@"; do
        i=$((i + 1))
        if [[ "$arg" =~ [0-9a-fA-F][0-9a-fA-F] ]]; then
            if [ $bn -gt $bc ]; then
                if [ $((0x$arg >> 6)) -eq 2 ]; then
                    offs=$(((bn - bc - 1) * 6))
                    n=$((((0x$arg & 0x3F) << $offs) + n))
                    bc=$((bc + 1))
                    if [ $bn -eq $bc ]; then
                        out=$out$(dec2hex $n)
                    fi
                else
                    logError "The ${i}th byte '$arg' should be 10xxxxxx!" && return 2
                fi
            elif [ $((0x$arg >> 7)) -eq 0 ]; then
				out=$out$arg
			elif [ $((0x$arg >> 5)) -eq 6 ]; then
				bn=2; bc=1
                n=$(((0x$arg & 0x1F) << 6))
			elif [ $((0x$arg >> 4)) -eq 14 ]; then
				bn=3; bc=1
                n=$(((0x$arg & 0x0F) << 12))
			elif [ $((0x$arg >> 3)) -eq 30 ]; then
				bn=4; bc=1
                n=$(((0x$arg & 0x07) << 18))
			else
				logError "Invalid 1st byte '0x$arg' (before index $i)! Should be one of 0xxxxxx, 110xxxxx, 1110xxxx, 11110xx" && return 2
			fi
        else
            logError "The ${i}th byte '$arg' is not match [0-9a-fA-F][0-9a-fA-F]!" && return 2
        fi
    done
    if [ $bn -gt $bc ]; then
		[ "$silent" ] && : || logError "Bytes recording badly stopped"
		return 1
	fi
    echo $out
}

_NO_URL_ENCODING_CHARS="0-9a-zA-Z._~\!\$\'\(\)*+,=\;-"

function enurlp() { #? encode url param by UTF-8
	[ -z "$1" ] && return
	local i all c hex out
	declare -a bytes
	all=$@
	for (( i=0 ; i<${#all}; i++ )); do
		c=${all:$i:1}
		if [[ "$c" = " " ]]; then
			out=$out%20
		elif [[ "$c" =~ [$_NO_URL_ENCODING_CHARS] ]]; then
			out=$out$c
		else
			hex=$(printf "%x" "'$c")
			bytes=($(echo $(ucp2utf8 $hex)))
			for byte in "${bytes[@]}"; do
				out="$out%$byte"
			done
		fi
	done
	echo $out
}

function deurlp() { #? decode url param by UTF-8
	[ -z "$1" ] && return
	local i all c hex out collecting1 b_ collecting2 bytes chr ucp exitCode
	declare -i arrayBase=$(getArrayBase) bn n
	declare -a bytes
	all=$@

	for (( i=0 ; i<${#all}; i++ )); do
		c=${all:$i:1}
		if [ "$collecting1" ]; then
			if ! [[ "$c" =~ [0-9a-fA-F] ]]; then
				logError "Bad char '$c' at index $i! There should be 2 hex digits behind a %" && return 1
			fi
			b_=$c
			collecting1=""
			collecting2=1
		elif [ "$collecting2" ]; then
			if ! [[ "$c" =~ [0-9a-fA-F] ]]; then
				logError "Bad char '$c' at index $i! There should be 2 hex digits behind a %" && return 1
			fi
			bytes+=($b_$c)
			ucp=$(utf82ucp ${bytes[@]})
			exitCode=$?
			if [ $exitCode -eq 0 ]; then
				out=$out$(ucp2chr $ucp)
				bytes=()
			elif [ $exitCode -eq 2 ]; then
				logError "Bad bytes [${bytes[@]}]! :\n$ucp" # $ucp is error message now
				return 1
			fi
			collecting2=""
		elif [[ "$c" = "%" ]]; then
			collecting1=1
			continue
		elif [[ "$c" =~ [$_NO_URL_ENCODING_CHARS] ]]; then
            if [ ${#bytes[@]} -gt 0 ]; then
                logError "Recorded bad UTF-8 bytes at index $i (char '$c')!" && return 1
            fi
			out="$out$c"
		else
			logError "Bad char '$c' at index $i! Chars not match [$_NO_URL_ENCODING_CHARS] should be encoded" && return 1
		fi
	done

    [[ "$collecting1" || "$collecting2" ]] && logError "Badly end! It's recording a byte." && return 1

    if [ ${#bytes[@]} -gt 0 ]; then
        ucp=$(utf82ucp ${bytes[@]})
        bytes=()
        if [ $? -eq 0 ]; then
            out=$out$(ucp2chr $ucp)
        else
            logError "Recorded bad UTF-8 bytes at the end!" && return 1
        fi
    fi
	echo $out
}