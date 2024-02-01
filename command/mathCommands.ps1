#? Match related commands

function dec2hex() {
    #? convert decimals to hexadecimals
    $i = 1
    $out = ""
    $not1st = $false
    foreach ($arg in $args) {
        if ($arg -isnot [int]) {
            throw "${i}th param '$arg' is not decimal"
            return
        }
        $int = [Int32]$arg
        $hex = $int.ToString("X")
        if ($not1st) {
            $out = "$out $hex"
        } else {
            $not1st = $true
            $out = $hex
        }
        $i++
    }
    if ($i -gt 1) {
        Write-Output "$out"
    }
}

function hex2dec() {
    #? convert hex unicode code points to decimals
    $i = 1
    $out = ""
    $not1st = $false
    foreach ($arg in $args) {
        if (-Not ($arg -match "[0-9A-Fa-f]+")) {
            throw "${i}th param '$arg' is not hexdecimal"
        }
        $dec = [Convert]::ToInt32($arg, 16)
        if ($not1st) {
            $out = "$out $dec"
        } else {
            $not1st = $true
            $out = $dec
        }
        $i++
    }
    if ($i -gt 1) {
        Write-Output "$out"
    }
}

$_LETTER_VALUE_MAP = @{}
$_VALUE_LETTERS = @()
$v = 0
foreach ($char in "0123456789abcdefghijklmnopqrstuvwxyz".ToCharArray()) {
    $_LETTER_VALUE_MAP[$char] = $v
    $_VALUE_LETTERS += $char
    $v++
}
$v = 10
foreach ($char in "ABCDEFGHIJKLMNOPQRSTUVWXYZ".ToCharArray()) {
    $_LETTER_VALUE_MAP[$char] = $v
    $v++
}
Clear-Variable v
Clear-Variable char
function rebase() {
    param(
        [Parameter(Mandatory = $true)][string]$num, 
        [Parameter(Mandatory = $true)][int]$oldBase, 
        [Parameter(Mandatory = $true)][int]$newBase
    )
    if (($num -notmatch "^[a-zA-Z0-9]+$") -or ($oldBase -lt 2 -or $oldBase -gt 36) -or ($newBase -lt 2 -or $newBase -gt 36)) {
        throw "rebase num oldBase newBase. base should in [2-36]"
    }

    for ($i = 0; $i -lt $num.Length; $i++) {
        $char =  $num[$i]
        $v = $_LETTER_VALUE_MAP[$char]
        if ($v -ge $oldBase) {
            throw "$char at index $i is not a valud number for base $oldBase!"
        }
    }

    # convert from oldBase based number to 10 based number
    $decNum = 0
    $digitBase = 1
    for ($i = $num.Length - 1; $i -ge 0; $i--) {
        $char = $num[$i]
        $v = $_LETTER_VALUE_MAP[$char]
        $decNum = $v * $digitBase + $decNum
        $digitBase = $digitBase * $oldBase
    }

    # calculae max digital base
    $digitalBase_ = $newBase
    do {
        $digitalBase = $digitalBase_
        $digitalBase_ = $digitalBase_ * $newBase
    } while ($digitalBase_ -le $decNum)

    # convert from 10 to newBase based number
    do {
        if ($decNum -lt $digitalBase) {
            if ($out.Length -gt 0) {
                $out="${out}0"
            } 
        } else {
            $v = $decNum / $digitalBase
            $char = $_VALUE_LETTERS[$v]
            $out = "$out$char"
            $decNum = $decNum % $digitalBase
        }
        $digitalBase = $digitalBase / $newBase
    } while ($digitalBase -ge 1)
    Write-Output $out
}