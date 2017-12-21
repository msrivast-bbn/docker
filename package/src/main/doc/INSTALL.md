# DEFT Installation and Operation #

# INTRODUCTION #

This document describes how to install and run the Deep Exploration and
Filtering of Text (DEFT) ADEPT Automatic Knowledge Discovery (A2KD) system. The 
system takes in a set of documents and extracts:

 - Entities, for example, of the type Person, Location, or GeoPoliticalEntity,
 - Relations, for example, of the type 'Resident (location, person)',
 - and Events, for example, of the type 'Meet (place, entity)', 'Attack (time)'.

This document makes the following assumptions of the person who is doing 
the installation:

 - you are familiar with Linux commands; and
 - you have docker privileges on a docker host in your site

See PREREQUISITES below for software required but not included in this 
installation package.

For questions or comments, please contact:

Name          | Email                     | Work Phone
--------------|---------------------------|--------------
John Griffith | john.griffith@raytheon.com|(617) 873-2939
Roger Bock    | roger.bock@raytheon.com   |(603) 873-8009

# BILL OF MATERIALS #

The following is a list of the files you will need to obtain from the
BBN SFTP Site in order to install DEFT:

1. Exported Docker Images:
    - KnowledgeBase (deft_kb.tar.xz)
    - KB Explorer (deft_kb-explorer.tar.xz)
    - A2KD (deft_a2kd.tar.xz) 
<br/><br/>
2. External Model and Data Tree (split and compressed tar archive MODEL.tar.xz.0xx)

3. Tarball containing local (client) commands and configurations: deft-utilities.tar.gz. Includes:
    - DB Creation Script (bin/DEFTCreateUserDB.sh)
    - runa2kd script (bin/runa2kd)
    - Example configuration files under the conf directory
    - Other scripts under bin
<br/><br/>
4. The **runkb** script and its documentation

# PREREQUISITES #

This list identifies software that must be installed on a set of systems
before installation of the A2KD software can begin. Basically, you must
first stand up a Spark/Yarn/HADOOP cluster before starting the installation
of A2KD itself.

1. Java 1.8

