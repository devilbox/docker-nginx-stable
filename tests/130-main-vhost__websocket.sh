#!/usr/bin/env bash

set -e
set -u
set -o pipefail

CWD="$(cd -P -- "$(dirname -- "$0")" && pwd -P)"

IMAGE="${1}"
TAG="${2}"
ARCH="${3}"

if [ "${IMAGE}" = "devilbox/apache-2.2" ]; then
	echo "Skipping websocket check for Apache 2.2 - not supported."
	exit 0
fi


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
# shellcheck disable=SC2034
NAME_WORKER="$( get_random_name )"



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
#APP1_HDR=""
APP1_TXT="hello you are now connected to a websocket"
#create_app "${MOUNT_HOST}" "${DOCROOT}" "" "index.${APP1_EXT}" "<?php echo '${APP1_TXT}';"
cat << EOF > "${MOUNT_HOST}/index.js"
const WebSocket = require("ws");
const wss = new WebSocket.Server({ port: 3000 });
wss.on("connection", (ws) => {
  ws.send("${APP1_TXT}");
  ws.on("message", (message) => {
    console.log("New message from client: %s", message);
  });
});
console.log("WebSocket server ready at localhost:3000");
EOF
# Create package.json
cat << EOF > "${MOUNT_HOST}/package.json"
{
  "name": "node-websocket-example",
  "version": "1.0.0",
  "main": "index.js",
  "devDependencies": {},
  "scripts": {
    "test": "echo \"Error: no test specified\" && exit 1"
  },
  "keywords": [],
  "author": "",
  "license": "ISC",
  "description": "",
  "dependencies": {
    "ws": "^7.5.1"
  }
}
EOF
# Create start script
cat << EOF > "${MOUNT_HOST}/start.sh"
#!/bin/sh
npm install
node index.js
EOF
# Create script for worker
cat << EOF > "${MOUNT_HOST}/worker.sh"
#!/bin/sh
npm install -g wscat
sleep 90000
EOF




#---------------------------------------------------------------------------------------------------
# START
#---------------------------------------------------------------------------------------------------

###
### Start NodeJS Container
###
run "docker run -d --name ${NAME_RPROXY} \
-v ${MOUNT_HOST}:${MOUNT_CONT} -w ${MOUNT_CONT} \
node:19-alpine sh start.sh >/dev/null"


###
### Start HTTPD Container
###
run "docker run -d --platform ${ARCH} --name ${NAME_HTTPD} \
-v ${MOUNT_HOST}:${MOUNT_CONT} \
-p 127.0.0.1:${HOST_PORT_HTTP}:80 \
-p 127.0.0.1:${HOST_PORT_HTTPS}:443 \
-e DEBUG_ENTRYPOINT=3 \
-e DEBUG_RUNTIME=2 \
-e MAIN_VHOST_BACKEND=conf:rproxy:ws:${NAME_RPROXY}:3000 \
--link ${NAME_RPROXY} \
${IMAGE}:${TAG} >/dev/null"

###
### Start Worker Container
###
run "docker run -d --name ${NAME_WORKER} \
-v ${MOUNT_HOST}:${MOUNT_CONT} -w ${MOUNT_CONT} \
--link ${NAME_HTTPD} \
node:19-alpine sh worker.sh >/dev/null"


#---------------------------------------------------------------------------------------------------
# TESTS
#---------------------------------------------------------------------------------------------------

###
### Test: APP1
###
count=0
retry=30
while ! run "docker exec -t ${NAME_WORKER} wscat --no-color --connect ${NAME_HTTPD} -x quit | grep '${APP1_TXT}'"; do
	if [ "${count}" = "${retry}" ]; then
		docker_logs "${NAME_WORKER}"
		docker_logs "${NAME_RPROXY}"
		docker_logs "${NAME_HTTPD}"

		docker_stop "${NAME_WORKER}"
		docker_stop "${NAME_RPROXY}"
		docker_stop "${NAME_HTTPD}"
		log "fail" "'${APP1_TXT}' not found in ${APP1_URL}"
		exit 1
	fi
	count=$(( count + 1 ))
	sleep 1
done
log "ok" "Resp: '${APP1_TXT}'"



#---------------------------------------------------------------------------------------------------
# GENERIC
#---------------------------------------------------------------------------------------------------

###
### Test: Errors
###
if ! test_docker_logs_err "${NAME_HTTPD}"; then
	docker_logs "${NAME_WORKER}"
	docker_logs "${NAME_RPROXY}"
	docker_logs "${NAME_HTTPD}"

	docker_stop "${NAME_WORKER}"
	docker_stop "${NAME_RPROXY}"
	docker_stop "${NAME_HTTPD}"
	log "fail" "Found errors in docker logs"
	exit 1
fi


###
### Cleanup
###
docker_stop "${NAME_WORKER}"
docker_stop "${NAME_RPROXY}"
docker_stop "${NAME_HTTPD}"
log "ok" "Test succeeded"
