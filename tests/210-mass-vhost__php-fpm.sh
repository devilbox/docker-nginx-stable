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


###
### Universal ports
###
# shellcheck disable=SC2034
HOST_PORT_HTTP="8093"
# shellcheck disable=SC2034
HOST_PORT_HTTPS="8493"

###
### Universal container names
###
# shellcheck disable=SC2034
NAME_HTTPD="$( get_random_name )"
# shellcheck disable=SC2034
NAME_PHPFPM="$( get_random_name )"
# shellcheck disable=SC2034
NAME_RPROXY="$( get_random_name )"



#---------------------------------------------------------------------------------------------------
# DEFINES
#---------------------------------------------------------------------------------------------------

###
### GLOBALS
###
DOCROOT="htdocs"
TLD=".loc"
MOUNT_CONT="/shared/httpd"
MOUNT_HOST="$( tmp_dir )"



#---------------------------------------------------------------------------------------------------
# APPS
#---------------------------------------------------------------------------------------------------

###
### Application 1
###
APP1_NAME="my-project-1"
APP1_URL="http://localhost:${HOST_PORT_HTTP}"
APP1_EXT="php"
APP1_HDR="Host: ${APP1_NAME}${TLD}"
APP1_TXT="hello from ${APP1_NAME} via httpd with ${APP1_EXT}"

###
### Application 2
###
APP2_NAME="another-example"
APP2_URL="http://localhost:${HOST_PORT_HTTP}"
APP2_EXT="php"
APP2_HDR="Host: ${APP2_NAME}${TLD}"
APP2_TXT="hello from ${APP2_NAME} via httpd with ${APP2_EXT}"

###
### Application 2
###
APP3_NAME="app-after-startup"
APP3_URL="http://localhost:${HOST_PORT_HTTP}"
APP3_EXT="php"
APP3_HDR="Host: ${APP3_NAME}${TLD}"
APP3_TXT="hello from ${APP3_NAME} via httpd with ${APP3_EXT}"


###
### Create Applications (before startup)
###
create_app "${MOUNT_HOST}" "${DOCROOT}" "${APP1_NAME}" "index.${APP1_EXT}" "<?php echo '${APP1_TXT}';"
create_app "${MOUNT_HOST}" "${DOCROOT}" "${APP2_NAME}" "index.${APP2_EXT}" "<?php echo '${APP2_TXT}';"



#---------------------------------------------------------------------------------------------------
# START
#---------------------------------------------------------------------------------------------------

###
### Start PHP Container
###
run "docker run -d --platform ${ARCH} --name ${NAME_PHPFPM} \
-v ${MOUNT_HOST}:${MOUNT_CONT} \
devilbox/php-fpm-8.1 >/dev/null"


###
### Start HTTPD Container
###
run "docker run -d --platform ${ARCH} --name ${NAME_HTTPD} \
-v ${MOUNT_HOST}:${MOUNT_CONT} \
-p 127.0.0.1:${HOST_PORT_HTTP}:80 \
-p 127.0.0.1:${HOST_PORT_HTTPS}:443 \
-e DEBUG_ENTRYPOINT=3 \
-e DEBUG_RUNTIME=2 \
-e MAIN_VHOST_ENABLE=0 \
-e MASS_VHOST_ENABLE=1 \
-e MASS_VHOST_BACKEND=conf:phpfpm:tcp:${NAME_PHPFPM}:9000 \
--link ${NAME_PHPFPM} \
${IMAGE}:${TAG} >/dev/null"



#---------------------------------------------------------------------------------------------------
# TESTS
#---------------------------------------------------------------------------------------------------

###
### Test: APP1
###
if ! test_vhost_response "${APP1_TXT}" "${APP1_URL}" "${APP1_HDR}"; then
	docker_logs "${NAME_PHPFPM}"
	docker_logs "${NAME_HTTPD}"
	docker_stop "${NAME_PHPFPM}"
	docker_stop "${NAME_HTTPD}"
	log "fail" "'${APP1_TXT}' not found in ${APP1_URL}"
	exit 1
fi

###
### Test: APP2
###
if ! test_vhost_response "${APP2_TXT}" "${APP2_URL}" "${APP2_HDR}"; then
	docker_logs "${NAME_PHPFPM}"
	docker_logs "${NAME_HTTPD}"
	docker_stop "${NAME_PHPFPM}"
	docker_stop "${NAME_HTTPD}"
	log "fail" "'${APP2_TXT}' not found in ${APP2_URL}"
	exit 1
fi

###
### Test: APP3
###
create_app "${MOUNT_HOST}" "${DOCROOT}" "${APP3_NAME}" "index.${APP3_EXT}" "<?php echo '${APP3_TXT}';"
if ! test_vhost_response "${APP3_TXT}" "${APP3_URL}" "${APP3_HDR}"; then
	docker_logs "${NAME_PHPFPM}"
	docker_logs "${NAME_HTTPD}"
	docker_stop "${NAME_PHPFPM}"
	docker_stop "${NAME_HTTPD}"
	log "fail" "'${APP3_TXT}' not found in ${APP3_URL}"
	exit 1
fi



#---------------------------------------------------------------------------------------------------
# GENERIC
#---------------------------------------------------------------------------------------------------

###
### Test: Errors
###
if ! test_docker_logs_err "${NAME_HTTPD}"; then
	docker_logs "${NAME_PHPFPM}"
	docker_logs "${NAME_HTTPD}"
	docker_stop "${NAME_PHPFPM}"
	docker_stop "${NAME_HTTPD}"
	log "fail" "Found errors in docker logs"
	exit 1
fi


###
### Cleanup
###
docker_stop "${NAME_PHPFPM}"
docker_stop "${NAME_HTTPD}"
log "ok" "Test succeeded"
