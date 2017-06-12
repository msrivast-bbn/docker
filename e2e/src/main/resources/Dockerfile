FROM ubuntu:xenial

ENV CDH_VERSION=5.11 CDH_MAJOR=5 \
    SPARK_VERSION=2.0.0 HADOOP_VERSION=2.6 \
    JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64 \
    E2E_HOME=/var/lib/adept-e2e DEBIAN_FRONTEND=noninteractive
ENV SPARK_TGZ=spark-$SPARK_VERSION-bin-hadoop$HADOOP_VERSION.tgz \
    SPARK_HOME=/var/lib/spark-$SPARK_VERSION-bin-hadoop$HADOOP_VERSION \
    PATH=$E2E_HOME/bin:$SPARK_HOME/bin:$JRE_HOME/bin:$JAVA_HOME/bin:$PATH \
    JRE_HOME=$JAVA_HOME/jre

COPY entrypoint.sh gosu-amd64 spark-2.0.0-bin-hadoop2.6.tgz e2e.sh adept-e2e-bin.zip /

# default version of python is 2.7
# initial installs
RUN apt-get update -y && \
    apt-get upgrade -y  && \
    apt-get install -y apt-utils && \
    apt-get install -y curl wget python perl libterm-readline-gnu-perl openjdk-8-jdk unzip ssh && \
    echo 'deb http://apt.postgresql.org/pub/repos/apt xenial-pgdg main' >/etc/apt/sources.list.d/postgresql.list && \
    chmod 644 /etc/apt/sources.list.d/postgresql.list && \
    wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - && \
    apt-get update -y && \
    apt-get install -y postgresql-9.6 postgresql-contrib-9.6 postgresql-plpython-9.6 && \
    mv /gosu-amd64 /usr/local/bin/gosu && \
    chmod +x /usr/local/bin/gosu && \
    echo "deb [arch=amd64] http://archive.cloudera.com/cdh${CDH_MAJOR}/ubuntu/xenial/amd64/cdh xenial-cdh${CDH_VERSION} contrib" >>/etc/apt/sources.list.d/cloudera.list && \
    wget --quiet -O - https://archive.cloudera.com/cdh${CDH_MAJOR}/ubuntu/xenial/amd64/cdh/archive.key | apt-key add - && \
    apt-get update -y && \
    apt-get install -y hadoop hadoop-0.20-mapreduce hadoop-client hadoop-hdfs hadoop-mapreduce hadoop-yarn && \
    tar -C /var/lib -xzf /${SPARK_TGZ} && \
    rm -f /${SPARK_TGZ} && \
    chmod +x /entrypoint.sh && \
    echo "export SPARK_DIST_CLASSPATH=$(hadoop classpath)" >> ${SPARK_HOME}/conf/spark-env.sh && \
    mkdir -p ${E2E_HOME} && \
    unzip -d ${E2E_HOME} /adept-e2e-bin.zip && \
    mkdir -p ${E2E_HOME}/bin && \
    mv /e2e.sh ${E2E_HOME}/bin/e2e.sh && \
    chmod +x ${E2E_HOME}/bin/e2e.sh && \
    rm -f /adept-e2e-bin.zip 

EXPOSE 4040
 
LABEL version=${project.version} timestamp=${maven.build.timestamp}

ENTRYPOINT ["/entrypoint.sh"]
#CMD ["bash"]

