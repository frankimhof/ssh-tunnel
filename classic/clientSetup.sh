if [ $# -lt 1 ]; then
  echo "USAGE: ./clientSetup.sh <SERVER_IP_ADDRESS> <REMOTE_WEBSERVER_CONTAINER_IP_ADDRESS>"
  echo "--> Please provide SERVER_IP_ADDRESS and REMOTE_WEBSERVER_CONTAINER_IP_ADDRESS as argument."
  exit 1
else
  SERVER_IP=$1
  REMOTE_IP=$2
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
CONTAINER_NAME="ssh-client"
evaldbg "docker ps | grep ${CONTAINER_NAME}"
if [ $? -eq 0 ]; then
    echo "Stopping container: ${CONTAINER_NAME}"
    evaldbg "docker stop ${CONTAINER_NAME} -t 0"
fi

# start the client container
docker run ${DOCKER_OPTIONS} --name ${CONTAINER_NAME} ${IMAGE_TAG}
CLIENT_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' ${CONTAINER_NAME})

# generate the clients identity keys
echo "### Generating the identity keys for ${CONTAINER_NAME} container..."
evaldbg "docker exec -it ${CONTAINER_NAME} /bin/sh ./createIdentityKeys.sh"
if [[ $? -eq 0 ]]; then
  echo -e "### [ OK ] ###\n\n"
else
    echo "### [FAIL] ### Error while generating identity keys."
fi

# pass the identity keys over to the server (ssh-server container)
echo "### Sending the identity keys to the ssh server..."
evaldbg "docker exec -it -u ${USER} ${CONTAINER_NAME} sshpass -p ${PASSWORD} ssh-copy-id ${USER}@${SERVER_IP} -o StrictHostKeyChecking=no"
if [[ $? -eq 0 ]]; then
  echo -e "### [ OK ] ###\n\n"
else
  echo "### [FAIL] ### Error while sending identity keys to ssh-server. Is the ssh-server running?\n Is the SERVER_IP correct? (${SERVER_IP})"
fi

# create an ssh tunnel to the server. Forward local port 80 to remote port 80, enabling the client to reach the webpage at REMOTE_IP:80.
echo "### Setting up the ssh tunnel..."
evaldbg "docker exec -t ${CONTAINER_NAME} ssh -fNT -L ${CLIENT_IP}:80:${REMOTE_IP}:80 ${USER}@${SERVER_IP}"
if [[ $? -eq 0 ]]; then
  echo -e "### [ OK ] ###\n\n"
  echo -e "================================================================================"
  echo -e "ssh tunnel (local port forwarding) successfully set up!\n"
  echo -e "[${CONTAINER_NAME}]:80 was forwarded to [remote-webserver]:80"
  echo -e "--------------------------------------------------------------------------------"
  echo -e "Use one of the following options to reach the webserver and load the web page:"
  echo -e "--> (on this machine): open up a webbrowser and visit localhost"
  echo -e "--> (on this machine): curl localhost"
  echo -e "--> (inside the [${CONTAINER_NAME}] container): curl ${CLIENT_IP}'\n"
  echo -e "================================================================================"
else
  echo -e "### [FAIL] ### Error while setting up the ssh tunnel."
fi
