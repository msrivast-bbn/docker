#!/bin/bash
# Script run within the docker container to start the actual A2KD Run.
# /input contains:
#   /input/partitions - a file containing the number of partitions to use.
#   /input/ddPartitions - a file containing the number of document deduplication partitions to use.
#   /input/config.xml - a file containing the A2KD Configuration file.
#   /input/spark.conf - a file containing the Spark properties file.
#   /input/languages - a file containing a space-separated list of language codes
# The docker container will have the following volumes:
#   /input - mount to /tmp/input$$ containing the files listed above
#   /output - mount to output directory
#   /{EN|ZH|ES} - mounts to the directories containing input files - the name being a language code
#   /hadoop - a mount to the HADOOP configuration directory
#   /sharedTop - a mount to the shared_top directory
# The following environment variables are defined:
#    LOCAL_USER_ID - the numeric id of the user that invoked runa2kd
#    LOCAL_USER_NAME - the name of the user that invoked runa2kd
#    LOCAL_GROUP_ID -  The numeric id of the current group of the user that invoked runa2kd
#    LOCAL_GROUP_NAME - The name of the current group of the user that invoked runa2kd
#    shared_top - the path to the shared directory on the 'outside', we will recreate that in the container
#                 This path was created by entrypoint.sh and is accessible
#    HADOOP_CONF_DIR points to /hadoop
#
set -eu
set -o pipefail

echo Starting A2KD.sh - running as $(id)
trap '
	exit_status=$?; \
	exit_command="${BASH_COMMAND}"; \
	if [[ ${exit_status} -ne 0 ]] && [[ ! "${exit_command}" =~ ^exit\ [0-9]*$ ]]; then \
		echo "ERROR ENCOUNTERED WHILE RUNNING COMMAND:"; \
		echo "	${exit_command}"; \
	fi' \
EXIT

log() {
	echo ">>> $1"
}

if [[ $# -ne 0 ]]; then
	echo "Usage: $(basename $0)"
	echo "e.g.:"
	echo "  $(basename $0)"
	echo "Exiting"
	exit 1
fi

num_partitions=$(cat /input/partitions)
num_ddPartitions=$(cat /input/ddPartitions)

timestamp=$(date +%s)
log "the UTC timestamp/id of this script execution is $timestamp"

log "a2kd preparation started"
config_shared_directory="${shared_top%/}/$(id -un)"
mkdir -p "$config_shared_directory"
config_shared="${config_shared_directory}/config_${timestamp}.xml"
rm -f "$config_shared"

log "creating KB schema"
# Get kb parameters from config file
port=$(xmlstarlet sel -T -t -m "/config/kb_config/metadata_db/@port" -v . -n /input/config.xml)
host=$(xmlstarlet sel -T -t -m "/config/kb_config/metadata_db/@host" -v . -n /input/config.xml)
username=$(xmlstarlet sel -T -t -m "/config/kb_config/metadata_db/@username" -v . -n /input/config.xml)
dbName=$(xmlstarlet sel -T -t -m "/config/kb_config/metadata_db/@dbName" -v . -n /input/config.xml)
password=$(xmlstarlet sel -T -t -m "/config/kb_config/metadata_db/@password" -v . -n /input/config.xml)

# use them to ensure the schema has been created
cat "$A2KD_HOME/etc/DEFT KB create schema.txt" \
	| PGPASSWORD="${password}" psql -d "${dbName}" -U "${username}" -h "${host}" -p ${port} -f -

log "Uploading input to HDFS"
input_dir_hdfs="input_${timestamp}"
log "uploading local input directory/ies to hdfs"
languages=$(cat /input/languages)
cp /input/config.xml /tmp
# copy in the input data, and then update the config file to the new location in hdfs for each language
hdfs dfs -mkdir "$input_dir_hdfs"
for lang in $languages; do
  hdfs dfs -mkdir "$input_dir_hdfs/${lang}"
  hdfs dfs -put "/${lang}" "$input_dir_hdfs/${lang}"
  # update path in shared copy of a2kd_config file
  xmlstarlet ed -u "/config/algorithm_set[@language="$lang"]/input_directory" -v "${input_dir_hdfs}/${lang}" /tmp/config.xml >/tmp/a
  rm -f /tmp/config.xml
  mv /tmp/a /tmp/config.xml
done
# we are done editing the config file, move it to the shared location
mv /tmp/config.xml "$config_shared"

output_dir_hdfs="output_${timestamp}"
spark_eventLog_dir_hdfs="hdfs:///user/$(id -un)/spark_logs/spark_logs_${timestamp}"
hdfs dfs -mkdir "$spark_eventLog_dir_hdfs"

log "running spark-submit"

${SPARK_HOME}/bin/spark-submit \
	--class adept.e2e.driver.MainE2eDriver \
	--properties-file /input/spark.conf \
	${A2KD_HOME}/lib/adept-e2e.jar ${output_dir_hdfs} ${num_partitions} ${num_ddPartitions} $config_shared

log "downloading output directory from hdfs"
hdfs dfs -get "${output_dir_hdfs}" /output

log "removing temporary hdfs directories, a2kd configuration file"
hdfs dfs -rmr -skipTrash "${input_dir_hdfs}" "${output_dir_hdfs}"
rm -f "$config_shared"

log "spark.eventLog.dir: ${spark_eventLog_dir_hdfs}"
log "wrote output to local directory"

log "A2KD Processing Complete"
