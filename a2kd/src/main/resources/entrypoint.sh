#!/bin/bash
# /input contains:
#   /input/partitions - a file containing the number of partitions to use.
#   /input/ddPartitions - a file containing the number of document deduplication partitions to use.
#   /input/config.xml - a file containing the A2KD Configuration.
#   /input/spark.conf - a file containing the Spark properties.
#   /input/languages - a file containing a space-separated list of language codes
# The docker container will have the following volumes:
#   /input - mount to /tmp/input$$ containing the files listed above
#   /output - mount to output directory
#   /{EN|ZH|ES} - mounts to the directories containing input files - the name being a language code
#   /hadoop - a mount to the HADOOP configuration directory
#   /sharedTop - a mount to the shared_top directory
# The following environment variables are defined:
#    LOCAL_USER_ID - the numeric id of the user that invoked runa2kd
#    LOCAL_USER_NAME - the name of the user that invoked runa2kd
#    LOCAL_GROUP_ID -  The numeric id of the current group of the user that invoked runa2kd
#    LOCAL_GROUP_NAME - The name of the current group of the user that invoked runa2kd
#    shared_top - the path to the shared directory on the 'outside', we will recreate that in the container
#    job_timestamp - a (hopefully) unique time-based string
#    job_directory - the path to the job directory - will be under shared_top

echo In entrypoint.sh $job_timestamp

# Some sites use windows ldap for ID, which can introduce spaces into names
USERNAME=$(echo -n "${LOCAL_USER_NAME:-9001}" | tr "[:space:]" "_")
# it is possible a user name already exists. If so, append a '1' - that won't exist
if grep "^${USERNAME}:" /etc/passwd ; then
  USERNAME="${USERNAME}1"
fi
USER_ID="${LOCAL_USER_ID:-9001}"
# Some sites use windows ldap for ID, which can introduce spaces into names
GROUPNAME=$(echo -n "${LOCAL_GROUP_NAME:-9001}" | tr "[:space:]" "_")
if grep "^${GROUPNAME}:" /etc/group ; then
  GROUPNAME="${GROUPNAME}1"
fi
GROUP_ID="${LOCAL_GROUP_ID:-9001}"
echo "Creating User UID: $USERNAME:$USER_ID - $GROUPNAME:$GROUP_ID"
groupadd --gid "${GROUP_ID}" "${GROUPNAME}" 2>/dev/null 
useradd --shell /bin/bash -u $USER_ID -g ${GROUP_ID} -o -c "" -m "${USERNAME}"
export HOME="/home/${USERNAME}"
cd ${HOME}
mkdir .ssh
ssh-keygen -q -t rsa -f .ssh/id_rsa -N ''
cp .ssh/id_rsa .ssh/authorized_keys
chown -R "${USERNAME}" .ssh
chmod 755 .ssh

# set up shared_top so that paths that use it will be valid:
[ ${shared_top:-o#} = 'o#' ] || mkdir -p $(dirname "$shared_top")
[ -d /sharedTop -a "$shared_top:-o#}" != 'o#' ] && ln -s /sharedTop "$shared_top"

# The HADOOP Configuration Directory is mounted at /hadoop. Set the variable.
export HADOOP_CONF_DIR=/hadoop

# set up environment for running as requesting user
export PATH=${SPARK_HOME}/bin:${A2KD_HOME}/bin:${PATH}

# make sure /scripts exist
[ -d /scripts ] || mkdir /scripts && chmod a+rx /scripts

# run any customization scripts we have installed
run-parts /scripts

# run requested command (normally a2kd.sh)
if [ "${1:-x}" == a2kd.sh ]; then
  echo "Starting A2KD With UID: $USERNAME:$USER_ID - $GROUPNAME:$GROUP_ID"
  exec /usr/local/bin/gosu "${USERNAME}" $@ >/tmp/cmd
else
  exec /bin/bash
fi
