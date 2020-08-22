# Reference:
# https://i.stack.imgur.com/OK3po.png

echo "echo \"\\\e[38;05;\${n}m\"hello"
echo 'n='

js=`echo 1 8 | awk '{ for(i = $1; i <= $2; i++) printf i " " }'`
is=`echo 1 32 | awk '{ for(i = $1; i <= $2; i++) printf i " " }'`

for i in $is; do
    for j in $js; do
        n=`expr $i \* $j`
        printf "\e[38;05;${n}m%-6s" "($n)"
    done
    echo
done
