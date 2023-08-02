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

