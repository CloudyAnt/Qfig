# Enhancement for cygwin

REFRESH_QFIG_DEFINE=$(declare -f refresh-qfig)
REFRESH_QFIG_DEFINE=${REFRESH_QFIG_DEFINE//refresh-qfig ()/++refresh-qfig ()}
eval "$REFRESH_QFIG_DEFINE"

function refresh-qfig() {
  ql="$QFIG_LOC"
  peerLoc="$ql/peer"
  if [ -d "$peerLoc" ]; then
    rm -rf "$peerLoc"
    mkdir "$peerLoc";
    cp -r "$ql/command" "$ql/script" "$ql/init.sh" "$ql/configTemplate" "$ql/activation.sh" "$peerLoc";
  fi
  ++refresh-qfig # call the original function
}
