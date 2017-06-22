#!/bin/bash

# pg_hba.conf can be set up to allow remote access without passwords.
# do not let it
sed -i -e '/\s*host\s\+all\s\+all\s\+all\s\+trust/s!trust!md5!' "${PGDATA}/pg_hba.conf"
