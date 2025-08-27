#? Commands to do translation. 
enable-qcmds json
enable-qcmds encoding

qmap -c translation _TRANS_MAPPING

function bdts() { #? Translate use Baidu Fanyi api. Sample usage: bdts hello. -v to print verbose response
    # Check for verbose flag
    local verbose=false
    OPTIND=1
	while getopts ":v" opt; do
        case $opt in
			v)
                verbose=true
                ;;
        esac
    done
    shift $((OPTIND-1))

    # Check input
    [[ -z $1 ]] && logError "Sample usage: bdts hello" && return 1
    
    # Check API credentials
    [ -z "${_TRANS_MAPPING[baidu]}" ] && logError "Run 'qmap translation' to add a mapping in form baidu=appId#key.
  For appId, key, please refer to Baidu Fanyi open platform."  && return
    
    # Parse credentials
    toArray "${_TRANS_MAPPING[baidu]}" "#" && declare -a mapping=("${_TEMP[@]}")
    declare -i arrayBase=$(getArrayBase)
    local appId=${mapping[$((arrayBase))]}
    local key=${mapping[$((arrayBase + 1))]}

    # Setup API params
    local text="$@"
    local api="https://fanyi-api.baidu.com/api/trans/vip/translate"
    local salt=$RANDOM
    local sign=$(echo -n "$appId$text$salt$key" | md5x)
    local q=$(enurlp "$text")

    # Detect language
    local u=$(chr2ucp "${text:0:1}")
    local from to
    if [[ 0x$u -ge 0x41 && 0x$u -le 0x5A ]] || [[ 0x$u -ge 0x61 && 0x$u -le 0x7A ]]; then
        from="en"
        to="zh"
    else
        from="zh" 
        to="en"
    fi

    # Make API request
    local url="$api?q=$q&from=$from&to=$to&appid=$appId&salt=$salt&sign=$sign"
    local response=$(echoe "$(curl -s "$url")")

    # Output result
    if [[ "$verbose" == "true" ]]; then
        echo "$response"
    else
        +outputTransResult "$response" "trans_result.0.dst"
    fi
}


function ggts() { #? Translate use Google Cloud Translation api. Sample usage: ggts hi. -v to print verbose response
    # Check for verbose flag
    local verbose=false
    OPTIND=1
	while getopts ":v" opt; do
        case $opt in
			v)
                verbose=true
                ;;
        esac
    done
    shift $((OPTIND-1))

    # Check input
    [[ -z $1 ]] && logError "Sample usage: ggts hello" && return 1

    # Check dependencies
    if ! type gcloud >/dev/null 2>&1; then
        logError "\e[1mgcloud\e[0m CLI is required! Install from https://cloud.google.com/sdk/docs/install" && 
        if [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
            echoe "  \e[1mNOTE\e[0m that you should choose the Windows version"
        fi
        return 1
    elif ! isExportedVar GOOGLE_APPLICATION_CREDENTIALS; then
        logError "Please export environment variable \e[1mGOOGLE_APPLICATION_CREDENTIALS\e[0m and set value to the path of your private key file" && return 1
    fi

    # Detect language
    local text="$@"
    local u=$(chr2ucp "${text:0:1}")
    local source target
    if [[ 0x$u -ge 0x41 && 0x$u -le 0x5A ]] || [[ 0x$u -ge 0x61 && 0x$u -le 0x7A ]]; then
        source="en"
        target="zh"
    else
        source="zh"
        target="en"
    fi

    # Setup API request
    local data="{\"q\":\"$text\",\"source\":\"$source\",\"target\":\"$target\",\"format\":\"text\"}"
    local response=$(curl -s -X POST \
        -H "Authorization: Bearer $(gcloud auth application-default print-access-token)" \
        -H "Content-Type: application/json; charset=utf-8" \
        -d "$data" \
        "https://translation.googleapis.com/language/translate/v2")

    # Output result
    if [[ "$verbose" == "true" ]]; then
        echo "$response"
    else
        +outputTransResult "$response" "data.translations.0.translatedText"
    fi
}

function +outputTransResult() { #x
    local response="$1"
    local resultPath="$2"
    result=$(jsonget -n "$response" "$resultPath")
    if [ $? -eq 0 ]; then
        echo "$result"
    else
        logError "Something wrong:"
        echo "$response"
    fi
}
