#!/usr/bin/env bash

set -e
set -u
set -o pipefail

docker-compose build
docker-compose up -d
sleep 10

if ! curl http://localhost:8000 | grep '[OK]'; then
	docker-compose logs || true
	docker-compose stop || true
	docker-compose rm -f || true
	exit 1
fi

docker-compose logs || true
docker-compose stop || true
docker-compose rm -f || true
