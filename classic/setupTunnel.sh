USER="testuser"
PASSWD="abcd"
SSH_ID_PATH=/home/testuser/.ssh
docker exec -it ssh-client /bin/sh ./createIdentityKeys.sh
docker exec -it ssh-server /bin/sh ./startServer.sh
docker exec -it ssh-remote /bin/sh ./startServer.sh

CLIENTIP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' ssh-client)
SERVERIP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' ssh-server)
REMOTEIP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' ssh-remote)

echo "ssh-client ip: ${CLIENTIP}"
echo "ssh-server ip: ${SERVERIP}"
echo "ssh-remote ip: ${REMOTEIP}"

docker exec --user ${USER} -t ssh-client sshpass -p abcd ssh-copy-id ${USER}@${SERVERIP} -o StrictHostKeyChecking=no
#docker exec --user ${USER} -t ssh-client sshpass -p abcd ssh-copy-id ${USER}@${REMOTEIP} -o StrictHostKeyChecking=no
docker exec --user ${USER} -t ssh-server sshpass -p abcd ssh-copy-id ${USER}@${REMOTEIP} -o StrictHostKeyChecking=no

#docker exec --user ${USER} -t ssh-client /bin/bash -c "cat ${SSH_ID_PATH}/id_rsa.pub | sshpass -p ${PASSWD} ssh ${USER}@${SERVERIP} 'cat >> .ssh/authorized_keys; exit 0'"
#docker exec --user ${USER} -t ssh-server /bin/bash -c "cat ${SSH_ID_PATH}/id_rsa.pub | sshpass -p ${PASSWD} ssh ${USER}@${ENDPOINTIP} 'cat >> .ssh/authorized_keys; exit 0'"

# WEBSERVER SETUP
# create folders and give rights to ${USERS}
docker exec -u root -t ssh-remote /bin/sh -c "mkdir /var/run/lighttpd && chown -R ${USER}:${USER} /var/run/lighttpd"
docker exec -u root -t ssh-remote /bin/sh -c "mkdir -p /var/www/webserver/html && chown -R ${USER}:${USER} /var/www/webserver"
docker exec -u root -t ssh-remote /bin/sh -c "chown -R ${USER}:${USER} /var/log/lighttpd"
docker exec -u root -t ssh-remote /bin/sh -c "cp /etc/lighttpd/lighttpd.conf lighttpd.conf && chown ${USER}:${USER} lighttpd.conf"
# change lighttpd.conf such that
# -html files will be located at /var/www/webserver/html
# -log files will be located at /var/log/lighttpd
# -lighttpd.pid file will be located in /var/run/lighttpd/
docker exec -t ssh-remote /bin/sh -c "sed -i 's/\/run\/lighttpd.pid/\/var\/run\/lighttpd\/lighttpd.pid/' lighttpd.conf"
docker exec -t ssh-remote /bin/sh -c "sed -i 's/\/var\/www\/localhost/\/var\/www\/webserver/' lighttpd.conf"
docker exec -t ssh-remote /bin/sh -c "sed -i 's/htdocs/html/' lighttpd.conf"
docker exec -t ssh-remote /bin/sh -c "sed -i '42s/^/#/' lighttpd.conf" #comment out the inclusion of mime-types.conf

# create the simple html file
docker exec -t ssh-remote /bin/sh -c "echo 'Congrats, you reached the webpage of the remote webserver!' > /var/www/webserver/html/index.html"
# run the webserver
docker exec -t ssh-remote /usr/sbin/lighttpd -f /home/${USER}/lighttpd.conf

# create an ssh tunnel to the server. Forward local port 80 to remote port 80, enabling the client to reach the webpage at REMOTEIP:80.
docker exec -t ssh-client ssh -fNT -L ${CLIENTIP}:80:${REMOTEIP}:80 ${USER}@${SERVERIP}

# entering the ssh-client container
docker exec -it ssh-client /bin/sh
