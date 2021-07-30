$c27 = [char]27
function logTitle {
    param([Parameter(Mandatory)]$title)
    echo "$c27[;3m$c27[92;100m<--- $title --->$c27[0m"
}

logTitle "Write-Host Supported colors"
echo "Print color by `"Write-Host 'Color1' -F color1 -nonewline; Write-Host 'Color2' -F color2 -nonewline;...`"."
Write-Host "RED" -f RED -nonewline;
Write-Host "BLUE" -f BLUE -nonewline;
Write-Host "GREEN" -f GREEN -nonewline;
Write-Host "YELLOW" -f YELLOW -nonewline;
Write-Host "CYAN" -f CYAN -nonewline;
Write-Host "MAGENTA" -f MAGENTA -nonewline;
Write-Host "WHITE" -f WHITE -nonewline;Write-Host "GRAY" -f GRAY -nonewline;
Write-Host "DARKGRAY" -f DARKGRAY -nonewline;Write-Host "BLACK" -f BLACK -nonewline;
Write-Host "DARKMAGENTA" -f DARKMAGENTA -nonewline;
Write-Host "DARKCYAN" -f DARKCYAN -nonewline;
Write-Host "DARKYELLOW" -f DARKYELLOW -nonewline;
Write-Host "DARKGREEN" -f DARKGREEN -nonewline;
Write-Host "DARKBLUE" -f DARKBLUE -nonewline;
Write-Host "DARKRED" -f DARKRED -nonewline;
echo ""

# ----------
logTitle "Full FG Colors"

echo "echo -e `"$([char]27)[38;05;nm`"hello"
echo 'n='

$is = 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15
$is | % {
    $base = $_ * 16
    $is | % {
        $n = $base + $_ 
        $s = "$c27[38;05;$n`m{0, 6}" -F $n
        Write-Host $s -nonewline
    }
    "$c27[38;0m"
}

# ----------
logTitle "ANSI BG Styles"

echo "echo `"`$([char]27)[;am`"hello"
echo 'a='

$is = 0, 1, 2, 3, 4, 7, 8, 9 
$is | % {
    $s = "$c27[;$_`m{0, 6}" -F $_ 
    Write-Host $s -nonewline
}
"$c27[0m" 

echo "\033[34;100m7: set previous bg color as fg color. \033[1;7mif corrent bg color ∈ [1, 29], set previous fg color as bg color\033[0m"

# ----------
logTitle "ANSI BG Colors"

echo "echo `"`$([char]27)[30;am`"hello"
echo 'a='
$is = 3, 4, 5, 11, 12, 13
$js = 0, 1, 2, 3, 4, 5, 6, 7

$is | % {
    $base = $_ * 8;
    $js | % {
        $n = $base + $_
        $s = "$c27[30;$n`m{0, 6}" -F $n
        Write-Host $s -nonewline 
    }
    "$c27[0m" 
}

# ----------
logTitle "ANSI FG Colors"

echo "echo `"`$([char]27)[a;40m`"hello"
echo 'a='

$is | % {
    $base = $_ * 8;
    $js | % {
        $n = $base + $_
        $s = "$c27[$n;40`m{0, 6}" -F $n
        Write-Host $s -nonewline 
    }
    "$c27[0m" 
}
