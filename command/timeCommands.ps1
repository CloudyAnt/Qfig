#? Commands about time

function eut {
    #? describe an epoch unix timestamp (default now), -m to indicate a milliseconds
    $millis = $false
    $remaining = @($args)

    if ($remaining.Count -gt 0 -and $remaining[0] -eq '-m') {
        $millis = $true
        if ($remaining.Count -gt 1) {
            $remaining = $remaining[1..($remaining.Count - 1)]
        } else {
            $remaining = @()
        }
    }

    if ($remaining.Count -eq 0 -or [string]::IsNullOrEmpty($remaining[0])) {
        $stamp = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
        Write-Output "Current stamp: $stamp"
        Write-EutDateLines ([DateTimeOffset]::FromUnixTimeSeconds($stamp))
        return
    }

    $arg = $remaining[0]
    if ($arg -notmatch '^[0-9]+$') {
        logError "Not an unix timestamp!"
        return 1
    }

    if ($millis) {
        $stamp = [int64]([math]::Floor([int64]$arg / 1000))
    } else {
        $stamp = [int64]$arg
    }

    $curStamp = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()

    if ($curStamp -eq $stamp) {
        Write-Output "Now"
    } else {
        if ($curStamp -ge $stamp) {
            $s = $curStamp - $stamp
            $str = " before now ($curStamp)"
        } else {
            $s = $stamp - $curStamp
            $str = " from now ($curStamp)"
        }

        $y = 0; $d = 0; $h = 0; $m = 0
        if ($s -ge 60) {
            $m = [math]::Floor($s / 60)
            $s = $s % 60
        }
        if ($m -ge 60) {
            $h = [math]::Floor($m / 60)
            $m = $m % 60
        }
        if ($h -ge 24) {
            $d = [math]::Floor($h / 24)
            $h = $h % 24
        }
        if ($d -ge 365) {
            $y = [math]::Floor($d / 365)
            $d = $d % 365
        }

        $parts = @()
        if ($y -ne 0) { $parts += "$y years" }
        if ($d -ne 0) { $parts += "$d days" }
        if ($h -ne 0) { $parts += "$h hours" }
        if ($m -ne 0) { $parts += "$m minutes" }
        if ($s -ne 0) { $parts += "$s seconds" }

        Write-Output (($parts -join ' ') + $str)
    }

    Write-EutDateLines ([DateTimeOffset]::FromUnixTimeSeconds($stamp))
}

function Write-EutDateLines { #x
    param([DateTimeOffset]$dto)

    $local = $dto.ToLocalTime()
    $offset = $local.ToString("zzz").Replace(":", "")
    $tzLabel = if ([TimeZoneInfo]::Local.IsDaylightSavingTime($local.DateTime)) {
        [TimeZoneInfo]::Local.DaylightName
    } else {
        [TimeZoneInfo]::Local.StandardName
    }
    Write-Output ("LOCAL: {0:yyyy-MM-dd HH:mm:ss} {1} {2}" -f $local.DateTime, $offset, $tzLabel)
    Write-Output ("  GMT: {0:yyyy-MM-dd HH:mm:ss}" -f $dto.UtcDateTime)
}
