function tsrun() {
    if ! +base:checkParams "FileName" "$1"; then return 1; fi
    ./node_modules/typescript/bin/tsc "$1.ts" && node "$1.js"
}
