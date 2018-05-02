#!/usr/bin/env bash

set -e
set -u
set -o pipefail


############################################################
# Functions
############################################################

###
### Set PHP_FPM
###
vhost_gen_php_fpm() {
	local enable="${1}"
	local addr="${2}"
	local port="${3}"
	local config="${4}"
	local debug="${5}"

	if [ "${enable}" -eq "1" ]; then
		run "sed -i'' 's/__PHP_ENABLE__/yes/g' ${config}" "${debug}"
		run "sed -i'' 's/__PHP_ADDR__/${addr}/g' ${config}" "${debug}"
		run "sed -i'' 's/__PHP_PORT__/${port}/g' ${config}" "${debug}"
	else
		run "sed -i'' 's/__PHP_ENABLE__/no/g' ${config}" "${debug}"
	fi
}


###
### Configure Docker logs
###
vhost_gen_docker_logs() {
	local enable="${1}"
	local config="${2}"
	local debug="${3}"

	if [ "${enable}" -eq "1" ]; then
		run "sed -i'' 's/__DOCKER_LOGS_ERROR__/yes/g' ${config}" "${debug}"
		run "sed -i'' 's/__DOCKER_LOGS_ACCESS__/yes/g' ${config}" "${debug}"
	else
		run "sed -i'' 's/__DOCKER_LOGS_ERROR__/no/g' ${config}" "${debug}"
		run "sed -i'' 's/__DOCKER_LOGS_ACCESS__/no/g' ${config}" "${debug}"
	fi
}



###
### Generate Main vhost?
###
vhost_gen_generate_main_vhost() {
	local enable="${1}"
	local docroot="${2}"
	local config="${3}"
	local template="${4}"
	local ssl_type="${5}"
	local verbose="${6}"
	local debug="${7}"

	if [ "${enable}" -eq "1" ]; then

		# vhost-gen verbosity
		if [ "${verbose}" -gt "0" ]; then
			verbose="-v"
		else
			verbose=""
		fi
		run "vhost_gen.py -n localhost -p ${docroot} -c ${config} -o ${template} ${verbose} -d -s -m ${ssl_type}" "${debug}"
	fi
}



###
### Enable HTTPD status page?
###
vhost_gen_main_vhost_httpd_status() {
	local enable="${1}"
	local alias="${2}"
	local config="${3}"
	local debug="${4}"

	if [ "${enable}" -eq "1" ]; then
		run "sed -i'' 's|__ENABLE_STATUS__|yes|g' ${config}" "${debug}"
		run "sed -i'' 's|__STATUS_ALIAS__|${alias}|g' ${config}" "${debug}"
	else
		run "sed -i'' 's|__ENABLE_STATUS__|no|g' ${config}" "${debug}"
	fi
}



###
### Set DOCROOT_SUFFIX
###
vhost_gen_mass_vhost_docroot() {
	local enable="${1}"
	local docroot="${2}"
	local config="${3}"
	local debug="${4}"

	if [ "${enable}" -eq "1" ]; then
		run "sed -i'' 's|__DOCROOT_SUFFIX__|${docroot}|g' ${config}" "${debug}"
	fi
}


###
### Set TLD
###
vhost_gen_mass_vhost_tld() {
	local enable="${1}"
	local tld="${2}"
	local config="${3}"
	local debug="${4}"

	if [ "${enable}" -eq "1" ]; then
		run "sed -i'' 's/__TLD__/${tld}/g' ${config}" "${debug}"
	fi
}
