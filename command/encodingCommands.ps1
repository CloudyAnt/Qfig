#? Encodings related commands

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
    # Use UTF-32 to iterate by code point rather than UTF-16 code unit,
    # so surrogate pairs (e.g. emojis) are kept together.
    $utf32bytes = [System.Text.Encoding]::UTF32.GetBytes($str)
    for ($i = 0; $i -lt $utf32bytes.Length; $i += 4) {
        $intucp = [System.BitConverter]::ToUInt32($utf32bytes, $i)
        $ucp = "$prefix$($intucp.ToString("X"))"
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
    param([string]$char, [switch]$decimal)

    $utf32bytes = [System.Text.Encoding]::UTF32.GetBytes($char)
    $intucp = [System.BitConverter]::ToUint32($utf32bytes)
    if ($decimal) {
        return $intucp
    }
    return $intucp.ToString("X")
}