alias dstop='docker stop'
alias dlog='docker logs --tail 200 --follow --timestamps'
alias dps="docker ps | awk 'BEGIN{lines=-1;} {lines++; print $0} END{print "Total " lines " containers";}'"

function dbash() {
    [ -z "$1" ] && return
    docker exec -it $1 bash
}
