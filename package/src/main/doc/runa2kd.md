runa2kd(1) -- Run an A2KD job in a Cluster
====

NAME
----
runa2kd - process a document corpus through a DEFT pipeline

SYNOPSIS
----
`runa2kd` --config config --shared-top <path> --output-directory <output directory path> --spark-props <spark properties file> [OPTION]...

DESCRIPTION
----
Process the provided corpus of documents and load the results into a knowledgebase for viewing and further analysis. Place all output into the specified output directory, which must exist and be writable by the invoking user when this command is invoked.

OPTIONS
----
 * `-c`, `--config` &lt;path&gt;:
   Required. Path to the A2KD configuration xml file. No default.

 * `-t`, `--shared-top` <path>:
   Required. A path common to all hosts in the cluster under which shared                        directory trees and files will reside. The runa2kd script will create a                        child directory using the login name of the invoking user under this                        directory for the storage of intermediate results and log information.                        If you are storing model files in a central location and sharing them                        across the cluster, they should reside under this directory and the                        classpath specified in the spark properties file should reference the                        appropriate directories under this path. No default.

 * `-o`, `output-dir` <path>:
   Required. A path on the local host under which the output of the runa2kd                        will be placed. The script will create a child directory under this path                        that will be named using a timestamp value so that it can be easily identified.                        This child directory will include intermediate checkpoints, debug logs,                         and other files related to the run.

 * `-s`, `--spark-props` <path>:
   Required. The path to a spark properties file. Any properties specified in                        this file will override the cluster specific settings. Properties not specified                        will be obtained from the default settings in the Spark configuration                         directory. If a property is not defined in either location, a hard-coded                        default value will be used. An example spark properties file is provided in the conf directory provided in the utilities archive.

 * `-p`, `--partitions` <n>:
   Optional. The number of partitions to use while processing the corpus                        through the pipeline. If not specified, the script will set                        the number of partitions to one half of the number of documents in the                        largest document corpus specified in the A2KD configuration file. The option argument must be an integer value.

 * `-S`, `--spark-conf-dir` <path>:
   Optional. The path to the Spark 2 configuration directory for the target                        cluster. This directory contains default cluster-specific configuration settings                        to be used by Spark programs on that cluster. If not specified, runa2kd will                        use the value of the **$SPARK_CONF_DIR** environment variable if set to identify                        a Spark 2 settings directory. If the **$SPARK_CONF_DIR** environment variable                         is not set and the path to a settings directory is not set on the command                         line, the hard-coded Spark default settings will be used.

 * `-H`, `--hadoop-conf-dir` <path>:
   Optional. The path to the HADOOP configuration directory for the target                        cluster. This directory contains default cluster-specific configuration settings                        for the HDFS and HADOOP systems, including the locations of the various services                        that make up the cluster. If not specified, runa2kd will use the value of                         the **$HADOOP_CONF_DIR** environment variable to locate the HADOOP configuration                        directory. If neither specified on the command line nor in the **$HADOOP_CONF_DIR**                        environment variable, runa2kd will attempt to locate the HADOOP configuration directory at **$HADOOP_HOME**/etc/conf and then /etc/hadoop. If runa2kd cannot locate a HADOOP configuration directory after this search, the command will fail.

 * `-v`, `--version`:
   Displays detailed version information for the installed version of **runa2kd**.

 * `-h`, `--help`:
   Displays manual page information similar to this document.

ENVIRONMENT
----

`runa2kd` requires that both `xmllint` and `docker` (with access to a docker server) be installed on your system in order to run. The command will print an error message and exit with a non-zero status code should either not be installed and available on the users' path.

 * **HADOOP_CONF_DIR**:
   Defines the path to a HADOOP configuration directory. This is a standard variable used by many HADOOP installations. It may be overridden with the `-H` option on the command line. A HADOOP configuration directory contains configuration files necessary for the docker image to locate cluster resources and must be available to the **runa2kd** command.

 * **SPARK_CONF_DIR**:
   Defines the path to a Spark configuration directory. This is also a standard variable used by many Spark installations. It may be overridden with the `-S` option on the command line. The Spark configuration directory is an optional location where default parameters for the cluster or the user may be stored. Specific Spark properties may be overridden on a per-command basis via a Spark properties file specified with the `-s` option.

 * **DEFTIMAGE**:
   If defined, specifies the tag of the docker image to run, overriding the default value of `deft/a2kd:latest`. You can use this to select a non-default image for testing or other purposes. If defined, **DEFTIMAGE** will override all the other image selection environment variables described below. For instance, specifying

    `DEFTIMAGE=bbn/a2kd:2.8`

    will cause runa2kd to use that docker image rather than `deft/a2kd:latest`.

 * **A2KD_VERSION**:
   Specifies the version part of the deft/a2kd tag to use instead of `latest`.

EXAMPLES
----
Process the documents as specified by a2kdConfig.xml and place the results in 
the directory 'output'. Use the default Spark and HADOOP settings from 
/etc/hadoop/conf:

\$> runa2kd -c a2kdConfig.xml -t /nfs/shared -o output

Process the documents as specified by a2kdConfig.xml using the provided Spark 
and HADOOP settings and place the results in a new directory under the directory 'output':

\$> runa2kd --config a2kdConfig.xml --shared-top /nfs/shared --spark-props spark.conf  \\<br /> --spark-conf-dir \$HOME/spark/cluster1/conf --hadoop-conf-dir \$HOME/hadoop/cluster1/conf \\<br />  --output-dir output

The same command as above, but use environment variables to define the two 
configuration directories:

\$> export HADOOP_CONF_DIR=\$HOME/hadoop/cluster1/conf<br />
\$> export SPARK_CONF_DIR=\$HOME/spark/cluster1/conf<br />
\$> runa2kd --config a2kdConfig.xml --shared-top /nfs/shared --spark-props spark.conf --output-dir output


