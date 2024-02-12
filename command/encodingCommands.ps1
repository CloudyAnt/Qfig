#? Encodings related coomands

function chr2uni() {
    param([Parameter(Mandatory)][string]$str)
    chr2ucp $str -lowercase -u -noSpace
}

function chr2ucp() {
    param([Parameter(Mandatory)][string]$str, [switch]$lowercase, [switch]$u, [switch]$noSpace)

    $not1st = $false
    if ($u) {
        $prefix = "\u"
    } else {
        $prefix = ""
    }
    foreach ($char in $str.ToCharArray()) {
        $ucp = "$prefix$(Convert1Char2Ucp $char)"
        if ($not1st -And (-Not $noSpace)) {
            $ucps += " $ucp"
        } else {
            $ucps += $ucp
            $not1st = $true
        }
    }
    if ($lowercase) {
        Write-Output $ucps.ToLower()
    } else {
        Write-Output $ucps
    }
}

function Convert1Char2Ucp() {
    param([char]$char, [switch]$decimal)

    $utf32bytes = [System.Text.Encoding]::UTF32.GetBytes($char)
    $intucp = [System.BitConverter]::ToUint32($utf32bytes)
    if ($decimal) {
        return $intucp
    }
    return $intucp.ToString("X")
}