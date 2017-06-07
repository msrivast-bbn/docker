#!/bin/bash
set -xv

UI=" -e LOCAL_USER_ID=$(id -u)"
UN=" -e LOCAL_USER_NAME=$(id -un)"
GI=" -e LOCAL_GROUP_ID=$(id -g)"
GN=" -e LOCAL_GROUP_NAME=$(id -gn)"
V1=" -v ${HOME}/conf/hadoop:/etc/hadoop/conf.shared"
V2=" -v ${HOME}/conf/spark:/var/lib/spark-2.0.0-hadoop2.6/conf"
V3=" -v /nfs/mercury-04/u40:/sharedData"
P1=" -p 4040:4040"
if [ $# -le 1 ]; then
  sudo docker run -it $UI $UN $GI $GN $V1 $V2 $V3 $P1 deft/e2e:2.7.1-SNAPSHOT bash
else
  sudo docker run -it $UI $UN $GI $GN $V1 $V2 $V3 $P1 deft/e2e:2.7.1-SNAPSHOT $@
fi

