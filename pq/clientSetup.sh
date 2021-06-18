if [ $# -lt 1 ]; then
  echo "USAGE: ./clientSetup.sh <SERVER_IP_ADDRESS> <REMOTE_WEBSERVER_CONTAINER_IP_ADDRESS>"
  echo "--> Please provide SERVER_IP_ADDRESS and REMOTE_WEBSERVER_CONTAINER_IP_ADDRESS as argument."
  exit 1
else
  SERVER_IP=$1
  REMOTE_IP=$2
fi

USER="oqs"
PASSWORD="oqs.pw"
SIG_ALG="ssh-dilithium2"
KEM_ALG="kyber-512-sha384@openquantumsafe.org"
SSH_ID_PATH="/home/oqs/.ssh"

PORT=${PORT:=2222}
IMAGE_TAG="oqs-openssh-img"
DOCKER_OPTIONS="-dit --rm --user ${USER} -e SKIP_KEYGEN=YES -p ${PORT}:${PORT} -p 80:80"
DEBUGLVL=${DEBUGLVL:=0}

function evaldbg {
    if [ $DEBUGLVL -ge 2 ]; then
        echo "Debug: Executing '${1}'"
    fi
    eval $1
    return $?
}

# stop/delete container if it was already running
CONTAINER_NAME="oqs-openssh-client"
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
evaldbg "docker exec -it -u ${USER} ${CONTAINER_NAME} ssh-keygen -t ${SIG_ALG//_/-} -f ${SSH_ID_PATH}/id_${SIG_ALG//-/_} -N \"\" -q"
if [[ $? -eq 0 ]]; then
  echo -e "### [ OK ] ###\n\n"
else
    echo "### [FAIL] ### Error while generating identity keys."
    exit 1
fi

# pass the identity keys over to the server (oqs-openssh-server container)
echo "### Sending the identity keys to the ssh server..."
SSH_OPTS="-p ${PORT} \
  -o StrictHostKeyChecking=no \
  -o KexAlgorithms=${KEM_ALG}"
evaldbg "docker exec -u oqs -t ${CONTAINER_NAME} bash -c \"cat ${SSH_ID_PATH}/id_${SIG_ALG//-/_}.pub | sshpass -p ${PASSWORD} ssh ${SSH_OPTS} ${USER}@${SERVER_IP} 'cat >> .ssh/authorized_keys; exit 0'\""
if [[ $? -eq 0 ]]; then
  echo -e "### [ OK ] ###\n\n"
else
  echo "### [FAIL] ### Error while sending identity keys to ssh-server. Is the ssh-server running?\n Is the SERVER_IP correct? (${SERVER_IP})"
  exit 1
fi

echo "Testing the keys..."
SSH_OPTS="-p 2222 \
  -o StrictHostKeyChecking=no \
  -o Batchmode=yes \
  -o PubkeyAcceptedKeyTypes=${SIG_ALG//_/-} \
  -i ${SSH_ID_PATH}/id_${SIG_ALG//-/_} \
  -o KexAlgorithms=${KEM_ALG}"

evaldbg "docker exec -u oqs -it ${CONTAINER_NAME} ssh ${SSH_OPTS} ${USER}@${SERVER_IP} 'exit 0'"
if [[ $? -eq 0 ]]; then
  echo -e "### [ OK ] ###\n\n"
else
  echo "### [FAIL] ### Error while testing KEY"
  exit 1
fi

# create an ssh tunnel to the server. Forward local port 80 to remote port 80, enabling the client to reach the webpage at REMOTEIP:80.
echo "### Setting up the ssh tunnel..."
evaldbg "docker exec -u oqs -it ${CONTAINER_NAME} ssh ${SSH_OPTS} -fNT -L ${CLIENT_IP}:80:${REMOTE_IP}:80 ${USER}@${SERVER_IP}"
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
  exit 1
fi
