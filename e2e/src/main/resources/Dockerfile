FROM ubuntu:xenial

ENV CDH_VERSION=5.11 CDH_MAJOR=5
ENV SPARK_VERSION=2.0.0 HADOOP_VERSION=2.6

ENV SPARK_TGZ=spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz
ENV SPARK_HOME=/var/lib/spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}

ENV PATH=$SPARK_HOME/bin:$PATH JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64 JRE_HOME=${JAVA_HOME}/jre PATH="${JRE_HOME}/bin:${JAVA_HOME}/bin:${PATH}"
ENV E2E_HOME=/var/lib/adept-e2e PATH="${E2E_HOME}/bin:${PATH}"

ADD hadoop_entrypoint.sh /
ADD spark-entrypoint.sh /
ADD spark-historyserver.sh /
ADD spark-master.sh /
ADD spark-historyserver.sh /
ADD entrypoint.sh /

# default version of python is 2.7
# initial installs
RUN apt-get update -y && \
    apt-get upgrade -y  && \
    apt-get install -y apt-utils curl wget python perl libterm-readline-gnu-perl openjdk-8-jdk unzip && \
    echo 'deb http://apt.postgresql.org/pub/repos/apt xenial-pgdg main' >/etc/apt/sources.list.d/postgresql.list && \
    chmod 644 /etc/apt/sources.list.d/postgresql.list && \
    wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - && \
    apt-get update -y && \
    apt-get install -y postgresql-9.6 postgresql-contrib-9.6 postgresql-plpython-9.6 && \
    gpg --keyserver ha.pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 && \
    curl -o /usr/local/bin/gosu -SL "https://github.com/tianon/gosu/releases/download/1.10/gosu-amd64" && \
    curl -o /usr/local/bin/gosu.asc -SL "https://github.com/tianon/gosu/releases/download/1.10/gosu-amd64.asc" && \
    gpg --verify /usr/local/bin/gosu.asc && \
    rm /usr/local/bin/gosu.asc && \
    chmod +x /usr/local/bin/gosu && \
    echo "deb [arch=amd64] http://archive.cloudera.com/cdh${CDH_MAJOR}/ubuntu/xenial/amd64/cdh xenial-cdh${CDH_VERSION} contrib" >>/etc/apt/sources.list.d/cloudera.list && \
    wget --quiet -O - https://archive.cloudera.com/cdh${CDH_MAJOR}/ubuntu/xenial/amd64/cdh/archive.key | apt-key add - && \
    apt-get update -y && \
    apt-get install -y hadoop hadoop-0.20-mapreduce hadoop-client hadoop-hdfs hadoop-mapreduce hadoop-yarn && \
    wget --quiet -O /tmp/${SPARK_TGZ} https://archive.apache.org/dist/spark/spark-${SPARK_VERSION}/${SPARK_TGZ} && \
    wget --quiet -O /tmp/${SPARK_TGZ}.asc https://archive.apache.org/dist/spark/spark-${SPARK_VERSION}/${SPARK_TGZ}.asc && \
    wget --quiet -O - https://archive.apache.org/dist/spark/KEYS | gpg --import - && \
    gpg --verify /tmp/${SPARK_TGZ}.asc && \
    rm /tmp/${SPARK_TGZ}.asc && \
    tar -C /var/lib -xzf /tmp/${SPARK_TGZ} && \
    rm /tmp/${SPARK_TGZ} && \
    chmod a+x /hadoop_entrypoint.sh /spark-entrypoint.sh /spark-historyserver.sh /spark-master.sh /spark-historyserver.sh /entrypoint.sh && \
    echo "export SPARK_DIST_CLASSPATH=$(hadoop classpath)" >> ${SPARK_HOME}/conf/spark-env.sh


# E2E
ADD adept-e2e-${project.version}-bin.zip /tmp/
RUN mkdir -p ${E2E_HOME} && \
    unzip -d ${E2E_HOME} /tmp/adept-e2e-${project.version}-bin.zip && \
    rm -f /tmp/adept-e2e-${project.version}-bin.zip
 
#ENTRYPOINT ["/spark-entrypoint.sh"]
CMD ["bash"]

