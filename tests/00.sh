#!/usr/bin/env bash

set -e
set -u
set -o pipefail

CWD="$(cd -P -- "$(dirname -- "$0")" && pwd -P)"
DOCKER_NAME="${1}"
ARCH="${2}"


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
run "echo \"hello world\" > ${RAND_DIR}/index.html"


###
### Startup container
###
run "docker run -d --rm --platform ${ARCH} \
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
run "sleep 20"  # Startup-time is longer on cross-platform
run "docker ps"
run "docker logs ${RAND_NAME}"
run "curl -sS localhost/index.html"
run "curl -sS localhost/index.html | grep 'hello world'"


###
### Cleanup
###
run "docker stop ${RAND_NAME}"
