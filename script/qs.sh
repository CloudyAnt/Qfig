#!/bin/bash
# Quick Sort
# The Shell variables defined in session and functions are visible mutually by default.
# The 'local' keyword limit a variable only work in containing function

function partition {
    local l=$1
    local r=$2
    local i=$(($l - 1))

    local j=$l;
    local temp;
    for ((; j<=$(($r - 1)); j++)); do
        if [[ ${arr[$j]} -lt ${arr[$r]} ]]
        then
            temp=${arr[$j]}
            i=$(($i + 1))
            arr[$j]=${arr[$i]}
            arr[$i]=$temp
        fi
    done

    temp=${arr[$r]}
    i=$(($i + 1))
    arr[$r]=${arr[$i]}
    arr[$i]=$temp

    middle=$i
}

function qs {
    local l=$1
    local r=$2

    if [ $l -lt $r ]
    then
        partition $l $r
        local middle=$middle
        qs $l $(($middle - 1))
        qs $(($middle + 1)) $r
    fi
}

arr=($@)

if [ ${#arr[@]} -lt 1 ] 
then
    echo "To sort what??"
else
    intRe='^[0-9]+$'
    arrIsValid=1

    for i in $(seq 0 $(expr ${#arr[@]} - 1));do
        if [[ ! ${arr[$i]} =~ $intRe ]] 
        then 
            arrIsValid=0
            break
        fi
    done

    if [ $arrIsValid -eq 1 ]
    then
        recursion=0
        qs 0 $((${#arr[@]} - 1))
        echo ${arr[*]}
    else
        echo "Array is invalid!!"
    fi
fi