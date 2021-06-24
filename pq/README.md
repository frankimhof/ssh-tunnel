# ssh-tunnel (local port forwarding)
The following is an instruction to create and test an ssh-tunnel (using [open-quantum-safe/openssh](https://github.com/open-quantum-safe/openssh)).
The Dockerfile was taken from [fhnw-ise-qcrypt/oqs-demos/tree/benchmark/openssh](https://github.com/fhnw-ise-qcrypt/oqs-demos/tree/main/openssh).

# Prerequisites
1. For this experiment, two machines are required, one for running the ssh-server and one for running the ssh-client. For clarity, the two machines will be called machine **A** and machine **B**.
2. [Docker](https://www.docker.com/) must be installed on both machines.

# Installation
Clone the repository and build the image on both machines **A** and **B**.
## Clone the repository
clone this repository and cd into the `pq` directory using the following commands.
```
git clone --depth 1 --branch main https://github.com/frankimhof/ssh-tunnel.git
cd ssh-tunnel/pq/
```

## Build the docker image
Assuming we are in `/ssh-tunnel/pq`\
Build the docker image using the following command (don't forget the point at the end)
```
docker build --build-arg MAKE_INSTALL=install -t oqs-openssh-img .
```
the option -t is used to give the image a name (in this case **ssh-tunnel**).\
After a successfull build, the image **oqs-openssh-img** should show up when issueing the following command
```
docker images
```

# Start the containers
Start the ssh-server and the webserver on machine **A**. Then, start the ssh-client on machine **B**.

## Start the ssh-server and the remote-webserver on machine A
**IMPORTANT**: Make sure that port 2222 is not already in use.\
\
Assuming we are in `/ssh-tunnel/pq` on machine **A**
```
./serverAndRemoteSetup.sh
```
This script will start two containers:
1. **oqs-openssh-server**:\
It is running an ssh-server (on port 2222).\
The port 2222 of the container is mapped to port 2222 of machine **A**.
2. **remote-webserver**:\
It is running a simple webserver (on port 80) (using [lighttpd](https://www.lighttpd.net/))

Notice the **\<REMOTE\_WEBSERVER\_CONTAINER\_IP\>** that is printed out in the end. It will be used in the next step.

If the script ran successfully, the containers will show up when issueing the following command
```
docker ps
```

## Start the ssh-client on machine B
**IMPORTANT**: Make sure that port 80 is not already in use.\
\
Assuming we are in `/ssh-tunnel/pq` on machine **B**
```
./clientSetup.sh <SSH_SERVER_IP> <REMOTE_WEBSERVER_CONTAINER_IP>
```
Replace **\<SSH\_SERVER\_IP\>** with the IP address of machine **A**.\
Replace **\<REMOTE\_WEBSERVER\_CONTAINER\_IP\>** with the IP address of the **remote-webserver**, which was obtained in the last step.

This script will start the **ssh-client** container and establish the ssh-tunnel.

# Use the tunnel
The ssh-tunnel allows machine **A** to reach the remote webserver (running on machine **B**) by calling localhost:80.\
Use one of the following options to test whether the tunnel works (if so, the web page should load successfully):
1. open up [localhost](http://localhost) on machine **B**
2. run the following command on machine **B**
```
curl localhost
```
