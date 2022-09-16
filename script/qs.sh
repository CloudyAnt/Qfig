#!/bin/bash
# Quick Sort

function partition {
    arr=$1
    l=$2
    r=$3
    i=`expr $l - 1`

    for j in `seq $l $(expr $r - 1)`;do
        if [ ${arr[$j]} -le ${arr[$r]} ]
        then
            i=`expr $i + 1`
            temp=${arr[$j]}
            arr[$j]=${arr[$i]}
            arr[$i]=$temp

        fi
    done

    i=`expr $i + 1`
    temp=${arr[$r]}
    arr[$r]=${arr[$i]}
    arr[$i]=$temp

    partitionIndex=$i
}

function qs {
    recursion=`expr $recursion + 1`
    arr=$1
    l=$2
    r=$3

    if [ $l -lt $r ]
    then
        eval "l$recursion=$l"
        eval "r$recursion=$r"
        partition $arr $l $r
        eval "partitionIndex$recursion=$partitionIndex"
        qs $arr $l `expr $partitionIndex - 1`

        partitionIndexx="echo \$partitionIndex$recursion"
        partitionIndex=`eval $partitionIndexx`
        rx="echo \$r$recursion"
        r=`eval $rx`
        qs $arr `expr $partitionIndex + 1` $r 
    fi

    recursion=`expr $recursion - 1`
}

arr=($@)

if [ ${#arr[@]} -lt 1 ] 
then
    echo "To sort what??"
else
    intRe='^[0-9]+$'
    arrIsValid=1

    for i in `seq 0 $(expr ${#arr[@]} - 1)`;do
        if [[ ! ${arr[$i]} =~ $intRe ]] 
        then 
            arrIsValid=0
            break
        fi
    done

    if [ $arrIsValid -eq 1 ]
    then
        recursion=0
        qs $arr 0 `expr ${#arr[@]} - 1`
        echo ${arr[*]}
    else
        echo "Array is invalid!!"
    fi
fi

