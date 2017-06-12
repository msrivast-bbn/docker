#!/bin/bash
# Script run within the docker container to start the actual E2E Run.
set -eu
set -o pipefail

trap '
	exit_status=$?; \
	exit_command="${BASH_COMMAND}"; \
	if [[ ${exit_status} -ne 0 ]] && [[ ! "${exit_command}" =~ ^exit\ [0-9]*$ ]]; then \
		echo "ERROR ENCOUNTERED WHILE RUNNING COMMAND:"; \
		echo "	${exit_command}"; \
	fi' \
EXIT

if [[ $# -ne 3 ]]; then
	echo "Usage: $(basename $0) <inpur dir path> <num partitions> <num executors>"
	echo "e.g.:"
	echo "  $(basename $0) ~/input 1 1"
	echo "Exiting"
	exit 1
fi
input_dir="$1"
num_partitions="$2"
num_executors="$3"

log() {
	echo ">>> $1"
}

E2E_HOME=$(dirname $(dirname $0))
if [ ! -r /conf/site_config ]; then
  echo "/conf/site_config does not exist or is not readable"
  echo Exiting
  exit 1
fi

source /conf/site_config

if [ ! -e ${shared_top} ]; then
  echo "The Shared Data directory \"${shared_top}\" does not exist in the container"
  echo Exiting
  exit 1
fi

if [ ! -d ${shared_top} ]; then
  echo "The Shared Data directory \"${shared_top}\" is not a directory"
  echo Exiting
  exit 1
fi

if [ ! -w "${shared_top}" ]; then
  echo "The Shared Data directory \"${shared_top}\" is not writable"
  echo Exiting
  exit 1
fi

if [ ! -d "/conf" ]; then
  echo "The Configuration directory \"/conf\" is not a directory or does not exist"
  echo Exiting
  exit 1
fi

###
timestamp="$(date +%s)"
log "the UTC timestamp / id of this script execution is ${timestamp}"

log "e2e preparation started"
e2e_config_shared_directory="${shared_top%/}/$(id -un)"
mkdir -p "${e2e_config_shared_directory}"
e2e_config_shared="${e2e_config_shared_directory}/e2e_config_${timestamp}.xml"
cp "/e2e_config" "${e2e_config_shared}"
for e2e_config_attribute in "metadata_host" "metadata_port" "metadata_db" "metadata_user_name" "metadata_password" "corpus_id" "kb_report_output_dir" "gather_statistics" "stats_file_path"; do
	attribute_value="$(python -c "import re; print re.compile(\"<entry key=\\\"${e2e_config_attribute}\\\">(.*?)</entry>\").findall(open(\"${e2e_config_shared}\").read())[0]")"
	declare "${e2e_config_attribute}"="${attribute_value}"
done

log "creating KB schema"

cat "${E2E_HOME}/etc/DEFT KB create schema.txt" \
	| PGPASSWORD="${metadata_password}" psql -d "${metadata_db}" -U "${metadata_user_name}" -h "${metadata_host}" -p ${metadata_port} -f -

input_dir_hdfs="$(basename ${input_dir})_input_${timestamp}"
log "uploading local input directory to hdfs"
hadoop fs -put "/input" "${input_dir_hdfs}"
output_dir_hdfs="e2e_output_${timestamp}"
spark_eventLog_dir_hdfs="hdfs:///user/$(id -un)/spark_logs/spark_logs_${timestamp}"
hadoop fs -mkdir -p "${spark_eventLog_dir_hdfs}"

log "running spark-submit"
set -xv
S211jp="msrivast_serif_deliverable/scala_2_11/scala-library-2.11.8.jar"
S210jp="msrivast_serif_deliverable/scala_2_10/2.10.6/scala-library-2.10.6.jar"
EAS="${shared_top}/e2e_artifacts/e2e_external_classpath"
EACP="${EAS}/*:${EAS}/classes"
EXT_CP="${shared_top}/${S211jp}:${shared_top}/${S210jp}:${EACP}"

${SPARK_HOME}/bin/spark-submit \
	--driver-memory ${driver_memory:-"80g"} \
	--executor-memory ${executor_memory:-"80g"} \
	--conf spark.executor.extraClassPath="${EXT_CP}" \
	--conf spark.driver.cores=5 \
	--conf spark.eventLog.enabled=true \
	--conf spark.eventLog.dir="${spark_eventLog_dir_hdfs}" \
	--conf spark.ui.killEnabled=true \
	--conf spark.executor.cores=1 \
	--num-executors ${num_executors} \
	--conf spark.shuffle.blockTransferService=nio \
	--conf spark.dynamicAllocation.enabled=false \
	--conf spark.shuffle.service.enabled=false \
	--conf spark.speculation=true \
	--conf spark.speculation.multiplier=2 \
	--class adept.e2e.driver.E2eDriver \
	--master ${master:-yarn} \
        --deploy-mode ${deploymode:-cluster} \
	--queue pool1 \
	--conf spark.storage.blockManagerTimeoutInterval=100000 \
	"${E2E_HOME}/lib/adept-e2e.jar" "${input_dir_hdfs}" "${output_dir_hdfs}" ${num_partitions} "$(find /input -maxdepth 1 -type f | wc -l)" "${e2e_config_shared}"

log "downloading output directory from hdfs"
hadoop fs -get "${output_dir_hdfs}"

log "removing temporary hdfs directories, e2e configuration file"
hadoop fs -rm -r "${input_dir_hdfs}" "${output_dir_hdfs}"
rm "${e2e_config_shared}"

log "spark.eventLog.dir: ${spark_eventLog_dir_hdfs}"
log "wrote output to local directory: ${output_dir_hdfs}"

