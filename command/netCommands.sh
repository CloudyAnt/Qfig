#? Commands to operate network.

function ps2port() { #? [lsof] get port which listening by process id
	[ -z "$1" ] && logError "Which pid ?" && return 1
	lsof -aPi -p $1
}

function port2ps() { #? [lsof] get process which listening to port
	[ -z "$1" ] && logError "Which port ?" && return 1
	lsof -nP -iTCP -sTCP:LISTEN | grep $1
}

#? If unable to visit website by domain, flush the dns cache, if useless, switch to google or other public dns
function flushdnscache() { #? [dscacheutil, killall] flush dns cache
    if type dscacheutil >/dev/null 2>&1 && type killall >/dev/null 2>&1; then
        if sudo dscacheutil -flushcache && sudo killall -HUP mDNSResponder; then
            logSuccess "DNS cache just been flushed (using command \e[1mdscacheutil\e[0m and \e[1mkillall\e[0m)"
        fi
    else
        logError "This device is temporarily not support"
    fi
}

_SAVED_PROXIES_FILE=$_QFIG_LOCAL/savedProxies
# Load saved proxies
if [ -f "$_SAVED_PROXIES_FILE" ]; then
    eval $(awk -F '=' 'BEGIN { s="" } {
        if (NF >= 2) {
            s = s "export " $1 "=" $2 ";";
        }
    } END { print s }' $_SAVED_PROXIES_FILE)
fi

function shellproxy() { #? operate shell proxies. -p to set shell proxies to a port, -c to clear shell proxies
    function _saveProxiesToFile() {
        echo "ALL_PROXY=$ALL_PROXY" > $_SAVED_PROXIES_FILE
        echo "http_proxy=$http_proxy" >> $_SAVED_PROXIES_FILE
        echo "https_proxy=$https_proxy" >> $_SAVED_PROXIES_FILE
        echo "ftp_proxy=$https_proxy" >> $_SAVED_PROXIES_FILE
    }
    if [ -z $1 ]; then
        logInfo "ALL_PROXY=$ALL_PROXY"
        logInfo "http_proxy=$http_proxy"
        logInfo "https_proxy=$https_proxy"
        logInfo "ftp_proxy=$ftp_proxy"
    elif [ "-p" = $1 ]; then
        if [[ $2 =~ [0-9]+ ]]; then
            export ALL_PROXY=socks5://127.0.0.1:$2
            export http_proxy=http://127.0.0.1:$2
            export https_proxy=http://127.0.0.1:$2
            export ftp_proxy=http://127.0.0.1:$2
            _saveProxiesToFile
            logSuccess "Set all proxies to: \e[1m127.0.0.1:$2\e[0m"
        else
            logError "Please specify a valid port"
        fi
    elif [ "-c" = $1 ]; then
        unset ALL_PROXY
        unset http_proxy
        unset https_proxy
        unset ftp_proxy
        rm $_SAVED_PROXIES_FILE 2>/dev/null
        logInfo "Unset all proxies"
    elif [[ $1 =~ "([a-zA-Z0-9]+)(\.[a-zA-Z0-9]+)+" ]] || confirm "\e[1m$1\e[0m looks not like a valid host, continue?"; then
        export ALL_PROXY=socks5://$1
        export http_proxy=http://$1
        export https_proxy=http://$1
        export ftp_proxy=ftp://$1
        _saveProxiesToFile
        logSuccess "Set all proxies to: \e[1m$1\e[0m"
    fi
    unset -f _saveProxiesToFile
}

#? curl directly without preoxy
alias direct="curl --noproxy '*'"

