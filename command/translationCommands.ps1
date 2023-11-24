#? Commands to do translation.
#require encoding
#requiring-end

$_TRANS_MAPPING_FILE="$_QFIG_LOCAL\translationMappingFile"
$_TRANS_MAPPING = @{}
if (Test-Path -PathType Leaf $_TRANS_MAPPING_FILE) {
    Get-Content $_TRANS_MAPPING_FILE | ForEach-Object {
        $lineFields = $_.Split("=")
        if ($lineFields.Length -eq 2) {
            $_TRANS_MAPPING[$lineFields[0]] = $lineFields[1].Split("#")
        }
    }
    Clear-Variable lineFields 2>$1 | Out-Null
} else {
    New-Item $_TRANS_MAPPING_FILE
}
Clear-Variable _TRANS_MAPPING_FILE

function bdts() {
    $s = $args -join " "
    if ([String]::IsNullOrWhiteSpace($s)) {
        return
    }
    if ((-not $_TRANS_MAPPING.ContainsKey("baidu")) -or ($_TRANS_MAPPING["baidu"].Length -lt 2)) {
        logError "Run 'qmap translation' to add a mapping in form baidu=appId#key.
        For appId, key, please refer to Baidu Fanyi open platform."
        return
    }

    $api = "https://fanyi-api.baidu.com/api/trans/vip/translate"
    $appId = $_TRANS_MAPPING["baidu"][0]
    $key = $_TRANS_MAPPING["baidu"][1]

    $u = Convert1Char2Ucp $s.Substring(0, 1) -d
    if (($u -ge 0x41 -and $u -le 0x5A) -or ($u -ge 0x61 -and $u -le 0x7A)) {
        $from = "en"
        $to = "zh"
    } else {
        $from = "zh"
        $to = "en"
    }
    $salt = Get-Random
    $sign = "$appId$s$salt$key" | md5
    $q = [uri]::EscapeUriString($s)
    $url = "${api}?q=$q&from=$from&to=$to&appid=$appId&salt=$salt&sign=$sign"
    $response = Invoke-RestMethod -Uri "$url"

    return $response.trans_result[0].dst
}
