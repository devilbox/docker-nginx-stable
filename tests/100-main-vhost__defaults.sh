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
### GLOBALS
###
HOST_PORT_HTTP="8093"
TEXT_EXPECT="hello world via http"

###
### Create HTML file
###
RAND_DIR="$( tmp_dir )"
RAND_NAME="$( get_random_name )"
run "echo \"${TEXT_EXPECT}\" > ${RAND_DIR}/index.html"


###
### Start Container
###
run "docker run -d --platform ${ARCH} --name ${RAND_NAME} \
-v ${RAND_DIR}:/var/www/default/htdocs \
-p 127.0.0.1:${HOST_PORT_HTTP}:80 \
-e DEBUG_ENTRYPOINT=4 \
-e DEBUG_RUNTIME=2 \
${IMAGE}:${TAG} >/dev/null"


###
### Test
###
if ! while_retry "curl -sS 'http://localhost:${HOST_PORT_HTTP}' 2>/dev/null | grep '${TEXT_EXPECT}'"; then
	docker logs "${RAND_NAME}" || true
	docker stop "${RAND_NAME}"  >/dev/null 2>&1 || true
	docker rm -f "${RAND_NAME}" >/dev/null 2>&1 || true
	log "fail" "'${TEXT_EXPECT}' not found in http://localhost:${HOST_PORT_HTTP}"
	exit 1
fi

if docker logs "${RAND_NAME}" 2>&1 | grep -Eq '\[FAILURE|FAIL|ERROR|ERR\]'; then
	docker logs "${RAND_NAME}" || true
	docker stop "${RAND_NAME}"  >/dev/null 2>&1 || true
	docker rm -f "${RAND_NAME}" >/dev/null 2>&1 || true
	log "fail" "Errors found in docker logs"
	echo "[FAILED] Errors found in docker logs"
	exit 1
fi


###
### Cleanup
###
docker stop "${RAND_NAME}"  >/dev/null 2>&1
docker rm -f "${RAND_NAME}" >/dev/null 2>&1

log "ok" "Test succeeded"
