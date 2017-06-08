#!/bin/bash
if [ -f /already -a "${OK}X" = "X" ]; then
  while true; do
    sleep 30
  done
fi
touch /already
export PATH=${SPARK_HOME}/bin:${E2E_HOME}/bin:${PATH}
USERNAME=${LOCAL_USER_NAME:-9001}
USER_ID=${LOCAL_USER_ID:-9001}
GROUPNAME=${LOCAL_GROUP_NAME:-9001}
GROUP_ID=${LOCAL_GROUP_ID:-9001}
echo "Starting E2E With UID: $USERNAME:$USER_ID"
groupadd --gid ${GROUP_ID} ${GROUPNAME} 2>/dev/null 
useradd --shell /bin/bash -u $USER_ID -g ${GROUP_ID} -o -c "" -m $USERNAME
export HOME=/home/${USERNAME}
cd $HOME
mkdir .ssh
ssh-keygen -t rsa -f .ssh/id_rsa -N ''
cp .ssh/id_rsa .ssh/authorized_keys
chown -R ${USERNAME} .ssh

exec /usr/local/bin/gosu ${USERNAME} $@

