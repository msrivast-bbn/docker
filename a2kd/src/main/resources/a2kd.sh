#!/bin/bash
# Script run within the docker container to start the actual A2KD Run.
# /input contains:
#   /input/partitions - a file containing the number of partitions to use.
#   /input/config.xml - a file containing the A2KD Configuration file.
#   /input/spark.conf - a file containing the Spark properties file.
#   /input/languages - a file containing a space-separated list of language codes
#   /input/log4j.properties [optional] - log4j logging parameters
#   /input/statsDir - present if gather_statistics is true. A directory to contain statistics.
#   /input/kbReportsDir - present if generate_kb_reports is true. A directory to contain the reports.
#   /input/kbResolverConfig - present if kb_resolver_config is defined and readable. A parameters file for the KBResolver
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
#    job_timestamp - the time-based (hopefully unique) value used to distinguish this run
#    job_directory - the shared path to the job directory, mounted as /input
set -eu
set -o pipefail
umask 002
function errexit {
   ( >&2 echo "$1")
   logger -p user.error "$1"
   rm -rf /tmp/input$$
   exit 1
}

job_timestamp=$(cat /input/job_timestamp)

echo Starting A2KD.sh $job_timestamp - running as $(id)
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

find /input/* -type f -exec chmod 664 {} \;
find /input/* -type d -exec chmod 775 {} \;

num_partitions=$(cat /input/partitions)
job_directory=$(cat /input/job_directory)

log "a2kd preparation started"
[ "${job_directory:-x}" = x ] && errexit "ERROR: job_directory is not defined"
[ -d "$job_directory" ] || errexit "ERROR: job directory $job_directory is not defined"
[ -r "$job_directory" ] || errexit "ERROR: job directory $job_directory is not readable"
[ -w "$job_directory" ] || errexit "ERROR: job directory $job_directory is not writable"

log "creating KB schema"
# Get kb parameters from config file
port=$(xmlstarlet sel -T -t -m "/config/kb_config/metadata_db/@port" -v . -n /input/config.xml)
host=$(xmlstarlet sel -T -t -m "/config/kb_config/metadata_db/@host" -v . -n /input/config.xml)
username=$(xmlstarlet sel -T -t -m "/config/kb_config/metadata_db/@username" -v . -n /input/config.xml)
dbName=$(xmlstarlet sel -T -t -m "/config/kb_config/metadata_db/@dbName" -v . -n /input/config.xml)
password=$(xmlstarlet sel -T -t -m "/config/kb_config/metadata_db/@password" -v . -n /input/config.xml)
corpus_id=$(xmlstarlet sel -T -t -m "/config/kb_config/@corpus_id" -v . -n /input/config.xml)

# use them to ensure the schema has been created
cat "$A2KD_HOME/etc/DEFT KB create schema.txt" \
	| PGPASSWORD="${password}" psql -d "${dbName}" -U "${username}" -h "${host}" -p ${port} -f -

log "Uploading input to HDFS"
input_dir_hdfs="input_${job_timestamp}"
log "uploading local input directory/ies to hdfs"
languages=$(cat /input/languages)

# copy in the input data, and then update the config file to the new location in hdfs for each language
hdfs dfs -mkdir -p "$input_dir_hdfs"
for lang in $languages; do
  hdfs dfs -put -f "/${lang}" "$input_dir_hdfs"
  # update path in shared copy of a2kd_config file
  xmlstarlet edit --inplace --update "/config/algorithm_set[@language='$lang']/input_directory" --value "$input_dir_hdfs/$lang" /input/config.xml
done

output_dir_hdfs="output_${job_timestamp}"
hdfs dfs -mkdir -p "$output_dir_hdfs"

# if the KBResolver configuration file is specified, replace it with /input/kbResolverConfig
if [ -f /input/kbResolverConfig ]; then
  xmlstarlet edit --inplace --update "/config/kb_resolver_config" --value "$job_directory/kbResolverConfig" /input/config.xml
fi

# if the KB Report Directory exists, set /input/kbReportsDir as the directory
if [ -d /input/kbReportsDir ]; then
  xmlstarlet edit --inplace --update "/config/kb_reporting_config/@kb_report_output_dir" --value "$job_directory/kbReportsDir" /input/config.xml
fi

# if the Statistics Directory exists, set /input/statsDir as the directory
if [ -d /input/statsDir ]; then
  xmlstarlet edit --inplace --update "/config/debug_config/@stats_directory_path" --value "$job_directory/statsDir" /input/config.xml
fi

log "running spark-submit"

${SPARK_HOME}/bin/spark-submit --verbose \
	--class adept.e2e.driver.MainE2eDriver \
	--properties-file /input/spark.conf \
	${A2KD_HOME}/lib/adept-e2e.jar "${output_dir_hdfs}" ${num_partitions} "${job_directory}/config.xml"

log "downloading output directory from hdfs"
log "removing any existing local directories from previous run(s)"
rm -rf /output/"${output_dir_hdfs}"
hdfs dfs -get "${output_dir_hdfs}" /output
log "removing temporary hdfs directories"
hdfs dfs -rm -r -skipTrash "${input_dir_hdfs}" "${output_dir_hdfs}"
log "wrote output to local directory"

log "A2KD Processing Complete"

