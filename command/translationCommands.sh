#? Commands to do translation. These commands are still in very early stages.
#R:json
#R:encoding

_TRANS_MAPPING_FILE=$_QFIG_LOC/translationMappingFile
[ ! -f $_TRANS_MAPPING_FILE ] && touch $_TRANS_MAPPING_FILE || :
eval $(awk -F '=' 'BEGIN { s="declare -g -A _TRANS_MAPPING;" } {
    if (NF >= 2) {
        split($2, parts, "#");
        s = s "_TRANS_MAPPING[" $1 "]=\"" parts[1] " " parts[2] " " parts[3] "\";";
    }
} END { print s }' $_TRANS_MAPPING_FILE)

function bdts() { #? Translate use Baidu Fanyi api. Sample usage: bdts hello
    [[ -z $1 ]] && logError "Sample usage: bdts hello" && return 1
    [ -z "${_TRANS_MAPPING[baidu]}" ] && logError "Run 'qmap translation' to add a mapping in form baidu=appId#key.
  For appId, key, please refer to Baidu Fanyi open platform."  && return
    declare -a mapping=($(echo ${_TRANS_MAPPING[baidu]}))
    declare -i arrayBase=$(getArrayBase)
    local q api appId key salt sign url response result u from to text
    text=$@
    api="https://fanyi-api.baidu.com/api/trans/vip/translate"
    appId=${mapping[$((arrayBase))]}
    key=${mapping[$((arrayBase + 1))]}

    u=$(chr2ucp ${text:0:1})
    if [[ 0x$u -ge 0x41 && 0x$u -le 0x5A ]] || [[ 0x$u -ge 0x61 && 0x$u -le 0x7A ]]; then
        from="en"
        to="zh"
    else
        from="zh"
        to="en"
    fi
    salt=$RANDOM
    sign=$(echo -n "$appId$text$salt$key" | md5x)
    q=$(enurlp $text)
    url="$api?q=$q&from=$from&to=$to&appid=$appId&salt=$salt&sign=$sign"
    response=$(echoe "$(curl -s $url)")

    +outputTransResult "$response" "trans_result.0.dst"
}


function ggts() { #? Translate use Google Cloud Translation api. Sample usage: ggts hi
    [[ -z $1 ]] && logError "Sample usage: ggts hello" && return 1
    if ! type gcloud >/dev/null 2>&1; then
        logError "\e[1mgcloud\e[0m CLI is required! Install from https://cloud.google.com/sdk/docs/install" && 
        if [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
            echoe "  \e[1mNOTE\e[0m that you should choose the Windows version"
        fi
        return 1
    elif ! isExportedVar GOOGLE_APPLICATION_CREDENTIALS; then
        logError "Please export enviroment variable \e[1mGOOGLE_APPLICATION_CREDENTIALS\e[0m as path of your private key file" && return 1
    fi

    local u source target text
    text=$@
    u=$(chr2ucp ${text:0:1})
    if [[ 0x$u -ge 0x41 && 0x$u -le 0x5A ]] || [[ 0x$u -ge 0x61 && 0x$u -le 0x7A ]]; then
        source="en"
        target="zh"
    else
        source="zh"
        target="en"
    fi

    local data response result
    data="{\"q\":\"$text\",\"source\":\"$source\",\"target\":\"$target\",\"format\":\"text\"}"

    response=$(curl -s -X POST \
    -H "Authorization: Bearer $(gcloud auth application-default print-access-token)" \
    -H "Content-Type: application/json; charset=utf-8" \
    -d "$data" \
    "https://translation.googleapis.com/language/translate/v2")

    +outputTransResult "$response" "data.translations.0.translatedText"
}

function +outputTransResult() { #x
    local response="$1"
    local resultPath="$2"
    result=$(jsonget -t "$response" "$resultPath")
    if [ $? -eq 0 ]; then
        echo "$result"
    else
        logError "Something wrong:"
        echo "$response"
    fi
}