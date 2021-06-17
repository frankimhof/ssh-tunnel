USER="testuser"
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
