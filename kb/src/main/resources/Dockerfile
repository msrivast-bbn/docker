FROM centos:6
ADD parliamentQS.zip postgresql-setup supervisord.conf postgresql.conf /

ENV PGTOP="/var/lib/data/pgsql" PGDATA="/var/lib/data/pgsql/data" PARTOP="/var/lib/data/parliament"

RUN yum install -y epel-release && yum clean all -y
RUN awk '{print} \
/\[(base|updates)\]/ {print "exclude=postgresql*"} \
' /etc/yum.repos.d/CentOS-Base.repo >/tmp/t && cat /tmp/t >/etc/yum.repos.d/CentOS-Base.repo && rm -f /tmp/t
RUN awk '{print} \
/\[epel\]/ {print "exclude=postgresql*"} \
' /etc/yum.repos.d/epel.repo >/tmp/t && cat /tmp/t >/etc/yum.repos.d/epel.repo && rm -f /tmp/t
RUN yum install -y https://download.postgresql.org/pub/repos/yum/9.6/redhat/rhel-6.9-x86_64/pgdg-centos96-9.6-3.noarch.rpm
RUN yum update -y && yum clean all -y
RUN yum install -y java-1.8.0-openjdk.x86_64 emacs emacs-git emacs-nox vim vim-enhanced \
    postgresql96-server postgresql96 postgresql96-contrib supervisor unzip
RUN chmod +x /postgresql-setup
RUN /postgresql-setup
RUN adduser parliament
RUN mkdir -p /usr/local/parliament $PARTOP/{data,log}
RUN cd /usr/local/parliament
RUN mv /parliamentQS.zip /usr/local/parliament
RUN cd /usr/local/parliament; unzip parliamentQS.zip
RUN rm -rf /usr/local/parliament/{data,log}
RUN ln -s "$PARTOP/data" /usr/local/parliament/data
RUN ln -s "$PARTOP/log" /usr/local/parliament/log
RUN rm -f /usr/local/parliament/parliamentQS.zip
RUN chown -R parliament:parliament /usr/local/parliament "$PARTOP"
RUN chmod ug+rx /usr/local/parliament/StartParliament*.sh /usr/local/parliament/bin/*
RUN chmod -R ug+rwx "$PARTOP"
RUN sed -i -e 's/localhost/0.0.0.0/g' /usr/local/parliament/StartParliament*.sh
RUN mv /supervisord.conf /etc/supervisord.conf
RUN chmod a=r /etc/supervisord.conf

VOLUME /var/lib/data

EXPOSE 8089 5432

CMD ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisord.conf"]

