#? Math related commands

function dec2hex() { #? convert decimals to hexadecimals
	local arg
	declare -i index=1
	local out=""
	for arg in "$@"
	do
		if ! [[ $arg =~ ^[0-9]+$ ]]; then
			logError $index"th param '$arg' is not decimal" && return 1
		fi
		[ $index -eq 1 ] && out=$out$(printf "%x" $arg) || out=$out$(printf " %x" $arg)
		index=$((index + 1))
	done
	if [ $index -gt 1 ]; then
		printf "$out\n"
	fi
}

function hex2dec() { #? convert hex unicode code points to decimals
	local arg
	declare -i index=1
	local out=""
	for arg in "$@"
	do
		if ! [[ $arg =~ ^[0-9a-fA-F]+$ ]]; then
			logWarn $index"th param '$arg' is not hexdecimal" && return 1
		fi
		out=$out"$((0x$arg)) "
		index=$((index + 1))
	done
	if [ $index -gt 0 ]; then
		printf "$out\n"
	fi
}

declare -g -A _LETTER_VALUE_MAP
declare -i v=0
for c in 0 1 2 3 4 5 6 7 8 9 a b c d e f g h i j k l m n o p q r s t u v w x y z; do
    _LETTER_VALUE_MAP[$c]=$v
    v=$((v + 1))
done
v=10
for c in A B C D E F G H I J K L M N O P Q R S T U V W X Y Z; do
    _LETTER_VALUE_MAP[$c]=$v
    v=$((v + 1))
done
unset v c

_VALUE_LETTERS=(0 1 2 3 4 5 6 7 8 9 a b c d e f g h i j k l m n o p q r s t u v w x y z)
function rebase() { #? convert integer to another base. base should in [2-36]. Usage: rebase num oldBase newBase
    if ! [[ "$1" =~ [0-9a-zA-Z]+ ]] || ! [[ "$2" =~ [0-9]+ && $2 -ge 2 && $2 -le 36 ]] || ! [[ "$3" =~ [0-9]+ && $3 -ge 2 && $3 -le 36 ]]; then
        logError "Usage: rebase num oldBase newBase. base should in [2-36]" && return 1
    fi
    local num c 
    declare -i ob nb len i v maxOldDigit maxNewDigit 
    num=$1;len=${#num};ob=$2;nb=$3

    for ((i=0; i<$len; i++)); do
        c=${num:$i:1}
        v=${_LETTER_VALUE_MAP[$c]}
        if [ $v -ge $ob ]; then
            logError "'$c' at index $i is not a value number for base $ob!"
            return 1
        fi
    done

    # convert from ob to 10 based number
    declare -i decNum digitBase
    decNum=0;digitBase=1
    for ((i=$((len - 1)); i>=0; i--)); do
        c=${num:$i:1}
        v=${_LETTER_VALUE_MAP[$c]}
        decNum=$(((v * digitBase) + decNum))
        digitBase=$((digitBase * ob))
    done

    # calculae max digital base
    local out arrayBase
    arrayBase=$(_getArrayBase)
    declare -i digitBase_
    digitBase_=$nb;digitBase=$digitBase_
    while [ $digitBase_ -le $decNum ]; do
        digitBase=$digitBase_
        digitBase_=$((digitBase_ * nb))
    done

    # convert from 10 to nb based number
    while
        if [ $decNum -lt $digitBase ]; then
            out=${out}0
        else
            v=$((decNum / digitBase))
            c=${_VALUE_LETTERS[$((v + arrayBase))]}
            out=$out$c
            decNum=$((decNum % digitBase))
        fi
        digitBase=$((digitBase / nb))
        [ $digitBase -ge 1 ]
    do :; done
    echo $out
}
