#!/bin/bash
if [ -f /already -a "${OK}X" = "X" ]; then
  while true; do
    sleep 30
  done
fi
touch /already
# set up the shared data path while running as root
if [ "${shared_top}" ] ; then
  mkdir -p $(dirname ${shared_top})
  ln -sf /sharedData ${shared_top}
fi
# copy hadoop and spark configurations
export HADOOP_CONF_DIR=/conf/hadoop
export SPARK_CONF_DIR=/conf/spark
echo "export SPARK_DIST_CLASSPATH=$(hadoop classpath)" >> ${SPARK_HOME}/conf/spark-env.sh
# set up environment for running as requesting user
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
# run requested command (normally e2e.sh)
exec /usr/local/bin/gosu ${USERNAME} $@

