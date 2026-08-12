# Fixing broken config or other critical things
# Please run this script under Qfig repo folder

## Check current repo
if [[ ! "`git rev-parse --is-inside-work-tree 2>&1`" = 'true' || ! "`git remote -v`" =~ .*Qfig.git.* ]]; then
    echo "fatal: this seems not the Qfig repo" && exit 1
fi

## Move config to current, right folder
configFolder="./.local"
mkdir -p $configFolder
config="$configFolder/$config"
if [ -f "./config" ] && [ ! -f "$config" ]; then
    mv ./config $config
    mv *MappingFile $configFolder 2>/dev/null

    echo "√ Moved configs to $configFolder"
fi

## Convert legacy XML-style config to the INI-style format
config="$configFolder/config"
if [ -f "$config" ] && grep -q '<enabledCommands>' "$config"; then
    sed -i.bak \
        -e 's|^[[:space:]]*<enabledCommands>[[:space:]]*$|[enabledCommands]|' \
        -e '/^[[:space:]]*<\/enabledCommands>[[:space:]]*$/d' \
        -e 's|<preferTextEditor>\(.*\)</preferTextEditor>|preferTextEditor=\1|' \
        -e 's|<showVerboseInitMsg>\(.*\)</showVerboseInitMsg>|showVerboseInitMsg=\1|' \
        -e 's|<psTabStyle>\(.*\)</psTabStyle>|psTabStyle=\1|' \
        "$config" && echo "√ Converted $config to the new format (backup: $config.bak)"
fi