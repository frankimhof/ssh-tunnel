FROM alpine:3.11 as dev
RUN apk update && apk upgrade

ARG USER_NAME="testuser"
ARG USER_PASSWD="abcd"

RUN addgroup --gid 1000 --system ${USER_NAME} && adduser --uid 1000 --system ${USER_NAME} --ingroup ${USER_NAME} --shell /bin/sh && echo -e -e "${USER_PASSWD}\n${USER_PASSWD}" | passwd ${USER_NAME}

WORKDIR /home/${USER_NAME}/.ssh
RUN chown ${USER_NAME}:${USER_NAME} .

RUN apk add openssh openrc openssh-server-pam sshpass lighttpd curl\
  && mkdir -p /run/openrc \
  && touch /run/openrc/softlevel \
  && rc-update add sshd \
  && rc-status

# give user access to start sshd
# RUN chown ${USER_NAME}:${USER_NAME} /etc/init.d/sshd

WORKDIR /home/${USER_NAME}
# copy original sshd config
RUN cp /etc/ssh/sshd_config .
# and change it to allow TCP port forwarding (used for tunneling)
RUN sed -i "s/AllowTcpForwarding no/AllowTcpForwarding yes/" sshd_config
# server can then be started by calling ./start_server.sh which runs /usr/sbin/sshd -f /home/testuser/sshd_config

# change host key path
RUN sed -i "s/#HostKey \/etc\/ssh\/ssh_host_rsa_key/HostKey ~\/.ssh\/id_rsa/" sshd_config
#RUN sed -i "s/#HostKey \/etc\/ssh\/ssh_host_rsa_key/HostKey ~\/.ssh\/ssh_host_rsa_key/" sshd_config

# set UsePAM, otherwise we can't connect
RUN sed -i "s/#UsePAM no/UsePAM yes/" sshd_config

COPY startServer.sh .
COPY createIdentityKeys.sh .
COPY sendIdentityKeysToServer.sh .

STOPSIGNAL SIGTERM
WORKDIR /home/${USER_NAME}/
CMD ["/bin/sh"]
