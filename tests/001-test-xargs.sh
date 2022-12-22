#!/usr/bin/env bash

set -e
set -u
set -o pipefail

CWD="$(cd -P -- "$(dirname -- "$0")" && pwd -P)"

IMAGE="${1}"
TAG="${2}"
ARCH="${3}"


###
### Load Library
###
# shellcheck disable=SC1090,SC1091
. "${CWD}/.lib.sh"



#---------------------------------------------------------------------------------------------------
# MAIN ENTRYPOINT
#---------------------------------------------------------------------------------------------------

###
### Setup
###
RAND_NAME="$( get_random_name )"

###
### Startup container
###
if ! run "docker run --platform ${ARCH} --name ${RAND_NAME} \
-e DEBUG_ENTRYPOINT=4 \
-e DEBUG_RUNTIME=1 \
--entrypoint=bash \
${IMAGE}:${TAG} -c 'command -v xargs >/dev/null'"; then
	docker logs "${RAND_NAME}" || true
	docker stop "${RAND_NAME}"  >/dev/null 2>&1 || true
	docker rm -f "${RAND_NAME}" >/dev/null 2>&1 || true
	log "fail" "command 'xargs' not found inside image, but required"
	exit 1
fi
echo "command 'xargs' found"


###
### Cleanup
###
docker stop "${RAND_NAME}"  >/dev/null 2>&1
docker rm -f "${RAND_NAME}" >/dev/null 2>&1

log "ok" "Test succeeded"
