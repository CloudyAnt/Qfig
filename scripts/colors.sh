
# view here:
# https://i.stack.imgur.com/OK3po.png

e=$'\e['

for n in {0..7}; do
    printf "${e}"'38;05;'"${n}"'m%-6s' '('"$n"') '
done
printf '\n'

for n in {8..15}; do
    printf "${e}"'38;05;'"${n}"'m%-6s' '('"$n"') '
done
printf '\n\n'

STEP='6'

START='16'
for i in {0..5}; do
    for j in {0..11}; do
        if (( $j < 6 )); then
            n="$(( $START + ( $j * $STEP ) + $i))"
        else
            n="$(( $START + ( ( 17 - $j ) * $STEP ) + $i))"
        fi
        printf "${e}"'38;05;'"${n}"'m%-6s' '('"$n"') '
    done
    printf '\n'
done
printf '\n'

START='93'
for i in {0..5}; do
    for j in {0..11}; do
        if (( $j < 6 )); then
            n="$(( $START + ( $j * $STEP ) - $i))"
        else
            n="$(( $START + ( ( 17 - $j ) * $STEP ) - $i))"
        fi
        printf "${e}"'38;05;'"${n}"'m%-6s' '('"$n"') '
    done
    printf '\n'
done
printf '\n'

START='160'
for i in {0..5}; do
    for j in {0..11}; do
        if (( $j < 6 )); then
            n="$(( $START + ( $j * $STEP ) + $i))"
        else
            n="$(( $START + ( ( 17 - $j ) * $STEP ) + $i))"
        fi
        printf "${e}"'38;05;'"${n}"'m%-6s' '('"$n"') '
    done
    printf '\n'
done
printf '\n'

for n in {232..243}; do
    printf "${e}"'38;05;'"${n}"'m%-6s' '('"$n"') '
done
printf '\n'

for n in {255..244}; do
    printf "${e}"'38;05;'"${n}"'m%-6s' '('"$n"') '
done
printf '\n'
