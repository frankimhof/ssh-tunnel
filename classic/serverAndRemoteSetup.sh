IMAGE_TAG="ssh-tunnel"
USER="testuser"
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
# create identity keys for the ssh-server container
evaldbg "docker exec -u ${USER} ssh-server /bin/sh -c 'ssh-keygen -t rsa -f ~/.ssh/ssh_host_rsa_key -N \"\" -q'"
if [[ $? -eq 0 ]]; then
    echo "### [ OK ] ### identity keys generated!!!"
else
    echo "### [FAIL] ### Error while starting the ssh server"
fi

# start ssh server in the ssh-server container
evaldbg "docker exec -u ${USER} ssh-server /bin/sh -c '/usr/sbin/sshd -f sshd_config'"
if [[ $? -eq 0 ]]; then
    echo "### [ OK ] ### Setup of ssh-server was successfull."
else
    echo "### [FAIL] ### Error while starting the ssh server"
fi

# WEBSERVER SETUP (ssh-remote)
# create folders and give rights to ${USER}
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
echo "### Setting up the webserver in the ssh-remote container..."
evaldbg "docker exec -t ssh-remote /usr/sbin/lighttpd -f /home/${USER}/lighttpd.conf"
if [[ $? -eq 0 ]]; then
    echo "### [ OK ] ### Set up of webserver was successfull."
else
    echo "### [FAIL] ### Error while starting the ssh server"
fi
