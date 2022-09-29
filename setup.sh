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

# Clean up docker environment
####################################
docker system prune --all


# Pull required docker images
####################################
docker pull postgres:14.2
docker pull apicurio/apicurio-registry-sql:2.0.2.Final
docker pull apicurio/apicurio-registry-sql:2.3.1.Final
