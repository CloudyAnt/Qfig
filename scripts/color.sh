# Reference:
# https://i.stack.imgur.com/OK3po.png

echo "echo \"\\\e[38;05;\${n}m\"hello"
echo 'n='

js=`echo 0 7 | awk '{ for(i = $1; i <= $2; i++) printf i " " }'`
is=`echo 0 31 | awk '{ for(i = $1; i <= $2; i++) printf i " " }'`

for i in $is; do
    base=`expr $i \* 8`
    for j in $js; do
        n=`expr $base + $j`
        printf "\e[38;05;${n}m%-6s" "($n)"
    done
    echo
done
