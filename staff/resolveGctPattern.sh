[ -z "$1" ] && echo "Pattern must not be empty!" && exit 1
pattern=$1
# pattern example:<name@^[^\:]+$:Unknown> <#type@^[^\:]+$:refactor fix feat chore doc test style>: <#message@^[^\:]+$:Unknown>

# token types:
# 0 String
# 1 Step
# 10 Branch-scope-step mark
# 11 Step regex
# 12 Step options
tokens=""
escaping=""

# x(status) types:
# 0 append string
# 1 append key
# 2 append option
# 3 append regex
x=0
stepsCount=0
stepRegex=""
lastStepKey=""
recordingStepType=0
[[ "$(uname -s)" =~ CYGWIN* || "$(uname -s)" =~ MINGW* ]] && NL="\r\n" || NL="\n" # Windows use \r\n as newline
for (( i=0 ; i<${#pattern}; i++ )); do
    c=${pattern:$i:1}

	if [ $recordingStepType -eq 1 ]; then
		recordingStepType=0
		# append branch-scope-step mark
		if [ '#' = "$c" ]; then
			tokens+="10:$NL"
			continue
		fi
	fi
    [ '\' = "$c" ] && escaping=1 && continue

    if [ $escaping ]; then
        s=$s$c
        escaping=""
        continue
    fi

    case $x in
        0) # appending string
            if [[ '>' = "$c" ]]; then
                echo "Bad ending '$c' at index $i. No corrosponding beginning" && exit 1
            elif [ '<' = "$c" ]; then
				[ "$s" ] && tokens+="0:$s$NL" && s=""
                x=1
				stepRegex=""
				recordingStepType=1
            else
                s=$s$c
            fi
            ;;
        1) # appending key
            if [ ':' = "$c" ]; then
                if [ "$s" ]; then
                    tokens+="1:$s$NL"
					lastStepKey=$s
                    s=""
                    x=2
                else
                    echo "Bad options beginning '$c' at index $i. Key name must not be empty" && exit 1
                fi
			elif [ '@' = "$c" ]; then
                if [ "$s" ]; then
                    tokens+="1:$s$NL"
                    s=""
                    x=3
                else
                    echo "Bad regex beginning '$c' at index $i. Key name must not be empty" && exit 1
				fi
			elif [ '<' = "$c" ]; then
				echo "Bad key beginning '$c' at index $i. Specifying key \"$lastStepKey\" content"  && exit 1
			elif [ '>' = "$c" ]; then
				if [ "$s" ]; then
					tokens+="1:$s$NL"
                    stepsCount=$(($stepsCount + 1))
					s=""
					x=0
				else
					echo "Bad key ending '$c' at index $i. Key name must not be empty" && exit 1
				fi
            else
                s=$s$c
            fi
            ;;
        2) # appending options
			if [ '<' = "$c" ]; then
				echo "Bad key beginning '$c' at index $i. Specifying key \"$lastStepKey\" options"  && exit 1
			elif [ '>' = "$c" ]; then
				if [ "$s" ]; then
					if [ $stepRegex ]; then
						ops=($s)
						for option in $ops; do
							if ! [[ $option =~ $stepRegex ]]; then
								echo "Option \e[1m$option\e[0m is not matching \e[3m$stepRegex\e[0m" && exit 1
							fi
						done
					fi
					tokens+="12:$s$NL"
                    stepsCount=$(($stepsCount + 1))
				else
					echo "Please specify options for key \"$lastStepKey\" or remove the ':'" && exit 1
				fi
				s=""
				x=0
			else
				s=$s$c
			fi
            ;;
		3) # appending regex
			if [ '<' = "$c" ]; then
				echo "Bad key beginning '$c' at index $i. Specifying key \"$lastStepKey\" regex"  && exit 1
			elif [ '>' = "$c" ]; then
				if [ "$s" ]; then
					tokens+="11:$s$NL"
                    stepsCount=$(($stepsCount + 1))
				else
					echo "Please specify regex for key \"$lastStepKey\" or remove the '@'" && exit 1
				fi
				s=""
				x=0
			elif [ ':' = "$c" ]; then
				if [ "$s" ]; then
					tokens+="11:$s$NL"
					stepRegex=$s
					s=""
					x=2
				else
					echo "Please specify regex for key \"$lastStepKey\" or remove the '@'" && exit 1
				fi
			else
				s=$s$c
			fi
			;;
    esac
done

if [ $x -eq 0 ]; then
    if [ "$s" ]; then
        tokens+="0:$s"
    fi
else
	echo "Bad ending! Step specification not ended. (status $x)" && exit 1
fi

if [ $stepsCount -eq 0 ]; then
    echo "Please specify any steps!" && exit 1
fi

printf "%s" "$tokens" # print without escape