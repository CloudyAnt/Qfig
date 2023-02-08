# Docker related commands
# Hint: install colima to get docker runtime if using mac or linux

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
	[ -z "$1" ] && logError "Which one?" && return
    docker exec -it $1 bash
}

function drmi() { #? delete image by id
    [ -z "$1" ] && return
    docker image rm $1
}

function drmc() { #? delete container by id
    [ -z "$1" ] && return
    docker container rm $1
}

function dprune() { #? remove all stopped containders and useless images
	allStoppedContainers=$(docker ps -a -q)
	if [ -z "$allStoppedContainers" ]
	then
		logInfo "No stopped containers"	
	else
		logInfo "Remove stopped containers:"
		docker rm $(docker ps -a -q)
	fi
	logInfo "Remove useless imagess:"
	docker image prune -f
}

function dbt() { #? build docker image with tag using Dockerfile in current folder
	[ -z "$1" ] && logError "What name?" && return
	[ -z "$2" ] && logError "What tag?" && return

	docker build -t $1:$2 .
}
