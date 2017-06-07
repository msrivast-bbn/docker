#!/bin/bash
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

if [[ $# -ne 2 ]]; then
	echo "Usage: $(basename $0) <num partitions> <num executors>"
	echo "e.g.:"
	echo "  $(basename $0) 1 1"
	echo "Exiting"
	exit 1
fi
e2e_config="$1"
input_dir="$2"
num_partitions="$3"
num_executors="$4"

log() {
	echo ">>> $1"
}

E2E_HOME=$(dirname $(dirname $0))
if [ ! -r ${E2E_HOME}/etc/site_config ]; then
  echo "${E2E_HOME}/etc/site_config does not exist or is not readable"
  echo Exiting
  exit 1
fi

source ${E2E_HOME}/etc/site_config

if [ "/e2e_config"X == "X" ]; then
  echo '/e2e_config is not defined in site_config'
  echo Exiting
  exit 1
fi

if [ ! -e "/e2e_config" ]; then
  echo "\/e2e_config \"/e2e_config\" does not exist"
  echo Exiting
  exit 1
fi

if [ ! -d "/e2e_config" ]; then
  echo "\/e2e_config \"/e2e_config\" is not a directory"
  echo Exiting
  exit 1
fi

if [ ! -w "/e2e_config" ]; then
  echo "\/e2e_config \"/e2e_config\" is not writable"
  echo Exiting
  exit 1
fi

###
timestamp="$(date +%s)"
log "the UTC timestamp / id of this script execution is ${timestamp}"

log "processing ${e2e_config}"
e2e_config_shared_directory="/sharedData/$(id -un)"
mkdir -p "${e2e_config_shared_directory}"
e2e_config_shared="${e2e_config_shared_directory}/e2e_config_${timestamp}.xml"
cp "${e2e_config}" "${e2e_config_shared}"
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
mkdir -p "${kb_report_output_dir}/${corpus_id}"
if [[ "${gather_statistics}" == "true" ]]; then
	if [ ! -f "${stats_file_path}" ]; then
		touch "${stats_file_path}"
	fi
	chmod 777 "${stats_file_path}"
fi
find "${kb_report_output_dir}" -type d -exec chmod 777 {} +
log "running spark-submit"
${SPARK_HOME}/bin/spark-submit \
	--driver-memory 80g \
	--executor-memory 80g \
	--conf spark.executor.extraClassPath="${e2e_config_shared_top}/msrivast_serif_deliverable/scala_2_11/scala-library-2.11.8.jar:${e2e_config_shared_top}/u40/msrivast_serif_deliverable/scala_2_10/2.10.6/scala-library-2.10.6.jar" \
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
	"${E2E_HOME}/lib/adept-e2e.jar" "${input_dir_hdfs}" "${output_dir_hdfs}" ${num_partitions} "$(find ${input_dir} -maxdepth 1 -type f | wc -l)" "${e2e_config_shared}"

log "downloading output directory from hdfs"
hadoop fs -get "${output_dir_hdfs}"

log "removing temporary hdfs directories, e2e configuration file"
hadoop fs -rm -r "${input_dir_hdfs}" "${output_dir_hdfs}"
rm "${e2e_config_shared}"

log "spark.eventLog.dir: ${spark_eventLog_dir_hdfs}"
log "wrote output to local directory: ${output_dir_hdfs}"
