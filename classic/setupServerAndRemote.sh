IMAGE_TAG="ssh-tunnel"
DEBUGLVL=${DEBUGLVL:=0}
SSH_PORT=${SSH_PORT:=22}
# publish port 22 to port 22 of host (for ssh)
# and also port 80 for webserver

DOCKER_OPTIONS="-dit --rm -u testuser"

function evaldbg {
    if [ $DEBUGLVL -ge 2 ]; then
        echo "Debug: Executing '${1}'"
    fi
    eval $1
    return $?
}

# stop/delete containers if they were already running
CONTAINER="ssh-server"
evaldbg "docker ps | grep ${CONTAINER}"
if [ $? -eq 0 ]; then
    echo "Stopping container: ${CONTAINER}"
    evaldbg "docker stop ${CONTAINER} -t 0"
fi
CONTAINER="ssh-remote"
evaldbg "docker ps | grep ssh-remote"
if [ $? -eq 0 ]; then
    echo "Stopping container: ${CONTAINER}"
    evaldbg "docker stop ${CONTAINER} -t 0"
fi

# start containers
docker run ${DOCKER_OPTIONS}  -p ${SSH_PORT}:${SSH_PORT} --name ssh-server ${IMAGE_TAG}
docker run ${DOCKER_OPTIONS} --name ssh-remote ${IMAGE_TAG}
