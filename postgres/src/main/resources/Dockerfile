FROM postgres:alpine

COPY DEFTSetup.sh /docker-entrypoint-initdb.d/
RUN apk add --no-cache --virtual --fetch-deps vim vimdiff emacs-nox emacs && \
    chmod a+x /docker-entrypoint-initdb.d/*

