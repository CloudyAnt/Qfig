# Reference:
# https://i.stack.imgur.com/OK3po.png

echo "echo \"\\\e[38;05;\${n}m\"hello"
echo 'n='

js=`echo 0 15 | awk '{ for(i = $1; i <= $2; i++) printf i " " }'`
is=`echo 0 15 | awk '{ for(i = $1; i <= $2; i++) printf i " " }'`

for i in $is; do
    base=`expr $i \* 16`
    for j in $js; do
        n=`expr $base + $j`
        printf "\e[38;05;${n}m%-6s" "($n)"
    done
    echo
done

echo "------------"

echo "echo \"\\\033[\${a;b}m;\"hello"
echo 'a;b='

js=`echo 0 7 | awk '{ for(i = $1; i <= $2; i++) printf i " " }'`
is=`echo 0 15 | awk '{ for(i = $1; i <= $2; i++) printf i " " }'`

for i in $is; do
    base=`expr $i \* 8`
    for j in $js; do
        n=`expr $base + $j`
        printf "\033[0;${n}m%-8s\033[1;${n}m%-8s\033[0m" "(0;$n)" "(1;$n)"
    done
    echo
done


