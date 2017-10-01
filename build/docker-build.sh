#!/bin/sh -eu


###
### Globals
###
CWD="$(cd -P -- "$(dirname -- "$0")" && pwd -P)/.."


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

# Test Docker name
if ! grep -q 'image=".*"' "${CWD}/Dockerfile" > /dev/null 2>&1; then
	echo "No 'image' LABEL found"
	exit
fi

# Test Docker vendor
if ! grep -q 'vendor=".*"' "${CWD}/Dockerfile" > /dev/null 2>&1; then
	echo "No 'vendor' LABEL found"
	exit
fi

# Retrieve values
NAME="$( grep 'image=".*"' "${CWD}/Dockerfile" | sed 's/^[[:space:]]*//g' | awk -F'"' '{print $2}' )"
VEND="$( grep -Eo 'vendor="(.*)"' "${CWD}/Dockerfile" | awk -F'"' '{print $2}' )"
DATE="$( date '+%Y-%m-%d' )"


###
### Update Base
###
MY_BASE="$( grep 'FROM[[:space:]].*:.*' "${CWD}/Dockerfile" | sed 's/FROM\s*//g' )"
run "docker pull ${MY_BASE}"


###
### Build
###

# Update build date
run "sed -i'' 's/build-date=\".*\"/build-date=\"${DATE}\"/g' ${CWD}/Dockerfile"

# Build Docker
run "docker build -t ${VEND}/${NAME} ${CWD}"


###
### Retrieve information afterwards and Update README.md
###
docker run -d --rm --name my_tmp_${NAME} -t ${VEND}/${NAME}
INFO="$( docker exec my_tmp_${NAME} httpd -V | grep -E '^Server.*(version|built|Module|loaded|MPM)' )"
docker stop "$(docker ps | grep "my_tmp_${NAME}" | awk '{print $1}')" > /dev/null

INFO="$( echo "${INFO}" | sed 's/\s$//g' )"        # remove trailing space
echo "${INFO}"

sed -i'' '/##[[:space:]]Version/q' "${CWD}/README.md"
echo "" >> "${CWD}/README.md"
echo '```' >> "${CWD}/README.md"
echo "${INFO}" >> "${CWD}/README.md"
echo '```' >> "${CWD}/README.md"
