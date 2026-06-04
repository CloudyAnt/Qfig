function flushdnscache() {
    ipconfig /flushdns
}

function myip() {
    param([string]$Type = "")
    if ($Type -eq "-4" -or $Type -eq "ipv4") {
        try {
            (Invoke-WebRequest -Uri "https://ifconfig.me/ip" -UseBasicParsing -TimeoutSec 5).Content.Trim()
        } catch {
            Write-Host "Failed to get IPv4 address" -ForegroundColor Red
        }
    } elseif ($Type -eq "-6" -or $Type -eq "ipv6") {
        try {
            (Invoke-WebRequest -Uri "https://ifconfig.me/ip" -UseBasicParsing -TimeoutSec 5 -Headers @{"6"="6"}).Content.Trim()
        } catch {
            Write-Host "Failed to get IPv6 address" -ForegroundColor Red
        }
    } else {
        $ipv4 = try { (Invoke-WebRequest -Uri "https://ifconfig.me/ip" -UseBasicParsing -TimeoutSec 5).Content.Trim() } catch { "N/A" }
        Write-Host "IPv4: $ipv4" -ForegroundColor Cyan
        Write-Host "IPv6: Use -6 flag to get IPv6 address" -ForegroundColor Gray
    }
}

function localip() {
    param([string]$Type = "")
    if ($Type -eq "-4" -or $Type -eq "ipv4") {
        $ipv4 = Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -notlike "127.*" -and $_.InterfaceAlias -notlike "Loopback*" } | Select-Object -First 1 -ExpandProperty IPAddress
        if ($ipv4) { Write-Host $ipv4 } else { Write-Host "No IPv4 address found" -ForegroundColor Red }
    } elseif ($Type -eq "-6" -or $Type -eq "ipv6") {
        $ipv6 = Get-NetIPAddress -AddressFamily IPv6 | Where-Object { $_.IPAddress -notlike "::1" -and $_.IPAddress -notlike "fe80:*" } | Select-Object -First 1 -ExpandProperty IPAddress
        if ($ipv6) { Write-Host $ipv6 } else { Write-Host "No IPv6 address found" -ForegroundColor Red }
    } else {
        $ipv4 = Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -notlike "127.*" -and $_.InterfaceAlias -notlike "Loopback*" } | Select-Object -First 1 -ExpandProperty IPAddress
        $ipv6 = Get-NetIPAddress -AddressFamily IPv6 | Where-Object { $_.IPAddress -notlike "::1" -and $_.IPAddress -notlike "fe80:*" } | Select-Object -First 1 -ExpandProperty IPAddress
        Write-Host "IPv4: $($ipv4 ? $ipv4 : 'N/A')" -ForegroundColor Cyan
        Write-Host "IPv6: $($ipv6 ? $ipv6 : 'N/A')" -ForegroundColor Cyan
    }
}
$_SAVED_PROXIES_FILE = "$_QFIG_LOCAL\savedProxies"

# Load saved proxies on script load
if (Test-Path $_SAVED_PROXIES_FILE -PathType Leaf) {
    Get-Content $_SAVED_PROXIES_FILE | ForEach-Object {
        $parts = $_ -split '=', 2
        if ($parts.Count -eq 2 -and $parts[0]) {
            Set-Item -Path "env:$($parts[0])" -Value $parts[1]
        }
    }
}

function shellproxy() { #? operate shell proxies. -p to set shell proxies to a port, -c to clear shell proxies
    $Arg1 = $args[0]
    $Arg2 = $args[1]

    function _saveProxiesToFile {
        @"
ALL_PROXY=$env:ALL_PROXY
http_proxy=$env:http_proxy
https_proxy=$env:https_proxy
ftp_proxy=$env:ftp_proxy
"@ | Set-Content -Path $_SAVED_PROXIES_FILE
    }

    if ([string]::IsNullOrEmpty($Arg1)) {
        logInfo "ALL_PROXY=$env:ALL_PROXY"
        logInfo "http_proxy=$env:http_proxy"
        logInfo "https_proxy=$env:https_proxy"
        logInfo "ftp_proxy=$env:ftp_proxy"
    } elseif ($Arg1 -eq "-p") {
        if ($Arg2 -match '^\d+$') {
            $env:ALL_PROXY = "socks5://127.0.0.1:$Arg2"
            $env:http_proxy = "http://127.0.0.1:$Arg2"
            $env:https_proxy = "http://127.0.0.1:$Arg2"
            $env:ftp_proxy = "http://127.0.0.1:$Arg2"
            _saveProxiesToFile
            logSuccess "Set all proxies to: 127.0.0.1:$Arg2"
        } else {
            logError "Please specify a valid port"
        }
    } elseif ($Arg1 -eq "-c") {
        Remove-Item env:ALL_PROXY -ErrorAction SilentlyContinue
        Remove-Item env:http_proxy -ErrorAction SilentlyContinue
        Remove-Item env:https_proxy -ErrorAction SilentlyContinue
        Remove-Item env:ftp_proxy -ErrorAction SilentlyContinue
        Remove-Item $_SAVED_PROXIES_FILE -ErrorAction SilentlyContinue
        logInfo "Unset all proxies"
    } elseif ($Arg1 -match '([a-zA-Z0-9]+)(\.[a-zA-Z0-9]+)+' -or (confirm "$Arg1 looks not like a valid host, continue?")) {
        $env:ALL_PROXY = "socks5://$Arg1"
        $env:http_proxy = "http://$Arg1"
        $env:https_proxy = "http://$Arg1"
        $env:ftp_proxy = "ftp://$Arg1"
        _saveProxiesToFile
        logSuccess "Set all proxies to: $Arg1"
    }
    Remove-Item function:_saveProxiesToFile -ErrorAction SilentlyContinue
}

function direct() { #? curl directly without proxy
    curl.exe --noproxy '*' @args
}
