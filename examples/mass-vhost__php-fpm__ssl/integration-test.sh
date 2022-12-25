#!/usr/bin/env bash

set -e
set -u
set -o pipefail

docker-compose build
docker-compose up -d
sleep 10

if ! curl http://localhost:8000 -H 'Host:sample.loc' | grep '[OK]'; then
	docker-compose logs || true
	docker-compose stop || true
	docker-compose rm -f || true
	exit 1
fi
if ! curl -k https://localhost:8443 -H 'Host:sample.loc' | grep '[OK]'; then
	docker-compose logs || true
	docker-compose stop || true
	docker-compose rm -f || true
	exit 1
fi

if ! curl http://localhost:8000 -H 'Host:test.loc' | grep '[OK]'; then
	docker-compose logs || true
	docker-compose stop || true
	docker-compose rm -f || true
	exit 1
fi
if ! curl -k https://localhost:8443 -H 'Host:test.loc' | grep '[OK]'; then
	docker-compose logs || true
	docker-compose stop || true
	docker-compose rm -f || true
	exit 1
fi

docker-compose logs || true
docker-compose stop || true
docker-compose rm -f || true
