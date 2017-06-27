FROM centos:6.7
RUN yum install -y unzip
ADD parliamentQS-*.zip /usr/local/parliament/
WORKDIR /usr/local/parliament
RUN adduser parliament && \
    unzip parliamentQS-*.zip && \
    rm -f parliamentQS-*.zip && \
    mkdir data log && \
    chgrp -R parliament . && \
    chmod -R g+rx . && \
    chmod -R g+rwx data log && \
    yum install -y java-1.8.0-openjdk.x86_64 emacs emacs-git emacs-nox vim vim-enhanced && \
    yum update -y && \
    sed -i -e 's/localhost/0.0.0.0/g' StartParliament.sh

VOLUME /usr/local/parliament/data

EXPOSE 8089

USER parliament
CMD /usr/local/parliament/StartParliament.sh

