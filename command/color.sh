# Print Colors
# Reference:
# https://i.stack.imgur.com/OK3po.png

function logTitle() {
    [ -z "$1" ] && return
    echo "\033[;3m\033[92;100m<--- $1 --->\033[0m"
}

logTitle "Full FG Colors"

echo "echo -e \"\\\e[38;05;nm\"hello"
echo 'n='

js=`echo 0 15 | awk '{ for(i = $1; i <= $2; i++) printf i " " }'`
is=`echo 0 15 | awk '{ for(i = $1; i <= $2; i++) printf i " " }'`

for i in $is; do
    base=`expr $i \* 16`
    for j in $js; do
        n=`expr $base + $j`
        printf "\e[38;05;${n}m%-6s" "$n"
    done
    printf "\e[38;0m"
    echo
done

logTitle "ANSI BG Styles"

echo "echo \"\\\033[;am\"hello"
echo 'a='

is='0 1 2 3 4 9 7 0'
for i in $is; do
    printf "\033[;${i}m%-6s" "$i"  
done
printf "\033[0m"
echo

echo "\033[34;100m7: set previous bg color as fg color. \033[1;7mif corrent bg color ∈ [1, 29], set previous fg color as bg color\033[0m"

logTitle "ANSI BG Colors"

echo "echo \"\\\033[30;am\"hello"
echo 'a='

js=`echo 0 7 | awk '{ for(i = $1; i <= $2; i++) printf i " " }'`
is='3 4 5 11 12 13'

for i in $is; do
    base=`expr $i \* 8`
    for j in $js; do
        n=`expr $base + $j`
        printf "\033[30;${n}m%-6s" "$n"  
    done
    printf "\033[0m"
    echo
done

logTitle "ANSI FG Colors"

echo "echo \"\\\033[a;40m\"hello"
echo 'a='

for i in $is; do
    base=`expr $i \* 8`
    for j in $js; do
        n=`expr $base + $j`
        printf "\033[${n};40m%-6s" "$n"  
    done
    printf "\033[0m"
    echo
done
