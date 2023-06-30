#? Commands to operate network.

#? If unable to visit website by domain, flush the dns cache, if useless, swith to google or other public dns

function flushdnscache() { #? flush dns cache
    if which dscacheutil >/dev/null && which killall >/dev/null; then
        if sudo dscacheutil -flushcache && sudo killall -HUP mDNSResponder; then

            logSuccess "DNS cache just been flushed (using command \e[1mdscacheutil\e[0m and \e[1mkillall\e[0m)"
        fi
    else
        logError "Your device is temporarily not support"
    fi
}