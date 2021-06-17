if [ $# -lt 1 ]; then
  echo "USAGE: ./clientSetup.sh <SERVER_IP_ADDRESS>"
  echo "--> Please provide SERVER_IP_ADDRESS as argument."
  exit 1
else
  SERVER_IP=$1
fi

USER="testuser"
PASSWORD="abcd"
PORT=${PORT:=22}
IMAGE_TAG="ssh-tunnel"
DOCKER_OPTIONS="-dit --rm -u testuser -p ${PORT}:${PORT}"
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

# start the client container
docker run ${DOCKER_OPTIONS} --name ssh-client ${IMAGE_TAG}
# generate the clients identity keys
docker exec -it ssh-client /bin/sh ./createIdentityKeys.sh
# pass the identity keys over to the server (ssh-server container)
docker exec --user ${USER} ssh-client sshpass -p abcd ssh-copy-id ${USER}@${SERVER_IP} -o StrictHostKeyChecking=no
