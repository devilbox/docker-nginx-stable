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
### Globals
###
NAME_HTTPD="$( get_random_name )"


###
### Start HTTPD Container
###
if ! run "docker run --platform ${ARCH} --name ${NAME_HTTPD} \
-e DEBUG_ENTRYPOINT=4 \
-e DEBUG_RUNTIME=1 \
--entrypoint=bash \
${IMAGE}:${TAG} -c 'command -v xargs >/dev/null'"; then
	docker_logs "${NAME_HTTPD}"
	docker_stop "${NAME_HTTPD}"
	log "fail" "command 'xargs' not found inside image, but required"
	exit 1
fi
echo "command 'xargs' found"


###
### Cleanup
###
docker_stop "${NAME_HTTPD}"
log "ok" "Test succeeded"
