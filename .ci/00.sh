#!/usr/bin/env bash

set -e
set -u
set -o pipefail

CWD="$(cd -P -- "$(dirname -- "$0")" && pwd -P)"


###
### Load Library
###
# shellcheck disable=SC1090
. ${CWD}/.lib.sh



###
### Preparation
###
RAND_DIR="$( mktemp -d )"
RAND_NAME="$( get_random_name )"
echo "hello world" > "${RAND_DIR}/index.html"


###
### Build container
###
run "docker build -t ${DOCKER_NAME} ${CWD}/.."


###
### Startup container
###
run "docker run -d --rm \
 -v ${RAND_DIR}:/var/www/default/htdocs \
 -p 127.0.0.1:80:80 \
 -e DEBUG_ENTRYPOINT=2 \
 -e DEBUG_RUNTIME=1 \
 -e NEW_UID=$( id -u ) \
 -e NEW_GID=$( id -g ) \
 --name ${RAND_NAME} ${DOCKER_NAME}"


###
### Tests
###
sleep 5
run "docker ps"
run "docker logs ${RAND_NAME}"
run "curl localhost"
run "curl localhost | grep 'hello world'"


###
### Cleanup
###
run "docker stop ${RAND_NAME}"
