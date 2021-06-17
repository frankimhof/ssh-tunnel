if test -f ~/.ssh/id_rsa; then
  echo "id_rsa.pub already created"
else
#generate keys
echo "creating new rsa identity keys..."
ssh-keygen -t rsa -f ~/.ssh/id_rsa -N "" -q
fi
