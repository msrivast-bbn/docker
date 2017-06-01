#!/bin/bash
#fill in the values of the following variables to use this script

###################Description of params#########################
if false
then
run_mode='allowed values are local or cluster: local mode runs e2e from the adept-e2e jar on any machine with sufficient memory; cluster mode runs e2e on a spark cluster'
input_dir='input directory path: use a local filesystem path for local mode, or a hadoop filesystem path for cluster mode'
output_dir='output directory path: use a local filesystem path for local mode, or a hadoop filesystem path for cluster mode'
e2e_version='version number, e.g. 2.7.1-SNAPSHOT'
config_file='path to the config file; when using cluster mode, this file should be present on a shared mount e.g. /nfs/mercury-04/u40'
num_partitions='For a handful of files use 1 as the value, otherwise use num_input_files/2'
num_executors='Use a value that makes sense given your cluster and input-size. For local mode, this param is not used'
spark_machine='Allowed values are d403 if running Spark from d403, and d405 if running Spark from d405. This param is used to set appropriate memory and number of cores for the e2e run. Ignored for local mode.'
fi

###Set your params here--overwrite the sample values:
run_mode=cluster
input_dir=/user/msrivast/sample_input
output_dir=/user/msrivast/sample_output
e2e_version=2.7.1-SNAPSHOT
config_file=/nfs/mercury-04/u40/e2e_config.xml
num_partitions=1
num_executors=1
spark_machine=d403

if [[ "$run_mode" == "cluster" ]]
 then
 if [[ "$spark_machine" == 'd403' ]]
  then
   memory=80g
   memoryOverhead=18432
   driver_cores=5
 elif [[ "$spark_machine" == 'd405' ]]
  then
   memory=60g
   memoryOverhead=10240
   driver_cores=1
 fi
 cmd='/var/lib/spark-2.0.0-hadoop2.6/bin/spark-submit --driver-memory '$memory' --executor-memory '$memory' --conf spark.yarn.driver.memoryOverhead='$memoryOverhead' --conf spark.yarn.executor.memoryOverhead='$memoryOverhead' --conf spark.executor.extraClassPath="/nfs/mercury-04/u40/msrivast_serif_deliverable/scala_2_11/scala-library-2.11.8.jar:/nfs/mercury-04/u40/msrivast_serif_deliverable/scala_2_10/2.10.6/scala-library-2.10.6.jar" --conf spark.driver.cores='$driver_cores' --conf spark.ui.killEnabled=true --conf spark.executor.cores=1 --num-executors '$num_executors' --conf spark.shuffle.blockTransferService=nio --class adept.e2e.driver.E2eDriver --master yarn-cluster --queue pool1 --conf spark.storage.blockManagerTimeoutInterval=100000 target/adept-e2e-'$e2e_version'.jar '$input_dir' '$output_dir' '$num_partitions' '$num_partitions' '$config_file
elif [[ "$run_mode" == 'local' ]]
 then
 cmd=$JAVA_HOME'/bin/java -Xmx24G -cp target/adept-e2e-'$e2e_version'.jar:/nfs/mercury-04/u40/msrivast_serif_deliverable/scala_2_11/scala-library-2.11.8.jar:/nfs/mercury-04/u40/msrivast_serif_deliverable/scala_2_10/2.10.6/scala-library-2.10.6.jar adept.e2e.driver.E2eDriver '$input_dir' '$output_dir' '$num_partitions' '$num_partitions' '$config_file' local'
fi
echo "Running the following command:"
echo $cmd
$cmd
