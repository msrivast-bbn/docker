# KB-Explorer setup instructions

This instance of KB-Explorer comes as a docker image. You need a working docker installation to work with KB-Explorer. Some docker installations require you to call docker using `sudo` command - i.e. `sudo docker run deft/kb`. The rest of the document assumes that you do NOT need `sudo` command.

1. Prepare the docker image for use:

    ```
    docker load -i kb_explorer.tar.gz
    ```

2. Verify that a new image has been installed:

    ```
    docker images
    ```

    should list `deft/kb-explorer` with a tag. The tag can be `latest` or a version string.

3. The image will listen on a port. You need to decide what port number to use for it. KB-Explorer is an HTTPS traffic. This tutorial assumes you are using port 443.

4. Start the docker container. Argument `-p` accepts arguments in the format of `listen_port:internal_port`. The `internal_port` has to be 8443. `--name` can be arbitrary, but command to set the KB.xml file uses the same value. You may need to change the tag from `:latest` to a version string:

    ```
    docker run -d -p 443:8443 --name KB_Explorer deft/kb-explorer:latest
    ```

5. KB-Explorer needs an input xml file `KB.xml` that describes host data for the parliament and the postgres databases. The xml file has the following content:

    ```
<?xml version="1.0" encoding="UTF-8"?>
<beans xmlns="http://www.springframework.org/schema/beans"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xmlns:util="http://www.springframework.org/schema/util"
    xsi:schemaLocation="http://www.springframework.org/schema/beans http://www.springframework.org/schema/beans/spring-beans.xsd
    http://www.springframework.org/schema/util http://www.springframework.org/schema/util/spring-util.xsd">

    <util:map id="kbQueryProcessors">
        <!-- To add additional KBs, create more <entry> blocks like this -->
        <entry key="THIS_VALUE_WILL_SHOW_IN_DROP_DOWN_LIST">
            <bean class="adept.kbapi.KB">
                <constructor-arg>
                    <bean class="adept.kbapi.KBParameters">
                        <constructor-arg value="http://parliament.host:PORT/parliament"/>
                        <!-- database_name must match the name of the database in the postgres -->
			<constructor-arg
                            value="jdbc:postgresql://postgres.host:PORT/database_name"/>
                        <constructor-arg value="postgres"/> <!-- postgres username -->
                        <constructor-arg value="password"/> <!-- postgres password -->
			<!-- keep the rest of values as-is -->
                        <constructor-arg value="/sparql"/>
                        <constructor-arg value="/sparql"/>
                        <constructor-arg type="boolean" value="true"/>
                    </bean>
                </constructor-arg>
            </bean>
        </entry>
    </util:map>
</beans>
    ```



6. KB-Explorer can switch between KB.xml files on the fly, without the need to restart the docker container. But you need to copy the file into docker first. Assuming you want to use `/home/deft/newKB.xml` as an input file, run:

    ```
    cat /home/deft/newKB.xml | docker exec -i KB_Explorer sh -c 'cat > /root/owf/apache-tomcat/lib/KB.xml'
    ```

7. Wait 30 seconds for the backend to discover the file changes.

# Accessing KB-Explorer Web Interface

KB Explorer web-interface starts approximately 30 seconds after running the command in (4). After that, you can access it from the same machine by navigating a web-browser to https://127.0.0.1:443/owf/. If the web browser gives a warning about an insecure connection, please force the connection anyway (the instructions for this depend on the web browser you are using). After the connection is established the web interface will ask for a username / password. Please use:

```
Username: testUser1
Password: password
```
