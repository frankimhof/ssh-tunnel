SIG_NAME=rsa
#HOST_KEY_FILE=~/.ssh/ssh_host_rsa_key
HOST_KEY_FILE=~/.ssh/id_rsa
ssh-keygen -t rsa -f ${HOST_KEY_FILE} -N "" -q
/usr/sbin/sshd -f sshd_config
