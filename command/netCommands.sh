#? Commands to operate network

function flushdnscache() { #? flush dns cache
    if which dscacheutil >/dev/null && which killall >/dev/null; then
        if sudo dscacheutil -flushcache && sudo killall -HUP mDNSResponder; then
            logSuccess "DNS cache just flushed by using command 'dscacheutil' and 'killall'"
        fi
    else
        logError "Your device is temporarily not support"
    fi
}