# KB-Explorer docker image use

This walk-thorugh assumes you have the kb-explorer docker image installed.

## Starting KB-Explorer

* Choose a port you want the KB-Explorer to listen on. It is an HTTPS traffic. This tutorial assumes you are using port 443.

* Start the docker container. Argument `-p` accepts arguments in the format of `listen_port:internal_port`. The `internal_port` has to be 8443. `--name` can be arbitrary, but command to set the KB.xml file uses the same value:

    `docker run -d -p 443:8443 --name KB_Explorer deft/kb-explorer`

## Adding or changing the KB.xml file

* KB-Explorer can switch between KB.xml files on the fly, without the need to restart the docker container. But you need to copy the file into docker first. Assuming you want to use `/home/deft/newKB.xml` as an input file, run:

    `cat /home/deft/newKB.xml | docker exec -i KB_Explorer sh -c 'cat > /root/owf/apache-tomcat/lib/KB.xml'`

* Wait 30 seconds for the backend to discover the file changes.

