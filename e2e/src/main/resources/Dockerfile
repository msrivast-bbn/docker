FROM centos:6.7
RUN yum install -y java-1.8.0-openjdk
COPY opt /opt
RUN chmod +x /opt/adept-e2e/run_e2e.sh createKB.sh 
ENV JAVA_HOME /usr/lib/jvm/jre
WORKDIR /opt/adept-e2e/run_e2e.sh
CMD ["./run_e2e.sh"]

