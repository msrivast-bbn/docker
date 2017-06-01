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

if [[ $# -ne 4 ]]; then
	echo "Usage: $(basename $0) <local e2e config file> <local input directory> <num partitions> <num executors>"
	echo "e.g.:"
	echo "  $(basename $0) ./e2e_config.xml ./e2e-inputs 1 1"
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

###
timestamp="$(date +%s)"
log "the UTC timestamp / id of this script execution is ${timestamp}"

if [ ! -d "target" ]; then
	echo "must compile adept-e2e before running this script"
	exit 1
fi

log "processing ${e2e_config}"
e2e_config_shared_directory="/nfs/mercury-04/u40/$(id -un)"
mkdir -p "${e2e_config_shared_directory}"
e2e_config_shared="${e2e_config_shared_directory}/e2e_config_${timestamp}.xml"
cp "${e2e_config}" "${e2e_config_shared}"
for e2e_config_attribute in "metadata_host" "metadata_port" "metadata_db" "metadata_user_name" "metadata_password" "corpus_id" "kb_report_output_dir" "gather_statistics" "stats_file_path"; do
	attribute_value="$(python -c "import re; print re.compile(\"<entry key=\\\"${e2e_config_attribute}\\\">(.*?)</entry>\").findall(open(\"${e2e_config_shared}\").read())[0]")"
	declare "${e2e_config_attribute}"="${attribute_value}"
done

log "creating KB schema"
adept_kb_version=$(python <<-'EOF'
	import re, lxml.etree
	pom_xml=lxml.etree.fromstring(re.sub("<project (.*?)>", "<project>", open("pom.xml").read()))
	adept_kb_version=pom_xml.xpath("/project/dependencies/dependency[artifactId = 'adept-kb']/version")[0].text
	if adept_kb_version == "${project.version}": adept_kb_version = pom_xml.xpath("/project/version")[0].text
	print adept_kb_version
EOF
)
local_maven_repo=$(python <<-'EOF'
	import os, re, lxml.etree
	settings_xml=lxml.etree.fromstring(re.sub("<settings (.*?)>", "<settings>", open(os.path.expanduser("~") + "/.m2/settings.xml").read()))
	local_maven_repo=settings_xml.xpath("/settings/localRepository")[0].text.rstrip("/")
	print local_maven_repo
EOF
)
unzip -p "${local_maven_repo}/adept/adept-kb/${adept_kb_version}/adept-kb-${adept_kb_version}.jar" 'adept/utilities/DEFT KB create schema.txt'\
	| PGPASSWORD="${metadata_password}" psql -d "${metadata_db}" -U "${metadata_user_name}" -h "${metadata_host}" -p ${metadata_port} -f -

adept_e2e_version=$(python <<-'EOF'
	import re, lxml.etree
	pom_xml=lxml.etree.fromstring(re.sub("<project (.*?)>", "<project>", open("pom.xml").read()))
	adept_e2e_version = pom_xml.xpath("/project/version")[0].text
	print adept_e2e_version
EOF
)
input_dir_hdfs="$(basename ${input_dir})_input_${timestamp}"
log "uploading local input directory to hdfs"
hadoop fs -put "${input_dir}" "${input_dir_hdfs}"
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
/var/lib/spark-2.0.0-hadoop2.6/bin/spark-submit \
	--driver-memory 80g \
	--executor-memory 80g \
	--conf spark.executor.extraClassPath="/nfs/mercury-04/u40/msrivast_serif_deliverable/scala_2_11/scala-library-2.11.8.jar:/nfs/mercury-04/u40/msrivast_serif_deliverable/scala_2_10/2.10.6/scala-library-2.10.6.jar" \
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
	--master yarn-cluster \
	--queue pool1 \
	--conf spark.storage.blockManagerTimeoutInterval=100000 \
	"target/adept-e2e-${adept_e2e_version}.jar" "${input_dir_hdfs}" "${output_dir_hdfs}" ${num_partitions} "$(find ${input_dir} -maxdepth 1 -type f | wc -l)" "${e2e_config_shared}"

log "downloading output directory from hdfs"
hadoop fs -get "${output_dir_hdfs}"

log "removing temporary hdfs directories, e2e configuration file"
hadoop fs -rm -r "${input_dir_hdfs}" "${output_dir_hdfs}"
rm "${e2e_config_shared}"

log "spark.eventLog.dir: ${spark_eventLog_dir_hdfs}"
log "wrote output to local directory: ${output_dir_hdfs}"
