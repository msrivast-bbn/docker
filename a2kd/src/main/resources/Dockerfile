FROM ubuntu:xenial

ENV CDH_VERSION=5.11 CDH_MAJOR=5 \
    SPARK_VERSION=2.0.0 HADOOP_VERSION=2.6 \
    JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64 \
    A2KD_HOME=/var/lib/adept-a2kd DEBIAN_FRONTEND=noninteractive
ENV SPARK_TGZ=spark-$SPARK_VERSION-bin-hadoop$HADOOP_VERSION.tgz \
    SPARK_HOME=/var/lib/spark-$SPARK_VERSION-bin-hadoop$HADOOP_VERSION \
    PATH=$A2KD_HOME/bin:$SPARK_HOME/bin:$JRE_HOME/bin:$JAVA_HOME/bin:$PATH \
    JRE_HOME=$JAVA_HOME/jre

COPY entrypoint.sh gosu-amd64 spark-2.0.0-bin-hadoop2.6.tgz a2kd.sh adept-e2e-bin.zip git.properties /

# initial installs
RUN apt-get update -y && \
    apt-get upgrade -y && \
    echo 'deb http://apt.postgresql.org/pub/repos/apt xenial-pgdg main' >/etc/apt/sources.list.d/postgresql.list && \
    echo "deb [arch=amd64] http://archive.cloudera.com/cdh${CDH_MAJOR}/ubuntu/xenial/amd64/cdh xenial-cdh${CDH_VERSION} contrib" >>/etc/apt/sources.list.d/cloudera.list && \
    apt-get install -y apt-utils curl wget python perl libterm-readline-gnu-perl openjdk-8-jdk unzip ssh vim vim-fugitive emacs xmlstarlet sudo && \
    wget --quiet -O - https://archive.cloudera.com/cdh${CDH_MAJOR}/ubuntu/xenial/amd64/cdh/archive.key | apt-key add - && \
    wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - && \
    chmod 644 /etc/apt/sources.list.d/*.list && \
    apt-get update -y && \
    apt-get upgrade -y && \
    apt-get install -y hadoop hadoop-0.20-mapreduce hadoop-client hadoop-hdfs hadoop-mapreduce hadoop-yarn \
    postgresql-9.6 postgresql-contrib-9.6 postgresql-plpython-9.6 && \
    umask 022 && \
    ln -s libcrypto.so.1.0.0 /lib/x86_64-linux-gnu/libcrypto.so && \
    mv /gosu-amd64 /usr/local/bin/gosu && \
    chmod 755 /usr/local/bin/gosu /entrypoint.sh && \
    tar -C /var/lib -xzf /${SPARK_TGZ} && \
    rm -f /${SPARK_TGZ} && \
    echo "export SPARK_DIST_CLASSPATH=$(hadoop classpath)" >> ${SPARK_HOME}/conf/spark-env.sh && \
    mkdir -p ${A2KD_HOME} && \
    cd ${A2KD_HOME} && \
    unzip /adept-e2e-bin.zip && \
    rm /adept-e2e-bin.zip && \
    mkdir -p ${A2KD_HOME}/bin && \
    mv /a2kd.sh ${A2KD_HOME}/bin/a2kd.sh && \
    cp ${A2KD_HOME}/*.txt / && \
    mkdir /input && \
    chmod 755 ${A2KD_HOME} ${A2KD_HOME}/bin/* 

EXPOSE 4040
 
LABEL version=${project.version} timestamp=${maven.build.timestamp}

ENTRYPOINT ["/entrypoint.sh"]

