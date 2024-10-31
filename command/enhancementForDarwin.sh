# Enhancements for Darwin (macOS)

#? To check if a file is quarantined, use command 'xattr -l file_path'

function dquarantine() {  #? delete quarantine attr
  [ -z "$1" ] && logError "Specify the path!" || :
  xattr -d com.apple.quarantine $1;
}

alias bstart="brew services start"
alias bstop="brew services stop"
alias brestart="brew services restart"
alias bstatus="brew services list"