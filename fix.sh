# Fixing broken config or other critical things
# Please run this script under Qfig repo folder

## Check current repo
if [ ! "`git rev-parse --is-inside-work-tree 2>&1`" = 'true' ] || [[ ! "`git remote -v`" =~ .*Qfig.git.* ]]; then
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