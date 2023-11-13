#? Commands to operate network.

function ps2port() { #? [lsof] get port which listening by process id
	[ -z "$1" ] && logError "Which pid ?" && return 1
	lsof -aPi -p $1
}

function port2ps() { #? [lsof] get process which listening to port
	[ -z "$1" ] && logError "Which port ?" && return 1
	lsof -nP -iTCP -sTCP:LISTEN | grep $1
}

#? If unable to visit website by domain, flush the dns cache, if useless, swith to google or other public dns
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
            logSuccess "Set all proxies to: 127.0.0.1:$2"
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
    else
        export ALL_PROXY=socks5://$1
        export http_proxy=http://$1
        export https_proxy=http://$1
        export ftp_proxy=ftp://$1
        _saveProxiesToFile
        logSuccess "Set all proxies to: $1"
    fi
    unset -f _saveProxiesToFile
}

function curld() { #? [curl] curl directly (--noproxy)
	curl --noproxy '*' $@
}

function ipt() { #? [iptables] simplified iptables ops
    local command=$1
    local port=$2
    if [[ ! -z "$command" && ! "$port" =~ ^[0-9]+$ ]]; then
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