#!/usr/bin/env bash

set -e
set -u
set -o pipefail

CWD="$(cd -P -- "$(dirname -- "$0")" && pwd -P)"

IMAGE="${1}"
#NAME="${2}"
#VERSION="${3}"
TAG="${4}"
ARCH="${5}"


HOST_PORT="8093"

###
### Load Library
###
# shellcheck disable=SC1091
. "${CWD}/.lib.sh"



###
### Preparation
###
RAND_DIR="$( mktemp -d )"
RAND_NAME="$( get_random_name )"
run "echo \"hello world via html\" > ${RAND_DIR}/index.html"


###
### Startup container
###
run "docker run --rm --platform ${ARCH} \
 -v ${RAND_DIR}:/var/www/default/htdocs \
 -p 127.0.0.1:${HOST_PORT}:80 \
 -e DEBUG_ENTRYPOINT=2 \
 -e DEBUG_RUNTIME=1 \
 -e NEW_UID=$( id -u ) \
 -e NEW_GID=$( id -g ) \
 --name ${RAND_NAME} ${IMAGE}:${TAG} &"


###
### Tests
###
WAIT=120
INDEX=0
printf "Testing connectivity"
while ! curl -sS "http://localhost:${HOST_PORT}" 2>/dev/null | grep 'hello world via html'; do
	printf "."
	if [ "${INDEX}" = "${WAIT}" ]; then
		printf "\\n"
		run "docker logs ${RAND_NAME}" || true
		run "docker stop ${RAND_NAME}" || true
		echo "Error"
		exit 1
	fi
	INDEX=$(( INDEX + 1 ))
	sleep 1
done
printf "\\n[OK]  Test success\\n"

###
### Cleanup
###
run "docker stop ${RAND_NAME}"
