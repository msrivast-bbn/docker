#!/bin/bash
# Script run within the docker container to start the actual A2KD Run.
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
	echo "Usage: $(basename $0) <input dir path> <num partitions> <num executors>"
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

# read and parse the configuration file for the values of interest
while read line; do
    [[ "$line" =~ ^([[:space:]]*<entry[[:space:]]+key=\")([^\"]+)(\"[[:space:]]*>)([^<]*)(<[[:space:]]*/entry[[:space:]]*>) ]] && declare ${BASH_REMATCH[2]}=${BASH_REMATCH[4]}
done < "/a2kd_config"

timestamp=$(date +%s)
log "the UTC timestamp/id of this script execution is $timestamp"

log "a2kd preparation started"
config_shared_directory="${shared_top%/}/$(id -un)"
mkdir -p "$config_shared_directory"
config_shared="${config_shared_directory}/a2kd_config_${timestamp}.xml"
rm -f "$config_shared"
cp "/a2kd_config" "$config_shared"
ls -l "$config_shared"
log "creating KB schema"

cat "$A2KD_HOME/etc/DEFT KB create schema.txt" \
	| PGPASSWORD="${metadata_password}" psql -d "${metadata_db}" -U "${metadata_user_name}" -h "${metadata_host}" -p ${metadata_port} -f -

input_dir_hdfs="$(basename "$input_dir")_input_${timestamp}"
log "uploading local input directory to hdfs"
hdfs dfs -put "/input" "$input_dir_hdfs"
output_dir_hdfs="a2kd_output_${timestamp}"
spark_eventLog_dir_hdfs="hdfs:///user/$(id -un)/spark_logs/spark_logs_${timestamp}"
hdfs dfs -mkdir -p "$spark_eventLog_dir_hdfs"

log "running spark-submit"
[[ "$ext_classpath" = /* ]] || ext_classpath=$shared_top/$ext_classpath 
EAS="$ext_classpath"
EXT_CP="$EAS/*:$EAS/classes"

${SPARK_HOME}/bin/spark-submit \
	--driver-memory ${driver_memory:-80g} \
	--executor-memory ${executor_memory:-80g} \
	--conf spark.driver.cores=${driver_cores:-1} \
        --conf spark.executor.extraClassPath="${EXT_CP}" \
        --conf spark.driver.extraClassPath="${EXT_CP}" \
	--conf spark.eventLog.enabled=${eventlog_enabled:-true} \
	--conf spark.eventLog.dir="${spark_eventLog_dir_hdfs}" \
	--conf spark.ui.killEnabled=${kill_enabled:-true} \
	--conf spark.executor.cores=${executor_cores:-1} \
	--num-executors ${num_executors} \
	--conf spark.shuffle.blockTransferService=${shuffle_blocktransferservice:-nio} \
	--conf spark.dynamicAllocation.enabled=${dynamic_allocation_enabled:-false} \
	--conf spark.shuffle.service.enabled=${shuffle_service_enabled:-false} \
	--conf spark.speculation=${speculation:-false} \
	--conf spark.speculation.multiplier=${speculation_multiplier:-2} \
	--class adept.e2e.driver.E2eDriver \
	--master ${master:-yarn} \
        --deploy-mode ${deploymode:-cluster} \
	--queue ${queue:-pool1} \
	--conf spark.storage.blockManagerTimeoutInterval=${storage_blockmanagertimeoutinterval:-100000} \
	"${A2KD_HOME}/lib/adept-e2e.jar" "${input_dir_hdfs}" "${output_dir_hdfs}" ${num_partitions} "$(find /input -maxdepth 1 -type f | wc -l)" "$config_shared"

log "downloading output directory from hdfs"
hdfs dfs -get "${output_dir_hdfs}"

log "removing temporary hdfs directories, a2kd configuration file"
hdfs dfs -rm -r "${input_dir_hdfs}" "${output_dir_hdfs}"
rm -f "$config_shared"

log "spark.eventLog.dir: ${spark_eventLog_dir_hdfs}"
log "wrote output to local directory: ${output_dir_hdfs}"

