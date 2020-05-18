function odstart() {
        sudo /data/script/start.sh $1
}

function dstop() {
    docker stop $1
}

function dlog() {
    docker logs --tail 200 --follow --timestamps $1
}

function odps() {
    docker ps | awk 'BEGIN{lines=-1;} {lines++; print $0} END{print "Total " lines " containers";}'
}

function dbash() {
    docker exec -it $1 bash
}
