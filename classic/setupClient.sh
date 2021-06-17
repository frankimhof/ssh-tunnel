IMAGE_TAG="ssh-tunnel"
PORT=${PORT:=22}
DOCKER_OPTIONS="-dit --rm -u testuser -p ${PORT}"
DEBUGLVL=${DEBUGLVL:=0}

function evaldbg {
    if [ $DEBUGLVL -ge 2 ]; then
        echo "Debug: Executing '${1}'"
    fi
    eval $1
    return $?
}

# stop/delete container if it was already running
CONTAINER="ssh-client"
evaldbg "docker ps | grep ${CONTAINER}"
if [ $? -eq 0 ]; then
    echo "Stopping container: ${CONTAINER}"
    evaldbg "docker stop ${CONTAINER} -t 0"
fi

# start container
docker run ${DOCKER_OPTIONS} --name ssh-client ${IMAGE_TAG}
