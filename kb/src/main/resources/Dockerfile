FROM centos:6
ADD startup parliamentQS.zip postgresql.conf postgresql-setup parliament-setup supervisord.conf git.properties version runParliament runPostgres /

ENV VARTOP="/var/lib/data" PGTOP="/var/lib/data/pgsql" PGDATA="/var/lib/data/pgsql/data" PARTOP="/var/lib/data/parliament"

RUN yum install -y epel-release && yum clean all && \
    awk '{print} \
/\[(base|updates)\]/ {print "exclude=postgresql*"} \
' /etc/yum.repos.d/CentOS-Base.repo >/tmp/t && cat /tmp/t >/etc/yum.repos.d/CentOS-Base.repo && rm -f /tmp/t && \
    awk '{print} \
/\[epel\]/ {print "exclude=postgresql*"} \
' /etc/yum.repos.d/epel.repo >/tmp/t && cat /tmp/t >/etc/yum.repos.d/epel.repo && rm -f /tmp/t && \
    yum install -y https://download.postgresql.org/pub/repos/yum/9.6/redhat/rhel-6.9-x86_64/pgdg-centos96-9.6-3.noarch.rpm && \
    yum update -y && yum clean all -y && \
    yum install -y java-1.8.0-openjdk-devel emacs emacs-git emacs-nox vim vim-enhanced \
postgresql96-server postgresql96-contrib postgresql96 unzip openssh-client sudo && \
    yum install -y centos-release-SCL scl-utils-build && \
    yum install -y python27 python27-python-setuptools && \
    scl enable python27 'pip install pip --upgrade' && \
    scl enable python27 'pip install supervisor' && \
    cp -p /supervisord.conf /etc/supervisord.conf && \
    chmod a+r /supervisord.conf /etc/supervisord.conf && \
    chmod u+rx /postgresql-setup /startup /parliament-setup && \
    adduser parliament && \
    mkdir -p /usr/local/parliament "$VARTOP" && \
    cd /usr/local/parliament && \
    mv /parliamentQS.zip /usr/local/parliament && \
    cd /usr/local/parliament; unzip parliamentQS.zip && \
    rm -rf /usr/local/parliament/{data,log} && \
    ln -s $PARTOP/data /usr/local/parliament/data && \
    ln -s $PARTOP/log /usr/local/parliament/log && \
    rm -f /usr/local/parliament/parliamentQS.zip && \
    chown -R parliament:parliament /usr/local/parliament && \
    chmod ug+rx /usr/local/parliament/StartParliament*.sh /usr/local/parliament/bin/* && \
    sed -i -e 's/localhost/0.0.0.0/g' /usr/local/parliament/StartParliament*.sh && \
    chmod 777 "$VARTOP" && \
    mv /version /usr/local/bin && \
    chmod a+rx /usr/local/bin/version /runParliament /runPostgres && \
    chmod a=r /supervisord.conf

VOLUME /var/lib/data

LABEL version=@project.version@ timestamp=@timestamp@ type=KB

EXPOSE 8089 5432

ENTRYPOINT ["/startup"]

