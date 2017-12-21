# KB database setup instructions

This database comes as a docker image. You need a working docker instance to deploy this database. Some docker installations require you to call docker using `sudo` command - i.e. `sudo docker run deft/kb`. The rest of the document assumes that you do NOT need `sudo` command.

1. Prepare the docker image for use:

    ```
	docker load -i deft_kb.tar.gz
	```

2. Verify that a new image has been loaded:

    ```
	docker images
	```

    should list `deft/kb`

3. The image will listen on two ports - one for triple store, another for postgresql databases. You need to decide what port number to use for these services. For the following commands substitute `${TRIPLE_PORT}` for the triple store port and `${PSQL_PORT}` for the PostgreSQL port. Substitute the machine's IP address or hostname for `${KB_HOST}`. Come up with a password and substitute it for `${PSQL_PASSWORD}`.

4. Run the docker container. Substitute a possword of your chooosing for ${PSQL_PASSWORD}:

    `docker run -p ${PSQL_PORT}:5432 -p ${TRIPLE_PORT}:8089 -d --restart=always -e POSTGRES_PASSWORD=${PSQL_PASSWORD} deft/kb:latest`

5. Wait for the database to come up. You can verify that the triple store is up and running by navigating your web-browser to `http://${KB_HOST}:${TRIPLE_PORT}/postgres`. You need a PostgreSQL client in order to access Postgres database. Generally, it is called `psql`. If you do not have PostgreSQL client installed on a machine, please install it. You can verify that the Postgres database is running by calling `psql -h ${KB_HOST} -p ${PSQL_PORT} -U postgres` and typing in the `${PSQL_PASSWORD}` when prompted. Make sure to substitute `${}` items for their proper values.

6. BBN uses a `DEFTCreateUserDB.sh` script to populate the postgres database with pre-defined values. If you do NOT need them, omit steps 6-7. If you do need those values - create the a2kd config file if you haven't yet. There is a `Sample_config.xml` file in the same folder as this readme. You can edit it and make sure it contains the following:

    ```
	<kb_config clear_kb="true" corpus_id="smoke_test">
		<triple_store url="http://${KB_HOST}:${TRIPLE_PORT}/parliament"/>
		<metadata_db host="${KB_HOST}" port="${PSQL_PORT}" dbName="kb_results" username="postgres" password="${PSQL_PASSWORD}"/>
	</kb_config>
    ```

7. Create proper database usernames by running `DEFTCreateUserDB.sh` that was shipped with this readme file on the a2kd file created in previous step:

    ```
	./DEFTCreateUserDB.sh a2kd_config.xml
	```

8. You are now ready to run a2kd with this database.

Every time a2kd is run, it will populate the database with extracted data. Before each additional run of the a2dk you need to clean the database. You can acheive it by either choosing different ports and going through steps 3-8 of this file, OR only going through steps 7-8 of this file. The latter will delete any data that a2kd previously stored in the database.
