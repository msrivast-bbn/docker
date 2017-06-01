#!/bin/bash
source /hadoop_entrypoint.sh
USER_ID=${LOCAL_USER_ID:-9001}
echo "Starting E2E With UID: $USER_ID"
useradd --shell /bin/base -u $USER_ID -o -c "" -m e2e
export HOME=/home/e2e
cd $HOME
mkdir .ssh
ssh-keygen -t rsa -f .ssh/id_rsa -N ''
cp .ssh/id_rsa .ssh/authorized_keys
chown -R e2e .ssh

echo "exec /usr/local/bin/gosu e2e \"$@\""

