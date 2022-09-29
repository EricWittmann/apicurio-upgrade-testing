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


# Pull required docker images
####################################
docker stop postgresql
docker stop registry202
docker stop registry231


# Clean up docker environment
####################################
docker system prune
