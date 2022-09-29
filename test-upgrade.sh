#!/bin/sh

# Set up docker command
####################################
DOCKER=docker
if command -v winpty &> /dev/null
then
    echo "Found 'winpty', using it via:  'winpty docker'"
    DOCKER="winpty docker"
fi
if [ "x$DOCKER_CMD" != "x" ]
then
    echo "Override for 'docker' detected.  Using: '$DOCKER_CMD'"
    DOCKER=$DOCKER_CMD
fi


# Start postgresql
####################################
echo "STARTING PostgreSQL..."
PG_ID=`docker run -itd \
  -e POSTGRES_USER=dbuser \
  -e POSTGRES_PASSWORD=dbp4ss \
  -e POSTGRES_DB=registry \
  -p 5432:5432 \
  --name postgresql \
  postgres:14.2`
echo "PG is started, container id is $PG_ID"
echo "Getting PG IP Address"
PG_IP=`docker inspect $PG_ID | jq -r ".[0].NetworkSettings.Networks.bridge.IPAddress"`
echo "PG IP Address is $PG_IP"
echo "Giving PG some time to startup..."
sleep 2


# Start Apicurio Registry 2.0.2.Final
####################################
echo "STARTING Apicurio Registry 2.0.2.Final..."
docker run -itd -p 8080:8080 \
  -e "REGISTRY_DATASOURCE_URL=jdbc:postgresql://$PG_IP:5432/registry" \
  -e "REGISTRY_DATASOURCE_USERNAME=dbuser" \
  -e "REGISTRY_DATASOURCE_PASSWORD=dbp4ss" \
  -e "REGISTRY_LOG_LEVEL=DEBUG" \
  --name registry202 \
  apicurio/apicurio-registry-sql:2.0.2.Final
echo "Sleeping for 5s - waiting for Registry to start up."
sleep 5


# Create some artifacts, configure rules, etc.
####################################
curl -X GET  http://localhost:8080/apis/registry/v2/system/info | jq
curl -X POST http://localhost:8080/apis/registry/v2/admin/rules \
  -H 'Content-Type: application/json' \
  -d '{"type":"VALIDITY","config":"FULL"}' | jq
curl -X POST http://localhost:8080/apis/registry/v2/groups/default/artifacts \
  -H 'Content-Type: application/json' \
  -H 'X-Registry-ArtifactId: my-avro-schema' \
  -d @schemas/avro-v1.json | jq
curl -X POST http://localhost:8080/apis/registry/v2/groups/default/artifacts/my-avro-schema/versions \
  -H 'Content-Type: application/json' \
  -d @schemas/avro-v2.json | jq
curl -X GET  http://localhost:8080/apis/registry/v2/search/artifacts | jq
curl -X GET  http://localhost:8080/apis/registry/v2/admin/rules | jq
curl -X GET  http://localhost:8080/apis/registry/v2/groups/default/artifacts/my-avro-schema | jq
curl -X GET  http://localhost:8080/apis/registry/v2/groups/default/artifacts/my-avro-schema/meta | jq
curl -X GET  http://localhost:8080/apis/registry/v2/groups/default/artifacts/my-avro-schema/versions | jq


# Stop the Registry and startup the new 2.3.1.Final version
####################################
echo "STOPPING Apicurio Registry 2.0.2.Final..."
docker stop registry202
echo "STARTING Apicurio Registry 2.3.1.Final..."
docker run -itd -p 8080:8080 \
  -e "REGISTRY_DATASOURCE_URL=jdbc:postgresql://$PG_IP:5432/registry" \
  -e "REGISTRY_DATASOURCE_USERNAME=dbuser" \
  -e "REGISTRY_DATASOURCE_PASSWORD=dbp4ss" \
  -e "REGISTRY_LOG_LEVEL=DEBUG" \
  --name registry231 \
  apicurio/apicurio-registry-sql:2.3.1.Final
echo "Sleeping for 5s - waiting for Registry to start up."
sleep 5


# Validate that the upgrade worked and the registry is still working
####################################
curl -X GET http://localhost:8080/apis/registry/v2/system/info
curl -X GET  http://localhost:8080/apis/registry/v2/admin/rules | jq
curl -X GET  http://localhost:8080/apis/registry/v2/search/artifacts | jq
curl -X GET  http://localhost:8080/apis/registry/v2/groups/default/artifacts/my-avro-schema | jq
curl -X GET  http://localhost:8080/apis/registry/v2/groups/default/artifacts/my-avro-schema/meta | jq
curl -X GET  http://localhost:8080/apis/registry/v2/groups/default/artifacts/my-avro-schema/versions | jq
