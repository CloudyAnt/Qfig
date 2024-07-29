# Enhancements for Darwin (macOS)

function dquarantine() {  # delete quarantine attr
  [ -z "$1" ] && logError "Specify the path!" || :
  xattr -d com.apple.quarantine $1;
}