# kill all containers and prune
docker kill ssh-server
docker kill ssh-client
docker kill ssh-remote
docker system prune

docker run -it -d -u testuser --name ssh-client ssh-test /bin/sh
docker run -it -d -u testuser --name ssh-server ssh-test /bin/sh
docker run -it -d -u testuser --name ssh-remote ssh-test /bin/sh