2. HADOOP 2.6 or later (can be Cloudera CDH 5.3+)  
   **NOTE:** Cloudera CDH 5.3+ includes Java 1.7 only. If you use the Cloudera
   Manager to install your HADOOP and Spark components, then you must upgrade
   the version of Java it uses. See
   [this document](https://www.cloudera.com/documentation/enterprise/5-3-x/topics/cdh_cm_upgrading_to_jdk8.html "this") for details on how to upgrade your cluster.

3. Spark 2.0.0 build for Hadoop 2.6 (Cloudera Spark2 2.0.0 r2 as well).

4. Hadoop uses many ports for monitoring and control. All nodes in the cluster
   require access to many ports on every other node. The docker nodes
   will require similar access to monitoring ports on every cluster node.
   Configuring HADOOP for security is covered in the Cloudera documentation.

5. A common, shared filesystem (typically an NFS mount) accessible from every 
   node in the cluster and the docker client hosts. This filesystem is used for 
   logging and report files as well as to support the algorithm model files and 
   resources.

6. A home directory in the for HADOOP file system for every user submitting
   A2KD jobs. This directory - typically /user/<login> - provides temporary
   storage for A2KD during processing. Each user requires full access to their
   home directory.

7. A host with docker installed. This host does NOT have to be a cluster 
   member. This docker host will run the A2KD image for the duration of the job. 
   Note that the docker daemon does not have to actually run on this specific host 
   - there are methods to run docker containers on remote hosts, but we will assume 
   that the same host will be used as a docker server and as the primary user
   workstation. 
   - NOTE: There is a known issue with Cloudera SCM whereby the Docker daemon 
    and the SCM conflict with each other when running in the same host due to
    a problem with the use of the tmpfs file system. This does not interfere
    with the Cloudera software running as a docker image (which is the preferred
    quickstart method offered by Cloudera at this time) but may prevent the same
    physical or virtual host from running both simultaneously. Cloudera is 
    aware of the issue and as of August, 2017 they have fixed the issue in their
    patch stream. We do not yet know what release(s) will contain the fix.

8. optional - A host with a web browser installed for monitoring and debugging
   A2KD and the cluster. This host requires access to the HADOOP ports 
   on the YARN master and each of the executor hosts in the cluster at a 
   minimum. This can be the same host as the primary user workstation.

9. The preferred method for starting KB Containers is now through the use of
   the **runkb** script. In order to use this script, the host it is run on
   must have **docker** and **xmllint** installed.

    If you intend to use older versions of the KB image, or want to manually 
   configure the database in an already started KB Container, you should use 
   the DEFTCreateUserDB script. Use of this script requires that the host you 
   intend to run it on must have **wget**, **xmllint** and the **psql** program 
   (from the postgresql-client package) installed. Most often this will be the
   primary user workstation mentioned above.

10. The files containing the A2KD software are provided with SHA256 checksum
    files in order to help verify that they have not been corrupted in the
    process of transmission. A sha256sum utility is required to enable you
    to verify downloaded files.  

# A NOTE ON CLOUDERA-BASED INSTALLATIONS #

The Cloudera Manager and package set provides a powerful means of installing,
managing and monitoring a HADOOP/Spark cluster. If you want to use the
Cloudera framework, here are some things to remember:

1. You must use Cloudera CDH 5.7 or later. If you are installing a new cluster
from scratch, we recommend the latest available version of Cloudera 5 (5.11
as of the writing of this document.) You should install or upgrade to CDH 5.9
or later.

2. You must use Cloudera Manager 5.8.3, 5.9, or higher in order to support
Spark 2.

3. Cloudera 5 installs with Java 1.7 integrated. You must upgrade the cluster
to Java 1.8. Follow the instructions provided by Cloudera in their docs.
Try to install the latest version of Java 1.8 supported for your CDH release
(see the product and version release support matrix in the release notes for
your release.)

4. Cloudera 5 installs with Spark 1.7 as of 5.11. You must upgrade the cluster
to add Spark 2.0.0 build for Hadoop 2.6 (Cloudera 2.0.0 r2) CSD and parcel to your installation. 
Follow the directions
[here](https://www.cloudera.com/documentation/spark2/latest/topics/spark2_installing.html)
in order to install Spark 2. We recommend installing the Spark 2.0 
Release 2 Cloudera (2.0.0 Cloudera2) parcel as of the time of this note.

Once the cluster software has been installed and deployed and your cluster has been
configured, we recommend you run through one of the tutorials on the Cloudera
or HADOOP websites to ensure the cluster is operating correctly and that
you are familiar with the commands and administrative interfaces necessary
to submit and monitor jobs. 

# DOWNLOAD #

The A2KD system is available on an FTP site accessible to authorized users.
Once you have obtained the URL and credentials for the site, you will need
to ensure you have approximately 60GB of space to download the files to.

The time to download the files will vary according to the quality of your
internet connection. We recommend you use an FTP client that has restart/resume
capability so that if a download is interrupted, the download can be resumed 
instead of having to be restarted from the beginning.

The files needed to be downloaded are:

 - deft_kb-&lt;version&gt;.tar.xz:
   The saved docker image for the knowledgebase server
 - deft_kb-explorer.&lt;version&gt;.tar.xz:
   The saved docker image for the KB Explorer GUI Front End
 - deft_a2kd-&lt;version&gt;.tar.xz:
   The saved docker image for the A2KD Processor
 - deft-utilities-&lt;version&gt;.tgz:
   A tar archive containing utilities and libraries to be installed on the primary user workstation.
 - runkb:
   The runkb program.
 - INSTALL.*:
   Updated versions of this document in various formats
 - *.md, *.html, *.pdf:
   Documentation for the commands and the system
 - tendocs.tgz:
   A 10 document verification run that contains a set of input documents and the output an A2KD run produced.
 - 1K_doc.tgz:
   A 1000 document verification run that contains a set of input documents and the output an A2KD run produced.
 - adept-{api,kb}-<version>-{sources,javadoc}.jar:
   ADEPT Javadoc and source files used for this release. Note that the release of ADEPT does not necessarily match that of the images.
 - all_sha256sum:
   The hash values for the files listed above.

In addition, the FTP site contains a **model** directory containing a split 
archive file (13 parts) and a sha256sum file with hashes for all the parts. 
These files have not changed since mid-August 2017.

Once the files have been downloaded along with the checksum file, you
should verify their integrity of the file using the *sha256sum* command:

    sha256sum --check all.sha256sum

If you downloaded the model files, you can also verify them with a similar command:

    sha256sum --check MODEL.tar.xz.parts.sha256sum

Any other files provided on this FTP site should be considered informational and
optional in nature.
 
# INSTALLATION #

Once the cluster has been set up, properly configured and verified, and the 
above files have been downloaded and verified, the next step is to install the 
A2KD system. For an initial installation, all these files can be installed on a 
single docker-capable host by a user with access to the docker subsystem. A more 
distributed approach may be desirable once the operators, administrators and users 
are familiar with the system and have identified a reasonable set of goals to 
be achieved by doing so.

1. Install the model directory tree in your cluster. The model tree will
require approximately 146GB of space on disk, and must be accessible from
every node in the cluster using the same path. This can be accomplished in
several ways:

    - Install the tree at the same path on each and every node in the cluster, or
    - Install the tree on a shared file system (i.e., NFS) and ensure that mount is 
    accessible using the same path on every host.

    The former approach might provide better performance as the hosts are not
competing for network bandwidth and disk access over the same resource. The
latter option minimizes the amount of total disk space consumed by these
files. The BBN installation uses the latter option, but each end user must
choose according to their own needs and resources.

    To install the model and class directory tree, change your working 
directory to the location you have chosen. Ensure you have about 146GB
available at that location:

        $> df -h .
        Filesystem             Size  Used   Avail Use% Mounted on
        mongo-22.bbn.com:/u40  500G  127G  374G    26% /nfs/mongo-22/u40

    The model tarball can then be unpacked:

        $> cat <download dir>/MODEL.tar.xz.0?? | tar -xJf -

    If your version of tar does not support xz compression, you may also
use the following command:

        $> cat <download dir>/MODEL.tar.xz.0?? | xz -d | tar -xf -

2. Install docker images on the docker host/primary user workstation:

        $> docker load < deft_kb.tar.xz (note returned SHA1 for new image)
        $> docker tag <sha1 above> deft/kb:latest
        $> docker load < deft_a2kd.tar.xz (note returned SHA1 for new image)
        $> docker tag <sha1> deft/a2kd:latest
        $> docker load < kb-explorer.tar.xz (note returned SHA1 for new image)
        $> docker tag <sha1> deft/kb-explorer:latest
   
    When loaded, the images will have 'internal' tags associated with them that
    identify the build date. These may be retained or removed as desired. If you 
    need to identify a specific version of the image for the purposes of issue
    reporting, you can run the image with the 'version' argument to obtain detailed
    version information or use the docker inspect command:

        $> docker run -it --rm deft/kb:latest version

    or

        $> docker inspect deft/kb:latest


    Note that you may also tag the same image with another version ID if you want to
    maintain historical versions of each image. The newest images should
    be assigned the 'latest' tag when you have decided to transition to using them. 
    If you already have an image of the same name and a 'latest' tag, you can add the 
    -f option to the tag command to force the tag to be moved to your newly loaded image.

3. Install the utility tree into a directory on the primary user workstation or a shared 
location accessible from your primary user workstation:

        # select or create a top level directory (your home directory is fine)
        $> export A2KD_HOME=<directory>
        $> mkdir -p $A2KD_HOME
        $> tar -C $A2KD_HOME -xf a2kd-utilities.tgz
        $> export PATH=$PATH:$A2KD_HOME/bin

4. Copy/Move the **runkb** command into the $A2KD_HOME/bin directory and ensure 
that its permissions include read and execute for all authorized users.

The A2KD system is ready for use at this point.

# RUNNING AN A2KD JOB #

The A2KD system processes a set of documents contained in a specified directory,
populating the knowledge base identified in the configuration file. To perform
a run of the A2KD system over a new corpus, the following steps are must
be completed.

1. Create an A2KD configuration file for your A2KD run. A template for this file
   is provided in the file A2KD_HOME/conf/a2kd_config_template.xml.
   Copy the template to a work directory and open an editor on it. You will need to specify:
   - The languages to be processed, and for each language:
      - The directory containing the input files
      - Information about each algorithm available to run including it's type, implementing class and configuration file location
      - The algorithms to run
   - The address and login parameters for the PostgreSQL database and the Parliament Server
   - Various other parameters as documented in the template file.

1. Start and initialize the knowledge base (deft/kb) image on your primary user workstation:

        runkb a2kd_config.xml
    
   Parliament is the triple store used in conjunction with Postgres to store the 
   Knowledge Base (KB). For more general information on Parliament, see:

   http://parliament.semwebcentral.org/
 
2. Identify the location of the HADOOP configuration directory and
   ensure it is accessible from the host you will be running runa2kd on. If
   it is NOT in the standard location (/etc/hadoop/conf) ensure its location is
   defined in the HADOOP_CONF_DIR environment variable (this is standard for HADOOP) or specify it on the command line using the `-H` option.

    If the primary user workstation is not a cluster member, you should copy
    the content of those directories to the primary user workstation from any host in
    the cluster. Then set HADOOP_CONF_DIR to this local path.

3. Create a Spark configuration file. You can start with the template located in 
   A2KD_HOME/conf/spark.template.conf. The template contains an explanation of the
   properties you will primarily be interested in and an initial set of values
   for them.

4. If you want to run the KB Resolver stage, you will need to add a KBResolver configuration file as well. A template is provided in A2KD_HOME/conf/kbresolver_properties.template.xml. Copy the file, edit it, and then modify the kb_resolver_config element in the A2KD cofiguration file you created above to contain
the path to this KB Resolver configuration file.

5. Start the run:

        runa2kd -o <output directory> -c <configuration file path> -s <spark configuration file path> -t <shared_top_path> -H <hadoop_conf_path>

    where the parameters are:
      - output_directory - a directory to place the output in. runa2kd will create this if it is not already present.
      - configuration file path - the path to your A2KD configuration file
      - spark configuration file path - the path to your Spark configuration file.
      - shared_top_path - the path to the top of the shared directory tree.
      - hadoop_conf_path - the path to the HADOOP configuration directory.

# Verifying your Installation #
   
A sample data set called 'tendoc' has been provided in a tarball available from the
FTP site. To verify your installation, unpack the tarball into a location
on your system and execute a run using the input child directory in that
archive as your input data directory. The output results we obtained here at
BBN are provided in the output child directory in the archive. Comparing the
summary.txt files under the kb_report directories in both runs should provide some
assurance that the software and system are installed and operating correctly.

# Performance Testing the A2KD Cluster #

We conducted performance testing using the data provided on the FTP site in 1k_doc.tgz. With a single-node cluster using 5 executors, 2 CPUs and 40GB per container, we were able to process this 1017 document corpus in just over 2 hours total, or roughly 500 documents per hour, just under 10 documents per minute.

This corpus can be useful for tuning your own Spark cluster as needed. 

# Using the KB Explorer #

## KB Explorer Quickstart ##

The KB Explorer web application has also been provided. You must indicate the location
of the knowledgebase servers using a copy of the KB.xml file, provided in the
utilities jar under the **conf** directory. The instructions in the KB.xml
template should provide enough information to set the required parameters
correctly.

Start the image with:

     sudo docker run -d --restart=always -p 8443:8443 -v <path to KB.xml>:/root/owf/apache-tomcat/lib/KB.xml deft/kb-explorer:latest

You can then edit the KB.xml file in your local file system to add, remove, or edit KB instances.

If you want to maintain the KB.xml file in the container itself, use the following command the docker image:

     sudo docker run -d --restart=always -p 8443:8443 deft/kb-explorer:latest

Since the configuration file in this case resides in the container file system, you must login to the system and edit it there:

     sudo docker exec -it <name> sh
     cd /root/owf/apache-tomcat/lib
     vi KB.xml
Make your changes and save the file. 

Then, navigate your browser to: 

     http://<docker host>:8443/owf

## Updating the KB Locations in the KB Explorer

When maintaining the KB.xml file on the container file system, you can still maintain a copy of it on your host file system and copy it to the container using a simple command. Update a local copy of the KB.xml file with your new kb name, database access parameters and network location information, then execute the following command:

`$> cat /home/deft/newKB.xml | docker exec -i KB_Explorer sh -c 'cat > /root/owf/apache-tomcat/lib/KB.xml'`

The new values should show up in the KB Explorer in about 30 seconds.

## User Accounts in KB Explorer

By default, the following accounts are available.

  * testAdmin1/password
  * testUser1/password
  * testUser2/password
  * testUser3/password

If these accounts are not sufficient, you can use the '-v' docker option to
override /root/owf/apache-tomcat/lib/users.properties in the container.
