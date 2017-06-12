#!/bin/bash

function help() {
  echo "$(basename $0) <e2e_config file path> <site_config file path>"
}

function createDB() {
  echo "Creating DB"
  ${PGPASSWORD}psql -U "${pgresadmin}" -h "${metadata_host}" -p ${metadata_port} <<EOF
CREATE USER ${metadata_user_name} PASSWORD '${metadata_password}';
CREATE DATABASE ${metadata_db} WITH OWNER ${metadata_user_name};
GRANT ALL ON DATABASE ${metadata_db} TO ${metadata_user_name};
EOF
  ${PGPASSWORD}psql -U "${pgresadmin}" -h "${metadata_host}" -p ${metadata_port} -d ${metadata_db} <<EOF
ALTER SCHEMA public OWNER TO ${metadata_user_name};
GRANT ALL ON SCHEMA public TO ${metadata_user_name};
EOF
}

if [ $# -ne 2 ]; then
  help
  exit 1
fi

if [ ! -r $1 -o ! -f $1 ]; then
  echo "e2e configuration file \"$1\" does not exist, is not a file or is not readable"
  exit 1
fi

if [ ! -r $2 ]; then
  echo "site configuration file \"$2\" does not exist, is not a file or is not readable"
  exit 1
fi

source $2

e2e_config=$1
for e2e_config_attribute in "metadata_host" "metadata_port" "metadata_db" "metadata_user_name" "metadata_password" "corpus_id" "kb_report_output_dir" "gather_statistics" "stats_file_path"; do
	attribute_value="$(python -c "import re; print re.compile(\"<entry key=\\\"${e2e_config_attribute}\\\">(.*?)</entry>\").findall(open(\"${e2e_config}\").read())[0]")"
	declare "${e2e_config_attribute}"="${attribute_value}"
done

if [ "${pgreasdminpw}" ]; then
  export PGPASSWORD="env PGPASSWORD=\"${pgresadminpw}\" " 
else
  unset PGPASSWORD
fi

if [ "${metadata_password}" ]; then
  export PGUPASSWORD="env PGPASSWORD=\"${metadata_password}\" " 
else
  unset PGUPASSWORD
fi

# does DB exist?
DB=n
res=$(${PGPASSWORD}psql -l -U ${pgresadmin} -h ${metadata_host} -p ${metadata_port} -tAc "SELECT EXISTS(SELECT datname FROM pg_catalog.pg_database WHERE datname = '${metadata_db}');")
if [ $res = "t" ]; then
  echo "Database '${metadata_db}' already exists on ${metadata_host}:${metadata_port}"
  echo "Continuing will destroy its current content and then proceed with this run."
  read -r -p "Continue? (y/N) " response
  response=${response,,} # tolower
  if [[ "$response" =~ ^(yes|y)$ ]]; then
    DB=y
  fi
fi
# Does user exist?
USER=n
res=$(${PGPASSWORD}psql -l -U ${pgresadmin} -h ${metadata_host} -p ${metadata_port} -tAc "SELECT EXISTS(SELECT * FROM pg_catalog.pg_user WHERE usename = '${metadata_user_name}');")
if [ "$res" = t ]; then
  echo "User '${metadata_user_name}' already exists on ${metadata_host}:${metadata_port}"
  echo "Continuing will remove the existing user definition."
  read -r -p "Continue? (y/N) " response
  response=${response,,} # tolower
  if [[ "$response" =~ ^(yes|y)$ ]]; then
    USER=y
  fi
fi
if [ "$USER" = y ]; then
    ${PGPASSWORD}psql -l -U ${pgresadmin} -h ${metadata_host} -p ${metadata_port} -tAc "DROP DATABASE IF EXISTS ${metadata_db} ;"
    if [ $? -ne 0 ]; then 
      echo "Deal with the error and try again..."
      exit 1
    fi
    DB=n
    ${PGPASSWORD}psql -l -U ${pgresadmin} -h ${metadata_host} -p ${metadata_port} -tAc "DROP USER IF EXISTS ${metadata_user_name}"
    if [ $? -ne 0 ]; then 
      echo "Deal with the error and try again..."
      exit 1
    fi
fi
if [ "$DB" = y ]; then
    ${PGPASSWORD}psql -l -U ${pgresadmin} -h ${metadata_host} -p ${metadata_port} -tAc "DROP DATABASE IF EXISTS ${metadata_db} ;"
    if [ $? -ne 0 ]; then 
      echo "Deal with the error and try again..."
      exit 1
    fi
    DB=n
fi
createDB
echo "Created Database ${metadata_db} owned by ${metadata_user_name} on ${metadata_host}:${metadata_port}"

