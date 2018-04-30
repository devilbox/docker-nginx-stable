#!/bin/sh -eu


###
### Globals
###
CWD="$(cd -P -- "$(dirname -- "$0")" && pwd -P)/.."
VEND=devilbox
NAME=nginx-stable

###
### Funcs
###
run() {
	_cmd="${1}"
	_red="\033[0;31m"
	_green="\033[0;32m"
	_reset="\033[0m"
	_user="$(whoami)"

	printf "${_red}%s \$ ${_green}${_cmd}${_reset}\n" "${_user}"
	sh -c "LANG=C LC_ALL=C ${_cmd}"
}


###
### Checks
###

# Check Dockerfile
if [ ! -f "${CWD}/Dockerfile" ]; then
	echo "Dockerfile not found in: ${CWD}/Dockerfile."
	exit 1
fi


###
### Update Base
###
MY_BASE="$( grep 'FROM[[:space:]].*:.*' "${CWD}/Dockerfile" | sed 's/FROM\s*//g' )"
run "docker pull ${MY_BASE}"


###
### Build
###

# Build Docker
run "docker build -t ${VEND}/${NAME} ${CWD}"


###
### Retrieve information afterwards and Update README.md
###
DID="$( docker run -d --rm -t ${VEND}/${NAME} )"
INFO="$( docker exec "${DID}" nginx -v 2>&1 )"
docker stop "${DID}"

echo "${INFO}"

sed -i'' '/##[[:space:]]Version/q' "${CWD}/README.md"
echo "" >> "${CWD}/README.md"
echo '```' >> "${CWD}/README.md"
echo "${INFO}" >> "${CWD}/README.md"
echo '```' >> "${CWD}/README.md"
