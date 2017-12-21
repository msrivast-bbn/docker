runkb(1) -- Start and initialize a KnowledgeBase (KB) Service Instance
====

NAME
----
runkb - Start and initialize a KnowledgeBase (KB) Service Instance

SYNOPSIS
----
`runkb` [ -d <data_directory_path>] configuration_file_path

DESCRIPTION
----
**runkb** will extract the pertinent information from an **a2kd_config** file, validate it, verify that a KB instance with the specified characteristics can be created, and create it. When **runkb** completes, the KB server is running and contains a database ready to receive processed data from **runa2kd** runs. There is no need to use the **DEFTCreateUserDB** utility to complete database initialization on a KB created with **runkb**.

OPTIONS
----
 * `-d` &lt;data_directory_path&gt;:
   Optional. If specified, the data storage directories for both the Parliament and the PostgreSQL servers will be stored under the specified directory. The invoking user must have permissions to create this directory if necessary and be its owner if it already exists.

 * `-v`, `--version`:
   Optional. Displays detailed version information for the installed version of **runkb**.

 * `-h`, `--help`:
   Displays manual page information similar to this document.

DETAILS 
----

A2KD stores processed information in a KnowledgeBase (KB) that consists of two services - a database designed to store 'triples' (subject/predicate/object relationships) and a second database designed to store relational data. The A2KD KB Server is a Docker image that provides these two services, the former provided by a Parliament database server, and the latter provided by a PostgreSQL server.

When selecting a Docker KB image to run, **runkb** will first attempt to start an image with a type label of 'KB' and a version label with a version that matches that defined in the **runkb** command. If that fails, **runkb** will use the newest image on the docker system with a type label of 'KB'. If no images with a type label of 'KB' are found, **runkb** will fail.
 
While more complex setups are possible, **runkb** supports the simplest configuration where a single KB server instance supports a single **corpus** of processed documents. A corpus consists of a set of documents that contain information of interest related to a particular subject area or source - the content of a corpus is completely up to the end user. One or more runs of the A2KD system (**runa2kd**) create and expand a corpus. One or more corpora may be examined using the **kb-explorer**.

The data to be processed and the metadata necessary to access a KB instance are defined in an *a2kd configuration file*, an example of which is provided in the A2KD utilities archive as **conf/a2kd_config.template.xml**. This file must be customized for each corpus in order to be processed by **runa2kd**. **runkb** uses this file to create a KB instance that can be used for the corpus defined therein.


ENVIRONMENT
----

**runkb** executes the **docker** command in order to create and initialize the KB instance in a Docker container. The operation of the docker command is affected by the DOCKER_HOST, DOCKER_CERT_PATH and the DOCKER_TLS_VERIFY environment variables.

If the a2kd configuration file specifies a host that does NOT match that specified in the DOCKER_HOST environment variable, **runkb** will modify its content to match the configuration file specification and attempt communications again. If this fails, **runkb** will exit with an error message.

EXAMPLES
----
Create a KB instance using the access parameters specified in the configuration file, storing the data 
within the container:

\$> runkb kbConfig.xml 

Create a KB using the access parameters specified in the configuration file, storing the data 
in the mounted NFS system at the specified path:

\$> runkb -d /nfs/custServ-01/data/corpus01 kbConfig.xml 
