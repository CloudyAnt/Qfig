[ -z "$1" ] && echo "Pattern must not be empty!" && exit 1
pattern=$1
# pattern='[name:]-[type:a b c]#[card:0 1]@@[message:Nothing]'

# token types:
# 0:
# 1:abc:d e f
tokens=""
escaping=""

# x(status) types:
# 0 append string
# 1 append key
# 2 append option
x=0
for (( i=0; i<${#pattern}; i++ )); do
    c=${pattern:$i:1}
    [ '\' = "$c" ] && escaping=1 && continue

    if [ $escaping ]; then
        s=$s$c
        escaping=""
        continue
    fi

    case $x in
        0)
            if [[ ']' = "$c" ]]; then
                echo "Bad ending '$c' at index $i. No corrosponding beginning" && exit 1
            elif [ '[' = "$c" ]; then
				[ "$s" ] && tokens+="0:$s\n" && s=""
                x=1
            else
                s=$s$c
            fi
            ;;
        1)
            if [ ':' = "$c" ]; then
                if [ "$s" ]; then
                    k=$s
                    s=""
                    x=2
                else
                    echo "Bad options beginning '$c' at index $i. Key name must not be empty" && exit 1
                fi
			elif [ '[' = "$c" ]; then
				echo "Bad key beginning'$c' at index $i. Specifying key \"$k\" content"  && exit 1
			elif [ ']' = "$c" ]; then
				if [ "$s" ]; then
					tokens+="1:$s\n"
					s=""
					x=0
				else
					echo "Bad key ending '$c' at index $i. Key name must not be empty" && exit 1
				fi
            else
                s=$s$c
            fi
            ;;
        2)
			if [ '[' = "$c" ]; then
				echo "Bad key beginning'$c' at index $i. Specifying key \"$k\" options"  && exit 1
			elif [ ']' = "$c" ]; then
				if [ "$s" ]; then
					tokens+="1:$k:$s\n"
				else
					echo "No options specificed of key \"$k\"" && exit 1
				fi
				s=""
				x=0
			else
				s=$s$c
			fi
            ;;
    esac
done

if [ $x -eq 1 ]; then
	echo "Bad ending! Specification not ended for key \"$s\"" && exit 1
elif [ $x -eq 2 ]; then
	echo "Bad ending! Specification not ended for key \"$k\"" && exit 1
fi

echo $tokens
