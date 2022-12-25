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
#NAME_PHPFPM="$( get_random_name )"
# shellcheck disable=SC2034
NAME_RPROXY1="$( get_random_name )"
NAME_RPROXY2="$( get_random_name )"



#---------------------------------------------------------------------------------------------------
# DEFINES
#---------------------------------------------------------------------------------------------------

###
### GLOBALS
###
#DOCROOT="htdocs"
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
APP1_TXT="hello from ${APP1_NAME} via httpd with NodeJS"
APP1_URL="http://localhost:${HOST_PORT_HTTP}"
APP1_HDR="Host: ${APP1_NAME}${TLD}"
APP1_PORT=3000

APP1_DIR="$( tmp_dir )"
cat << EOF > "${APP1_DIR}/app.js"
const http = require('http');
const server = http.createServer((req, res) => {
        res.statusCode = 200;
        res.setHeader('Content-Type', 'text/plain');
        res.write('[OK]\n');
        res.write('${APP1_TXT}\n');
        res.end();
});
server.listen(${APP1_PORT}, '0.0.0.0');
EOF

# Create Project for Application 1
mkdir -p "${MOUNT_HOST}/${APP1_NAME}/cfg"
echo "conf:rproxy:http:${NAME_RPROXY1}:${APP1_PORT}" > "${MOUNT_HOST}/${APP1_NAME}/cfg/backend.txt"




###
### Application 2
###
APP2_NAME="another-nodejs-app"
APP2_TXT="hello hello from ${APP2_NAME} via httpd with NodeJS"
APP2_URL="http://localhost:${HOST_PORT_HTTP}"
APP2_HDR="Host: ${APP2_NAME}${TLD}"
APP2_PORT=4000

APP2_DIR="$( tmp_dir )"
cat << EOF > "${APP2_DIR}/app.js"
const http = require('http');
const server = http.createServer((req, res) => {
        res.statusCode = 200;
        res.setHeader('Content-Type', 'text/plain');
        res.write('[OK]\n');
        res.write('${APP2_TXT}\n');
        res.end();
});
server.listen(${APP2_PORT}, '0.0.0.0');
EOF






#---------------------------------------------------------------------------------------------------
# START
#---------------------------------------------------------------------------------------------------

###
### Pull node image
###
run "docker pull --platform linux/amd64 node:19-alpine"

###
### Start Node-1 Container (tcp 3000)
###
run "docker run -d --name ${NAME_RPROXY1} \
-v ${APP1_DIR}:/app \
node:19-alpine node /app/app.js >/dev/null"


###
### Start Node-2 Container (tcp 4000)
###
run "docker run -d --name ${NAME_RPROXY2} \
-v ${APP2_DIR}:/app \
node:19-alpine node /app/app.js >/dev/null"


###
### Start HTTPD Container
###
run "docker run -d --platform ${ARCH} --name ${NAME_HTTPD} \
-v ${MOUNT_HOST}:${MOUNT_CONT} \
-p 127.0.0.1:${HOST_PORT_HTTP}:80 \
-p 127.0.0.1:${HOST_PORT_HTTPS}:443 \
-e DEBUG_ENTRYPOINT=3 \
-e DEBUG_RUNTIME=1 \
-e MAIN_VHOST_ENABLE=0 \
-e MASS_VHOST_ENABLE=1 \
-e MASS_VHOST_BACKEND=file:backend.txt \
-e DOCKER_LOGS=0 \
--link ${NAME_RPROXY1} \
--link ${NAME_RPROXY2} \
${IMAGE}:${TAG} >/dev/null"



#---------------------------------------------------------------------------------------------------
# TESTS
#---------------------------------------------------------------------------------------------------

###
### Test: APP1
###
if ! test_vhost_response "${APP1_TXT}" "${APP1_URL}" "${APP1_HDR}"; then
	docker_logs "${NAME_RPROXY1}"
	docker_logs "${NAME_HTTPD}"

	docker_stop "${NAME_RPROXY2}"
	docker_stop "${NAME_RPROXY1}"
	docker_stop "${NAME_HTTPD}"
	log "fail" "'${APP1_TXT}' not found in ${APP1_URL}"
	exit 1
fi


###
### Test: APP2
###
# Create Project for Application 2
mkdir -p "${MOUNT_HOST}/${APP2_NAME}/cfg"
echo "conf:rproxy:http:${NAME_RPROXY2}:${APP2_PORT}" > "${MOUNT_HOST}/${APP2_NAME}/cfg/backend.txt"

if ! test_vhost_response "${APP2_TXT}" "${APP2_URL}" "${APP2_HDR}"; then
	docker_logs "${NAME_RPROXY2}"
	docker_logs "${NAME_HTTPD}"

	docker_stop "${NAME_RPROXY2}"
	docker_stop "${NAME_RPROXY1}"
	docker_stop "${NAME_HTTPD}"
	log "fail" "'${APP2_TXT}' not found in ${APP2_URL}"
	exit 1
fi



#---------------------------------------------------------------------------------------------------
# GENERIC
#---------------------------------------------------------------------------------------------------

###
### Test: Errors
###
if ! test_docker_logs_err "${NAME_HTTPD}"; then
	docker_logs "${NAME_RPROXY2}"
	docker_logs "${NAME_RPROXY1}"
	docker_logs "${NAME_HTTPD}"

	docker_stop "${NAME_RPROXY2}"
	docker_stop "${NAME_RPROXY1}"
	docker_stop "${NAME_HTTPD}"
	log "fail" "Found errors in docker logs"
	exit 1
fi


###
### Cleanup
###
docker_stop "${NAME_RPROXY2}"
docker_stop "${NAME_RPROXY1}"
docker_stop "${NAME_HTTPD}"
log "ok" "Test succeeded"
