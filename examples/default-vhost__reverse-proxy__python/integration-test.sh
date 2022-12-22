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
	retry=1200
	printf "[TESTING] %s" "curl --fail -sS -k -L \"${url}\" -H \"${header}\" | grep \"${expect}\" "
	while ! output="$( curl --fail -sS -k -L "${url}" -H "${header}" 2>/dev/null | grep -A 10 "${expect}" )"; do
		printf "."
		if [ "${count}" = "${retry}" ]; then
			printf "\\n"
			echo "[FAILED] curl --fail -sS -k -L \"${url}\" -H \"${header}\" | grep \"${expect}\""
			curl --fail -sS -k -L "${url}" -H "${header}" | grep -A 10 "${expect}" || true
			return 1
		fi
		count=$(( count + 1 ))
		sleep 1
	done
	printf "\\n"
	echo "${output}"
}

docker-compose build
docker-compose up -d

if ! while_retry '[OK]' "http://localhost:8000"; then
	docker-compose logs || true
	docker-compose stop || true
	docker-compose rm -f || true
	exit 1
fi

if ! while_retry '[OK]' "https://localhost:8443";  then
	docker-compose logs || true
	docker-compose stop || true
	docker-compose rm -f || true
	exit 1
fi
docker-compose logs || true
docker-compose stop || true
docker-compose rm -f || true
