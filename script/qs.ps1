# Quick sort
# The Powershell variable scope works like C#, Java, etc, so this scripts works like them too

[int[]]$list = (Read-Host "Please Input an int array, separated by ','`n").split(",") | ForEach-Object {
    [int]$_
}

function partition {
    param(
        [Parameter(Mandatory)][int[]]$list,
        [Parameter(Mandatory)][int]$l,
        [Parameter(Mandatory)][int]$r
    )
    
    $i = $l - 1;
    For($j = $l; $j -Lt $r; $j++ ) {
        if ($list[$j] -Lt $list[$r]) {
            $temp = $list[$j]
            $list[$j] = $list[++$i]
            $list[$i] = $temp
        }
    }
    $temp = $list[$r]
    $list[$r] = $list[++$i]
    $list[$i] = $temp 
    Return $i
}

function qs {
    param(
        [Parameter(Mandatory)][int[]]$list,
        [Parameter(Mandatory)][int]$l,
        [Parameter(Mandatory)][int]$r
    )

    if ($l -Lt $r) {
        $middle = partition $list $l $r
        qs $list $l ($middle - 1)
        qs $list $($middle + 1) $r
    }
}

qs $list 0 ($list.Length - 1)
$list -join "," 
