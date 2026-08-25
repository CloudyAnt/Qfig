#? Commands to do translation.
Get-EnableQcmdsExpr encoding | Invoke-Expression

$_TRANS_MAPPING = qmap translation -c -Output

function bdts() {
    $s = $args -join " "
    if ([String]::IsNullOrWhiteSpace($s)) {
        return
    }
    $baidu = If ($_TRANS_MAPPING.ContainsKey("baidu")) { $_TRANS_MAPPING["baidu"] } Else { "" }
    $creds = If ([string]::IsNullOrWhiteSpace($baidu)) { @() } Else { $baidu.Split("#") }
    if ($creds.Length -lt 2) {
        logError "Run 'qmap translation' to add a mapping in form baidu=appId#key.
        For appId, key, please refer to Baidu Fanyi open platform."
        return
    }

    $api = "https://fanyi-api.baidu.com/api/trans/vip/translate"
    $appId = $creds[0]
    $key = $creds[1]

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

    $response = curl -s "$url"
    $jsonResponse = $response | ConvertFrom-Json

    return $jsonResponse.trans_result[0].dst
}
