#!/bin/bash
function help() {
  cat <<EOF
  $1 <a2kd config file path> 

  Create a new database using information from the specified A2KD configuration 
  file. 

  This command uses the host, port, username,
  password and dbName parameters in the A2KD configuration file
  to connect to a PostgreSQL database instance and checks to see if a database
  instance already exists there. If it does, it checks with the user to ensure
  that the destruction of the existing database is all right. If the user
  indicates that it is all right to proceed, the command then sets that database
  up as an empty instance ready to be used by the A2KD processor.

  If an existing PostgreSQL database instance is deleted, the command will also
  clean out any existing data from the Parliament Triple Store using the
  url parameter from the configuration file.
EOF
}

# Check argument
if [ $# -ne 1 ] ; then
  echo "ERROR: Incorrect number of arguments\n"
  help $(basename $0)
  exit 1
fi
if [ "$1" = "-h" -o "$1" = "--help" ] ; then
  help $(basename $0)
  exit 0
fi
if [ ! -e "$1" ] ; then
  echo "ERROR: $1 does not exist"
  exit 1
fi 
if [ ! -f "$1" ] ; then
  echo "ERROR: $1 is not a file"
  exit 1
fi 
if [ ! -r "$1" ] ; then
  echo "ERROR: $1 is not readable"
  exit 1
fi 
a2kd_config="$1"
# check for wget, xmllint and psql
hash wget 2>/dev/null || { echo >&2 "I require wget but it's not installed or in your PATH.  Aborting."; exit 1; }
hash psql 2>/dev/null || { echo >&2 "I require psql but it's not installed or in your PATH.  Aborting."; exit 1; }
hash xmllint 2>/dev/null || { echo >&2 "I require xmllint but it's not installed or in your PATH.  Aborting."; exit 1; }

username=$(echo 'cat /config/kb_config/metadata_db/@username' | xmllint --shell "$a2kd_config" | grep -vE "^(/ > | ---)" | sed -n 's/[^\"]*\"\([^\"]*\)\"[^\"]*/\1/gp')
password=$(echo 'cat /config/kb_config/metadata_db/@password' | xmllint --shell "$a2kd_config" | grep -vE "^(/ > | ---)" | sed -n 's/[^\"]*\"\([^\"]*\)\"[^\"]*/\1/gp')
host=$(echo 'cat /config/kb_config/metadata_db/@host' | xmllint --shell "$a2kd_config" | grep -vE "^(/ > | ---)" | sed -n 's/[^\"]*\"\([^\"]*\)\"[^\"]*/\1/gp')
dbName=$(echo 'cat /config/kb_config/metadata_db/@dbName' | xmllint --shell "$a2kd_config" | grep -vE "^(/ > | ---)" | sed -n 's/[^\"]*\"\([^\"]*\)\"[^\"]*/\1/gp')
port=$(echo 'cat /config/kb_config/metadata_db/@port' | xmllint --shell "$a2kd_config" | grep -vE "^(/ > | ---)" | sed -n 's/[^\"]*\"\([^\"]*\)\"[^\"]*/\1/gp')
url=$(echo 'cat /config/kb_config/triple_store/@url' | xmllint --shell "$a2kd_config" | grep -vE "^(/ > | ---)" | sed -n 's/[^\"]*\"\([^\"]*\)\"[^\"]*/\1/gp')

for param in host dbName username password port url; do
  eval value="\$$param"
  if [ ! "$value" ] ; then
    if [ "$param" = password ] ; then
      echo "WARN: password is empty or not set. This may be an error, or it is not secure at all!"
    else
      echo "ERROR: $param is not set or is empty in $1"
      exit 1
    fi
  fi
  unset value
done

echo
echo
read -e -p "Enter DB Administrator login: " presadmin
read -s -e -p "Enter DB Administrator password: " presadminpw
echo
umask 077
export PGPASSFILE=~/.pgpass$$
echo "${host}:${port}:*:${presadmin}:${presadminpw}" >$PGPASSFILE
echo "${host}:${port}:*:${username}:${password}" >>$PGPASSFILE
trap 'rm -f $PGPASSFILE' EXIT
umask 027
chmod 400 $PGPASSFILE
unset presadminpw 

# Is the database there?
psql -U "$presadmin" -h "$host" -p "$port" -lqt >/dev/null
if [ $? -ne 0 ] ; then
  echo "Attempt to access the database failed!"
  exit 0
fi

# is the triple store there?
wget --output-document=/dev/null --quiet "$url"
if [ $? -ne 0 ] ; then
  echo "Attempt to access the triple store failed!"
  exit 0
fi

function databaseExists() {
  r=$(psql -U "$presadmin" -h $2 -p $3 --quiet -tAc "SELECT count(*) FROM pg_catalog.pg_database WHERE datname = '$1'" 2>/dev/null)
  [ $? -ne 0 ] && return 1
  [ "$r" -a "$r" -eq 1 ] && return 0
  return 1
}

function databaseInitialized() {
  r=$(psql -U "$presadmin" -h $2 -p $3 -d "$1" --quiet -tAc "SELECT count(*) FROM pg_catalog.pg_tables WHERE tablename = 'Corpus'" 2>/dev/null)
  [ $? -ne 0 ] && return 1
  [ "$r" -a $r -eq 1 ] && return 0
  return 1
}

function databasePopulated() {
  r=$(psql -U "$presadmin" -h $2 -p $3 -d "$1" --quiet -tAc "SELECT count(*) FROM \"Corpus\"" 2>/dev/null)
  [ $? -ne 0 ] && return 1
  [ "$r" -a $r -ge 1 ] && return 0
  return 1
}

function userExists() {
  r=$(psql -U "$presadmin" -h $2 -p $3 --quiet -tAc "SELECT count(*) FROM pg_catalog.pg_user WHERE usename = '$1'" 2>/dev/null)
  [ $? -ne 0 ] && return 1
  [ "$r" -a $r -ge 1 ] && return 0
  return 1
}

function passwordValid() {
  r=$(psql -U $1 -h $3 -p $4 -d postgres --quiet -tAc "SELECT 1" 2>/dev/null)
  [ $? -eq 0 ] && return 0
  return 1
}

function createUser() {
  psql -U "$presadmin" -h "$3" -p "$4" --quiet -tAc "CREATE USER $1 PASSWORD '$2'"
  if [ $? -ne 0 ] ; then
    echo "ERROR: failed to create user."
    exit 1
  fi
}

function deleteDatabase() {
  psql -U "$presadmin" -h "$2" -p "$3" -d "postgres" --quiet -tAc "DROP DATABASE IF EXISTS $1"
  if [ $? -ne 0 ] ; then
    echo "ERROR: failed to drop the database $1 on $3:$4"
    exit 1
  fi
}

function clearTripleStore() {
  wget --output-document=/dev/null --quiet --post-data "update=CLEAR DEFAULT" "${1}/sparql"
  if [ $? -ne 0 ] ; then
    echo "WARNING: failed to clear the triple store $1"
  fi
}

# Does the user exist?
if userExists "$username" "$host" "$port" ; then
  # yes. Check the password
  if passwordValid  "$username" "$password"  "$host" "$port"; then 
    echo "User $username exists and password is good"
  else
    echo "The password in the configuration file is incorrect. Please take appropriate action"
    exit 1
  fi
else
  # no. Create the user and set the password.
  createUser "$username" "$password"  "$host" "$port"
fi

createNew=1

# Does the database exist?
if databaseExists "$dbName" "$host" "$port" ; then
  # Yes. See if it has been initialized.
  if databaseInitialized  "$dbName" "$host" "$port" ; then
    # yes. see if it has been populated
    if databasePopulated "$dbName" "$host" "$port" ; then
      # OK, ask
      echo "The database $dbName on $host:$port already exists and is populated with data"
      read -p 'Do you want to overwrite it? (y/N): ' ans
      if [ ${${ans:0:1},,} = y ] ; then
        read -p 'Are you sure? (y/N): ' ans
        if [ ${${ans:0:1},,} = y ] ; then
          # remove existing
          deleteDatabase "$dbName" "$host" "$port"
          clearTripleStore "$url"
          createNew=0
        fi
      fi
    else
      # empty database...delete 
      deleteDatabase "$dbName" "$host" "$port"
      clearTripleStore "$url"
      createNew=0
    fi
  else
    # uninitialized database, delete
    deleteDatabase "$dbName" "$host" "$port"
    clearTripleStore "$url"
    createNew=0
  fi
else
  #empty database - delete
  deleteDatabase "$dbName" "$host" "$port"
  clearTripleStore "$url"
  createNew=0
fi

if [ $createNew -eq 0 ] ; then
  psql -U "$presadmin" -h "${host}" -p "${port}" --quiet <<-EOF
	CREATE DATABASE $dbName WITH OWNER $username;
	GRANT ALL ON DATABASE $dbName TO $username;
EOF
  psql -U "$presadmin" -h "$host" -p "$port" -d "$dbName" --quiet <<-EOF
	ALTER SCHEMA public OWNER TO $username;
	GRANT ALL ON SCHEMA public TO $username;
EOF
echo
echo "-----"
echo "Database $dbName has been created on $host:$port"
echo "and is ready for use by user $username. The triple store at"
echo "${url%/parliament} has been cleared as well."
fi
exit 0
