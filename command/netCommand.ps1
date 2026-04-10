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