function ipt() { #? [iptables] simplified iptables ops
    local command=$1
    local port=$2
    if [[ -n "$command" && ! "$port" =~ ^[0-9]+$ ]]; then
        logError "Port should be decimal!" && return 1
    fi
    if [ -z "$command" ]; then
        iptables -L -n --line-numbers
    elif [ "a" = "$command" ]; then
        iptables -A INPUT -p tcp --dport $port -j ACCEPT
        logInfo "Added port $port to INPUT chain."
    elif [ "d" = "$command" ]; then
        iptables -D INPUT -p tcp --dport $port -j ACCEPT
        logInfo "Deleted port $port from INPUT chain."
    fi
}

function myip() { #? get current public ip address
    local type=${1:-""}
    if [ "$type" = "-4" ] || [ "$type" = "ipv4" ]; then
        if command -v curl >/dev/null 2>&1; then
            curl -s -4 ifconfig.me
        elif command -v wget >/dev/null 2>&1; then
            wget -q -O- -4 ifconfig.me
        else
            logError "Neither curl nor wget is available"
            return 1
        fi
    elif [ "$type" = "-6" ] || [ "$type" = "ipv6" ]; then
        if command -v curl >/dev/null 2>&1; then
            curl -s -6 ifconfig.me
        elif command -v wget >/dev/null 2>&1; then
            wget -q -O- -6 ifconfig.me
        else
            logError "Neither curl nor wget is available"
            return 1
        fi
    else
        if command -v curl >/dev/null 2>&1; then
            logInfo "IPv4: $(curl -s -4 ifconfig.me)"
            logInfo "IPv6: $(curl -s -6 ifconfig.me 2>/dev/null || echo 'N/A')"
        elif command -v wget >/dev/null 2>&1; then
            logInfo "IPv4: $(wget -q -O- -4 ifconfig.me)"
            logInfo "IPv6: $(wget -q -O- -6 ifconfig.me 2>/dev/null || echo 'N/A')"
        else
            logError "Neither curl nor wget is available"
            return 1
        fi
    fi
}

function _localipOf() { #x print the first usable ip of family 4 or 6, preferring the default route interface
    local family=$1 dev candidates pattern exclude
    if [ "$family" = 4 ]; then
        pattern='inet [0-9.]+'; exclude='^(127\.|169\.254\.)'
    else
        pattern='inet6 [0-9a-fA-F:]+'; exclude='^(::|fe80:)'
    fi
    if command -v ip >/dev/null 2>&1; then
        dev=$(ip -$family route show default 2>/dev/null | awk '{for (i = 1; i < NF; i++) if ($i == "dev") { print $(i + 1); exit }}')
        [ -n "$dev" ] && candidates=$(ip -$family addr show dev "$dev" 2>/dev/null)
        candidates="$candidates"$'\n'"$(ip -$family addr show)"
    else
        if [ "$family" = 4 ]; then
            dev=$(route -n get default 2>/dev/null | awk '/interface:/ {print $2}')
        else
            dev=$(route -n get -inet6 default 2>/dev/null | awk '/interface:/ {print $2}')
        fi
        [ -n "$dev" ] && candidates=$(ifconfig "$dev" 2>/dev/null)
        candidates=$(echo "$candidates"$'\n'"$(ifconfig)" | /usr/bin/sed 's/[[:cntrl:]]\[[0-9;]*m//g')
    fi
    echo "$candidates" | grep -oE "$pattern" | awk '{print $2}' | grep -viE "$exclude" | head -1
}

function localip() { #? get local network ip address, -4 for ipv4 only, -6 for ipv6 only
    local type=${1:-""}
    if ! command -v ip >/dev/null 2>&1 && ! command -v ifconfig >/dev/null 2>&1; then
        logError "Neither ip nor ifconfig is available"
        return 1
    fi
    if [ "$type" = "-4" ] || [ "$type" = "ipv4" ]; then
        _localipOf 4
    elif [ "$type" = "-6" ] || [ "$type" = "ipv6" ]; then
        _localipOf 6
    else
        logInfo "IPv4: $(_localipOf 4)"
        logInfo "IPv6: $(_localipOf 6)"
    fi
}
