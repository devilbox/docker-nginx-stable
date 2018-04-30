#!/usr/bin/env bash
#
# This script created CA signed certificates
#

set -e
set -u
set -o pipefail


###
### Command line arguments
###

CERT_PATH="${1}"
VHOST_NAME="${2}"
CA_KEY="${3}"
CA_CRT="${4}"
VERBOSE="${5}"


###
### Variables
###

# Certificate options
size=2048
days=3650

# Certificate subject
C=DE
ST=Berlin
L=Berlin
O=Devilbox
OU=Devilbox
CN="*.${VHOST_NAME}"
ALT="DNS.1:${VHOST_NAME},DNS.2:*.${VHOST_NAME}"


###
### Build commands
###

# Key and Signing Request
cmd1="openssl req \
  -newkey rsa:${size} \
  -nodes \
  -keyout ${CERT_PATH}/${VHOST_NAME}.key \
  -subj '/C=${C}/ST=${ST}/L=${L}/O=${O}/OU=${OU}/CN=${CN}' \
  -out ${CERT_PATH}/${VHOST_NAME}.csr"

# Certificate
cmd2="openssl x509 -req \
  -extfile <(printf 'subjectAltName=${ALT}') \
  -days ${days} \
  -in ${CERT_PATH}/${VHOST_NAME}.csr \
  -CA ${CA_CRT} \
  -CAkey ${CA_KEY} \
  -CAcreateserial \
  -out ${CERT_PATH}/${VHOST_NAME}.crt"

# Trim newlines/whitespaces
cmd1="$( echo "${cmd1}" | tr -s " " )"
cmd2="$( echo "${cmd2}" | tr -s " " )"


###
### Execute
###

# Key and Signing Request
if [ -n "${VERBOSE}" ]; then
	echo "\$ ${cmd1}"
fi
if ! out="$( eval "${cmd1}" 2>&1)"; then
	echo "[FAILED] Failed to create certificate"
	echo "${out}"
	exit 1
fi

# Certificate
if [ -n "${VERBOSE}" ]; then
	echo "\$ ${cmd2}"
fi
if ! out="$( eval "${cmd2}" 2>&1)"; then
	echo "[FAILED] Failed to create certificate"
	echo "${out}"
	exit 1
fi
