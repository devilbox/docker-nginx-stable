#!/usr/bin/env bash

set -e
set -u
set -o pipefail

###
### Variables
###

IFS=$'\n'

# Current directory
CWD="$( dirname "${0}" )"
IMAGE="${1}"
TAG="${2}"
ARCH="${3}"

declare -a TESTS=()




###
### Run tests
###

# Get all [0-9]+.sh test files
FILES="$( find "${CWD}" -regex "${CWD}/[0-9].+\.sh" | sort -u )"
for f in ${FILES}; do
	TESTS+=("${f}")
done

for i in "${TESTS[@]}"; do
	echo "####################################################################################################"
	echo "####################################################################################################"
	echo "###"
	echo "### [${CWD}/${i}] ${IMAGE}:${TAG} (${ARCH})"
	echo "###"
	echo "####################################################################################################"
	echo "####################################################################################################"
	if ! sh -c "${i} ${IMAGE} ${TAG} ${ARCH}"; then
		exit 1
	fi
done
