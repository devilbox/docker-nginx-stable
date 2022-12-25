#!/usr/bin/env bash

set -e
set -u
set -o pipefail

###
### This file holds functions to create CA and Certs
###


# -------------------------------------------------------------------------------------------------
# ACTION FUNCTIONS
# -------------------------------------------------------------------------------------------------

###
### Generate CA
###
cert_gen_generate_ca() {
	local key="${1}"
	local crt="${2}"

	# Create directories
	if [ ! -d "$( dirname "${key}" )" ]; then
		run "mkdir -p $( dirname "${key}" )"
	fi
	if [ ! -d "$( dirname "${crt}" )" ]; then
		run "mkdir -p $( dirname "${crt}" )"
	fi

	# Generate CA if it does not exist yet
	if [ ! -f "${key}" ] || [ ! -f "${crt}" ]; then
		log "warn" "(Re)creating Certificate Authority. You may need to (re)import it into your browser."
		if ! run \
			"ca-gen -v -c DE -s Berlin -l Berlin -o Devilbox -u Devilbox -n 'Devilbox Root CA' -e 'cytopia@devilbox.org' \"${key}\" \"${crt}\"" \
			"Failed to create Certificate Authority."; then
			exit 1
		fi
	else
		log "info" "Existing Certificate Authority files found in: $(dirname "${key}")"
	fi
}


###
### Generate SSL certificate
###
cert_gen_generate_cert() {
	local enable="${1}"
	local ssl_type="${2}"
	local ca_key="${3}"
	local ca_crt="${4}"
	local key="${5}"
	local csr="${6}"
	local crt="${7}"
	local domains="${8}"

	# If not enabled, skip SSL certificate eneration
	if [ "${enable}" != "1" ]; then
		return
	fi

	# If no SSL is requested, skip the SSL certificate generation
	if [ "${ssl_type}" = "plain" ]; then
		return
	fi

	# Create directories
	if [ ! -d "$( dirname "${key}" )" ]; then
		run "mkdir -p $( dirname "${key}" )"
	fi
	if [ ! -d "$( dirname "${csr}" )" ]; then
		run "mkdir -p $( dirname "${csr}" )"
	fi
	if [ ! -d "$( dirname "${crt}" )" ]; then
		run "mkdir -p $( dirname "${crt}" )"
	fi

	# Get domain name and alt_names
	cn=
	alt_names=
	for domain in ${domains//,/ }; do
		domain="$( echo "${domain}" | xargs )" # trim

		# First domain goes into CN
		if [ -z "${cn}" ]; then
			cn="${domain}"
		fi
		# Create space separated list
		alt_names=" ${alt_names} ${domain}"
	done
	alt_names="$( echo "${alt_names}" | xargs )" # tim

	if ! run \
		"cert-gen -v -c DE -s Berlin -l Berlin -o Devilbox -u Devilbox -n '${cn}' -e 'admin@${cn}' -a '${alt_names}' \"${ca_key}\" \"${ca_crt}\" \"${key}\" \"${csr}\" \"${crt}\"" \
		"Failed to create SSL certificate"; then
		exit 1
	fi
}
