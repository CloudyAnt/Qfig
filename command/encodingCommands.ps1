#? Encodings related coomands

function chr2uni() {
    param([Parameter(Mandatory)][string]$str)
    chr2ucp $str -lowercase -u
}

function chr2ucp() {
    param([Parameter(Mandatory)][string]$str, [switch]$lowercase, [switch]$u)

    if ($u) {
        $prefix = "\u"
        $suffix = ""
    } else {
        $prefix = ""
        $suffix = " "
    }
    foreach ($char in $str.ToCharArray()) {
        $ucps += "$prefix$(Convert1Char2Ucp $char)$suffix"
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