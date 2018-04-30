#!/usr/bin/env bash

set -e
set -u
set -o pipefail

VHOST_PATH="${1}"
VHOST_NAME="${2}"
VHOST_TLD="${3}"
VHOST_TPL="${4}"
CA_KEY="${5}"
CA_CRT="${6}"
VERBOSE="${7}"
GENERATE_SSL="${8}"

if [ "${GENERATE_SSL}" = "1" ]; then
	if ! create-cert.sh "/etc/httpd/cert/mass" "${VHOST_NAME}${VHOST_TLD}" "${CA_KEY}" "${CA_CRT}" "${VERBOSE}"; then
		echo "[FAILED] Failed to add SSL certificate for ${VHOST_NAME}${VHOST_TLD}"
		exit 1
	fi
fi

cmd="vhost_gen.py -p \"${VHOST_PATH}\" -n \"${VHOST_NAME}\" -c /etc/vhost-gen/mass.yml -o \"${VHOST_TPL}\" -s ${VERBOSE} -m both"
if [ -n "${VERBOSE}" ]; then
	echo "\$ ${cmd}"
fi

if ! eval "${cmd}"; then
	echo "[FAILED] Failed to add vhost for ${VHOST_NAME}${VHOST_TLD}"
	exit 1
fi
