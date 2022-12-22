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
TEXT_EXPECT="hello world via http and php"


###
### Create PHP files
###
RAND_DIR="$( tmp_dir )"
RAND_NAME1="$( get_random_name )"
RAND_NAME2="$( get_random_name )"
run "echo \"<?php echo '${TEXT_EXPECT}';\" > ${RAND_DIR}/index.php"


###
### Startup container
###
run "docker run -d --platform ${ARCH} --name ${RAND_NAME1} \
-v ${RAND_DIR}:/var/www/default/htdocs \
devilbox/php-fpm-8.1 >/dev/null"

run "docker run -d --platform ${ARCH} --name ${RAND_NAME2} \
-v ${RAND_DIR}:/var/www/default/htdocs \
-p 127.0.0.1:${HOST_PORT_HTTP}:80 \
-e DEBUG_ENTRYPOINT=4 \
-e DEBUG_RUNTIME=2 \
-e MAIN_VHOST_BACKEND=conf:phpfpm:tcp:${RAND_NAME1}:9000 \
--link ${RAND_NAME1} \
${IMAGE}:${TAG} >/dev/null"


###
### Test
###
if ! while_retry "curl -sS 'http://localhost:${HOST_PORT_HTTP}' 2>/dev/null | grep '${TEXT_EXPECT}'"; then
	docker logs "${RAND_NAME1}" || true
	docker logs "${RAND_NAME2}" || true
	docker stop "${RAND_NAME1}"  >/dev/null 2>&1 || true
	docker stop "${RAND_NAME2}"  >/dev/null 2>&1 || true
	docker rm -f "${RAND_NAME1}" >/dev/null 2>&1 || true
	docker rm -f "${RAND_NAME2}" >/dev/null 2>&1 || true
	log "fail" "'${TEXT_EXPECT}' not found in http://localhost:${HOST_PORT_HTTP}"
	exit 1
fi

if docker logs "${RAND_NAME1}" 2>&1 | grep -Eq '\[FAILURE|FAIL|ERROR|ERR\]'; then
	docker logs "${RAND_NAME1}" || true
	docker logs "${RAND_NAME2}" || true
	docker stop "${RAND_NAME1}"  >/dev/null 2>&1 || true
	docker stop "${RAND_NAME2}"  >/dev/null 2>&1 || true
	docker rm -f "${RAND_NAME1}" >/dev/null 2>&1 || true
	docker rm -f "${RAND_NAME2}" >/dev/null 2>&1 || true
	echo "[FAILED] Errors found in docker logs"
	exit 1
fi


###
### Cleanup
###
docker stop "${RAND_NAME1}"  >/dev/null 2>&1
docker stop "${RAND_NAME2}"  >/dev/null 2>&1
docker rm -f "${RAND_NAME1}" >/dev/null 2>&1
docker rm -f "${RAND_NAME2}" >/dev/null 2>&1

log "ok" "Test succeeded"
