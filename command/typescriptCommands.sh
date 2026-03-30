function +ts:tscCheck() { #x
    if [ ! -f "./node_modules/typescript/bin/tsc" ]; then
        logError "TypeScript is not installed. Run 'npm install typescript' first."
        return 1
    fi
}

function tsrun() { #? compile & run a ts file
    if ! +base:checkParams "FileName" "$1" || ! +ts:tscCheck; then return 1; fi
    local filename="$1"
    [[ "$filename" =~ \.ts$ ]] && filename="${filename%.ts}"
    ./node_modules/typescript/bin/tsc "${filename}.ts" && node "${filename}.js"
}

function tscompile() { #? compile a ts file
    if ! +base:checkParams "FileName" "$1" || ! +ts:tscCheck; then return 1; fi
    local filename="$1"
    [[ "$filename" =~ \.ts$ ]] && filename="${filename%.ts}"
    ./node_modules/typescript/bin/tsc "${filename}.ts"
}
