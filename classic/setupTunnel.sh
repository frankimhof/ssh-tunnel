USER="testuser"
PASSWD="abcd"
SSH_ID_PATH=/home/testuser/.ssh
docker exec -it ssh-server /bin/sh ./startServer.sh #start an ssh server in the ssh-server container (and also generate identity keys)
docker exec -it ssh-remote /bin/sh ./startServer.sh #start an ssh server in the ssh-remote container (and also generate identity keys)

# get the ip addresses of the containers
CLIENTIP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' ssh-client)
SERVERIP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' ssh-server)
REMOTEIP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' ssh-remote)

echo "ssh-client ip: ${CLIENTIP}"
echo "ssh-server ip: ${SERVERIP}"
echo "ssh-remote ip: ${REMOTEIP}"

# copy the ssh identity keys of the ssh-client container to the ssh-server container
docker exec --user ${USER} -t ssh-client sshpass -p abcd ssh-copy-id ${USER}@${SERVERIP} -o StrictHostKeyChecking=no
# copy the ssh identity keys of the ssh-server container to the ssh-remote container
docker exec --user ${USER} -t ssh-server sshpass -p abcd ssh-copy-id ${USER}@${REMOTEIP} -o StrictHostKeyChecking=no

#docker exec --user ${USER} -t ssh-client sshpass -p abcd ssh-copy-id ${USER}@${REMOTEIP} -o StrictHostKeyChecking=no
#docker exec --user ${USER} -t ssh-client /bin/bash -c "cat ${SSH_ID_PATH}/id_rsa.pub | sshpass -p ${PASSWD} ssh ${USER}@${SERVERIP} 'cat >> .ssh/authorized_keys; exit 0'"
#docker exec --user ${USER} -t ssh-server /bin/bash -c "cat ${SSH_ID_PATH}/id_rsa.pub | sshpass -p ${PASSWD} ssh ${USER}@${ENDPOINTIP} 'cat >> .ssh/authorized_keys; exit 0'"


