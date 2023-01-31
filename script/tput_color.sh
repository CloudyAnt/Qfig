#!/bin/sh

function logTitle() {
    [ -z "$1" ] && return
    echo "\033[;3m\033[92;100m<--- $1 --->\033[0m"
}
printf '\e]8;;https://stackabuse.com/how-to-change-the-output-color-of-echo-in-linux\aReference\e]8;;\a\n'
logTitle "All Supported Colors"

echo "echo \`tput setbf n\`n"
echo 'n='

js=`echo 0 15 | awk '{ for(i = $1; i <= $2; i++) printf i " " }'`
is=`echo 0 15 | awk '{ for(i = $1; i <= $2; i++) printf i " " }'`

for i in $is; do
    base=`expr $i \* 16`
    for j in $js; do
        n=`expr $base + $j`
        printf "`tput setab $n`%-6s" "$n"
    done
    printf "\e[38;0m"
    echo
done

logTitle "All Supported Styles"
echo "echo \`tput setaf 1\`A --> `tput setaf 1`A\033[0;0m"
echo "echo \`tput setab 1\`A --> `tput setab 1`A\033[0;0m"
echo "echo \`tput bold\`A --> `tput bold`A\033[0;0m"
echo "echo \`tput dim\`A --> `tput dim`A\033[0;0m"
echo "echo \`tput smul\`A --> `tput smul`A\033[0;0m"
echo "echo \`tput blink\`A --> `tput blink`A\033[0;0m"
echo "echo \`tput rev\`A --> `tput rev`A\033[0;0m"
