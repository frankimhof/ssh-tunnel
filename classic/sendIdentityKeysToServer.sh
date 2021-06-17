PORT=${PORT:=22}
if [ $# -lt 1 ]; then
  echo "USAGE: ./sendKeysToServer.sh <SERVER_IP_ADDRESS>"
  echo "--> Please provide SERVER_IP_ADDRESS as argument."
  exit 1
else
  SERVER_IP=$1
fi
ssh-copy-id -p ${PORT} testuser@${SERVER_IP}
