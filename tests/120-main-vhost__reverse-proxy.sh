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
#DOCROOT="htdocs"
MOUNT_CONT="/var/www/default"
MOUNT_HOST="$( tmp_dir )"



#---------------------------------------------------------------------------------------------------
# APPS
#---------------------------------------------------------------------------------------------------

###
### Application 1
###
APP1_URL="http://localhost:${HOST_PORT_HTTP}"
#APP1_EXT="nodejs"
APP1_HDR=""
APP1_TXT="hello via httpd with NodeJS"
#create_app "${MOUNT_HOST}" "${DOCROOT}" "" "index.${APP1_EXT}" "<?php echo '${APP1_TXT}';"
cat << EOF > "${MOUNT_HOST}/app.js"
const http = require('http');
const server = http.createServer((req, res) => {
        res.statusCode = 200;
        res.setHeader('Content-Type', 'text/plain');
        res.write('[OK]\n');
        res.write('${APP1_TXT}\n');
        res.end();
});
server.listen(3000, '0.0.0.0');
EOF



#---------------------------------------------------------------------------------------------------
# START
#---------------------------------------------------------------------------------------------------

###
### Start NodeJS Container
###
run "docker run -d --name ${NAME_RPROXY} \
-v ${MOUNT_HOST}:${MOUNT_CONT} \
node:19-alpine node /var/www/default/app.js >/dev/null"


###
### Start HTTPD Container
###
run "docker run -d --platform ${ARCH} --name ${NAME_HTTPD} \
-v ${MOUNT_HOST}:${MOUNT_CONT} \
-p 127.0.0.1:${HOST_PORT_HTTP}:80 \
-p 127.0.0.1:${HOST_PORT_HTTPS}:443 \
-e DEBUG_ENTRYPOINT=3 \
-e DEBUG_RUNTIME=2 \
-e MAIN_VHOST_BACKEND=conf:rproxy:http:${NAME_RPROXY}:3000 \
--link ${NAME_RPROXY} \
${IMAGE}:${TAG} >/dev/null"



#---------------------------------------------------------------------------------------------------
# TESTS
#---------------------------------------------------------------------------------------------------

###
### Test: APP1
###
if ! test_vhost_response "${APP1_TXT}" "${APP1_URL}" "${APP1_HDR}"; then
	docker_logs "${NAME_RPROXY}"
	docker_logs "${NAME_HTTPD}"
	docker_stop "${NAME_RPROXY}"
	docker_stop "${NAME_HTTPD}"
	log "fail" "'${APP1_TXT}' not found in ${APP1_URL}"
	exit 1
fi



#---------------------------------------------------------------------------------------------------
# GENERIC
#---------------------------------------------------------------------------------------------------

###
### Test: Errors
###
if ! test_docker_logs_err "${NAME_HTTPD}"; then
	docker_logs "${NAME_RPROXY}"
	docker_logs "${NAME_HTTPD}"
	docker_stop "${NAME_RPROXY}"
	docker_stop "${NAME_HTTPD}"
	log "fail" "Found errors in docker logs"
	exit 1
fi


###
### Cleanup
###
docker_stop "${NAME_RPROXY}"
docker_stop "${NAME_HTTPD}"
log "ok" "Test succeeded"
