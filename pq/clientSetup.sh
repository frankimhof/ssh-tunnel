
if [ $# -lt 1 ]; then
  echo "USAGE: ./clientSetup.sh <SERVER_IP_ADDRESS> <REMOTE_WEBSERVER_CONTAINER_IP_ADDRESS>"
  echo "--> Please provide SERVER_IP_ADDRESS and REMOTE_WEBSERVER_CONTAINER_IP_ADDRESS as argument."
  exit 1
else
  SERVERIP=$1
  REMOTEIP=$2
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
CLIENTIP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' ssh-client)

# generate the clients identity keys
echo "### Generating the identity keys for ssh-client container..."
evaldbg "docker exec -it ssh-client /bin/sh ./createIdentityKeys.sh"
if [[ $? -eq 0 ]]; then
  echo -e "### [ OK ] ###\n\n"
else
    echo "### [FAIL] ### Error while generating identity keys."
fi

# pass the identity keys over to the server (ssh-server container)
echo "### Sending the identity keys to the ssh server..."
evaldbg "docker exec --user ${USER} ssh-client sshpass -p abcd ssh-copy-id ${USER}@${SERVERIP} -o StrictHostKeyChecking=no"
if [[ $? -eq 0 ]]; then
  echo -e "### [ OK ] ###\n\n"
else
  echo "### [FAIL] ### Error while sending identity keys to ssh-server. Is the ssh-server running?\n Is the SERVERIP correct? (${SERVERIP})"
fi

# create an ssh tunnel to the server. Forward local port 80 to remote port 80, enabling the client to reach the webpage at REMOTEIP:80.
echo "### Setting up the ssh tunnel..."
evaldbg "docker exec -t ssh-client ssh -fNT -L ${CLIENTIP}:80:${REMOTEIP}:80 ${USER}@${SERVERIP}"
if [[ $? -eq 0 ]]; then
  echo -e "### [ OK ] ### ssh tunnel successfully set up!\n### Try curl <CLIENT_CONTAINER_IP> to load the webpage from the webserver (which is running in the remote-webserver container).\n### <CLIENT_CONTAINER_IP> = ${CLIENTIP}"
else
  echo -e "### [FAIL] ### Error while setting up the ssh tunnel."
fi

# entering the ssh-client container
docker exec -it ssh-client /bin/sh
