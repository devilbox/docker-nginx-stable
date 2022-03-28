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


###
### Load Library
###
# shellcheck disable=SC1091
. "${CWD}/.lib.sh"


RAND_NAME="$( get_random_name )"

###
### Startup container
###
FILES="$( \
run "docker run --rm --platform ${ARCH} \
 -e DEBUG_ENTRYPOINT=2 \
 -e DEBUG_RUNTIME=1 \
 -e NEW_UID=$( id -u ) \
 -e NEW_GID=$( id -g ) \
 --entrypoint=bash \
 --name ${RAND_NAME} ${IMAGE}:${TAG} -c '
	find /lib -print0 | xargs -n1 -0 -P 2
 '"
)"

if [ -z "${FILES}" ]; then
	>&2 echo "Error, no files found with 'find' and 'xargs'"
	exit 1
fi

echo "[OK]  xargs works"
