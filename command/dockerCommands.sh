alias dstart='docker start'
alias dstop='docker stop'
alias dlog='docker logs --tail 200 --follow --timestamps'
alias dps='docker ps'
alias dpsa='docker ps -a'
#alias dps="docker ps | awk 'BEGIN{lines=-1;} {lines++; print $0} END{print \"Total \" lines \" containers\";}'"
#alias dpsa="docker ps -a | awk 'BEGIN{lines=-1;} {lines++; print $0} END{print \"Total \" lines \" containers\";}'"
alias dis="docker images"
alias dcs="docker container ls"
alias dcsa="docker container ls -a"
alias drun="docker run"

function dbash() { #? enter docker bash
    docker exec -it $1 bash
}


function dcrm() { #? delete container by id
    [ -z "$1" ] && return
    docker container rm $1
}
