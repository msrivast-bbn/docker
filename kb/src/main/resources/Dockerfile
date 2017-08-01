FROM centos:6
ADD startup parliamentQS.zip postgresql.conf postgresql-setup supervisord.conf /

ENV PGTOP="/var/lib/data/pgsql" PGDATA="/var/lib/data/pgsql/data" PARTOP="/var/lib/data/parliament"

RUN yum install -y epel-release && yum clean all
RUN awk '{print} \
/\[(base|updates)\]/ {print "exclude=postgresql*"} \
' /etc/yum.repos.d/CentOS-Base.repo >/tmp/t && cat /tmp/t >/etc/yum.repos.d/CentOS-Base.repo && rm -f /tmp/t
RUN awk '{print} \
/\[epel\]/ {print "exclude=postgresql*"} \
' /etc/yum.repos.d/epel.repo >/tmp/t && cat /tmp/t >/etc/yum.repos.d/epel.repo && rm -f /tmp/t
RUN yum install -y https://download.postgresql.org/pub/repos/yum/9.6/redhat/rhel-6.9-x86_64/pgdg-centos96-9.6-3.noarch.rpm
RUN yum update -y && yum clean all -y
RUN yum install -y java-1.8.0-openjdk emacs emacs-git emacs-nox vim vim-enhanced \
postgresql96-server postgresql96-contrib postgresql96 unzip openssh-client
RUN yum install -y centos-release-SCL scl-utils-build
RUN yum install -y python27 python27-python-setuptools
RUN scl enable python27 'pip install pip --upgrade'
RUN scl enable python27 'pip install supervisor'
RUN chmod u+x /postgresql-setup /startup
RUN adduser parliament
RUN mkdir -p /usr/local/parliament $PARTOP/data $PARTOP/log
RUN cd /usr/local/parliament
RUN mv /parliamentQS.zip /usr/local/parliament
RUN cd /usr/local/parliament; unzip parliamentQS.zip
RUN rm -rf /usr/local/parliament/{data,log}
RUN ln -s $PARTOP/data /usr/local/parliament/data
RUN ln -s $PARTOP/log /usr/local/parliament/log
RUN rm -f /usr/local/parliament/parliamentQS.zip
RUN chown -R parliament:parliament /usr/local/parliament $PARTOP
RUN chmod ug+rx /usr/local/parliament/StartParliament*.sh /usr/local/parliament/bin/*
RUN chmod -R ug+rwx $PARTOP
RUN sed -i -e 's/localhost/0.0.0.0/g' /usr/local/parliament/StartParliament*.sh
RUN chmod a=r /supervisord.conf

VOLUME /var/lib/data

EXPOSE 8089 5432

CMD ["/startup"]

