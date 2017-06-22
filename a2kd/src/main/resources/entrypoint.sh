#!/bin/bash

# set up the shared data path while running as root
if [ "${shared_top}" ] ; then
  mkdir -p $(dirname "${shared_top}")
  ln -sf /sharedData "${shared_top}"
else
  echo "ERROR: shared_top is not defined!"
  exit 1
fi
# copy hadoop and spark configurations
mkdir /hadoop
mkdir /spark
cp -R /conf/hadoop/* /hadoop
cp -R /conf/spark/* /spark
export HADOOP_CONF_DIR=/hadoop
export SPARK_CONF_DIR=/spark
if [ ! -f /spark/spark-env.sh ]; then
  if [ -f /spark/spark-env.sh.template ] ; then
    cp /spark/spark-env.sh.template /spark/spark-env.sh
  fi
fi
echo "export SPARK_CLASSPATH=\${SPARK_CLASSPATH}:$(hadoop classpath)" >> /spark/spark-env.sh
echo "export SPARK_CLASSPATH=\${SPARK_CLASSPATH}:${shared_top%/}/${ext_classpath}/*" >> /spark/spark-env.sh
echo "export SPARK_CLASSPATH=\${SPARK_CLASSPATH}:${shared_top%/}/${ext_classpath}/classes" >> /spark/spark-env.sh
# set up environment for running as requesting user
export PATH=${SPARK_HOME}/bin:${A2KD_HOME}/bin:${PATH}
USERNAME="${LOCAL_USER_NAME:-9001}"
if grep "^${USERNAME}:" /etc/passwd ; then
  USERNAME="${USERNAME}1"
fi
USER_ID="${LOCAL_USER_ID:-9001}"
GROUPNAME="${LOCAL_GROUP_NAME:-9001}"
if grep "^${GROUPNAME}:" /etc/passwd ; then
  GROUPNAME="${GROUPNAME}1"
fi
GROUP_ID="${LOCAL_GROUP_ID:-9001}"
echo "Starting A2KD With UID: $USERNAME:$USER_ID"
groupadd --gid "${GROUP_ID}" "${GROUPNAME}" 2>/dev/null 
useradd --shell /bin/bash -u $USER_ID -g ${GROUP_ID} -o -c "" -m "${USERNAME}"
export HOME="/home/${USERNAME}"
cd ${HOME}
mkdir .ssh
ssh-keygen -t rsa -f .ssh/id_rsa -N ''
cp .ssh/id_rsa .ssh/authorized_keys
chown -R "${USERNAME}" .ssh
# run requested command (normally a2kd.sh)
exec /usr/local/bin/gosu "${USERNAME}" $@

