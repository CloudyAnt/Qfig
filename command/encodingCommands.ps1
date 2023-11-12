#? Encodings related coomands

function chr2ucp() {
    param([Parameter(Mandatory)][string]$str)

    foreach ($char in $str.ToCharArray()) {
        $ucps += "$(Convert1Char2Ucp $char) "
    }
    Write-Output $ucps
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