#!/usr/bin/env bash

set -e
set -u
set -o pipefail

while_retry() {
	local expect="${1}"
	local url="${2}"
	local header="${3:-}"
	local output

	count=0
	retry=30
	while ! output="$( curl --fail -sS -k -L "${url}" -H "${header}" 2>/dev/null | grep -A 10 "${expect}" )"; do
		if [ "${count}" = "${retry}" ]; then
			echo "[FAILED] curl --fail -sS -k -L \"${url}\" -H \"${header}\" | grep \"${expect}\""
			curl --fail -sS -k -L "${url}" -H "${header}" | grep -A 10 "${expect}" || true
			return 1
		fi
		count=$(( count + 1 ))
		sleep 1
	done
	echo "${output}"
}

docker-compose build
docker-compose up -d

if ! output1="$( while_retry '[OK]' "http://localhost:8000" "Host:node.loc" )"; then
	docker-compose logs || true
	docker-compose stop || true
	docker-compose rm -f || true
	echo "${output1}"
	exit 1
fi
if ! output2="$( while_retry '[OK]' "https://localhost:8443" "Host:node.loc" )"; then
	docker-compose logs || true
	docker-compose stop || true
	docker-compose rm -f || true
	echo "${output2}"
	exit 1
fi

if ! output3="$( while_retry '[OK]' "http://localhost:8000" "Host:php.loc" )"; then
	docker-compose logs || true
	docker-compose stop || true
	docker-compose rm -f || true
	echo "${output3}"
	exit 1
fi
if ! output4="$( while_retry '[OK]' "https://localhost:8443" "Host:php.loc" )"; then
	docker-compose logs || true
	docker-compose stop || true
	docker-compose rm -f || true
	echo "${output4}"
	exit 1
fi

docker-compose logs || true
docker-compose stop || true
docker-compose rm -f || true

echo "${output1}"
echo "${output2}"
echo "${output3}"
echo "${output4}"
