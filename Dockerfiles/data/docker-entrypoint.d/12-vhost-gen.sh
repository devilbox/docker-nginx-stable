#!/usr/bin/env bash

set -e
set -u
set -o pipefail


# -------------------------------------------------------------------------------------------------
# ALL VHOST FUNCTIONS
# -------------------------------------------------------------------------------------------------

###
### Copy custom vhost-gen template
###
vhost_gen_copy_custom_template() {
	local input_dir="${1}"
	local output_dir="${2}"
	local template_name="${3}"

	if [ ! -d "${input_dir}" ]; then
		run "mkdir -p ${input_dir}"
	fi

	if [ -f "${input_dir}/${template_name}" ]; then
		log "info" "vhost-gen: applying customized global template: ${template_name}"
		run "cp ${input_dir}/${template_name} ${output_dir}/${template_name}"
	else
		log "info" "vhost-gen: no customized template found"
	fi
}


###
### Generate config for MAIN_VHOST
###
vhost_gen_main_generate_config() {
	local server_type="${1}"  # nginx, apache22 or apache24
	local backend_string="${2}"
	local http2_enable="${3}"
	local status_enable="${4}"
	local status_alias="${5}"
	local docker_logs="${6}"
	local timeout="${7}"
	local outpath="${8}"

	be_conf_type="$( get_backend_conf_type "${backend_string}" )"
	be_conf_host="$( get_backend_conf_host "${backend_string}" )"
	be_conf_port="$( get_backend_conf_port "${backend_string}" )"

	# Defaults
	directory_index="index.html, index.htm"
	php_fpm_enable="no"

	# PHP-FPM specific
	if [ "${be_conf_type}" = "phpfpm" ]; then
		php_fpm_enable="yes"
		directory_index="index.php, index.html, index.htm"
	fi
	generate_vhostgen_conf \
		"${server_type}" \
		"/etc/httpd/conf.d" \
		"" \
		"" \
		"${directory_index}" \
		"$( to_python_bool "${http2_enable}" )" \
		"/etc/httpd/cert/main" \
		"/etc/httpd/cert/main" \
		"'default'" \
		"$( to_python_bool "${docker_logs}" )" \
		"${php_fpm_enable}" \
		"${be_conf_host}" \
		"${be_conf_port}" \
		"${timeout}" \
		"/devilbox-api/:/var/www/default/api:http(s)?://(.*)$, /vhost.d/:/etc/httpd" \
		"$( to_python_bool "${status_enable}" )" \
		"${status_alias}"  \
		> "${outpath}"
}


###
### Configure Docker logs
###
vhost_gen_docker_logs() {
	local enable="${1}"
	local config="${2}"

	if [ "${enable}" -eq "1" ]; then
		run "sed -i'' 's/__DOCKER_LOGS_ERROR__/yes/g' ${config}"
		run "sed -i'' 's/__DOCKER_LOGS_ACCESS__/yes/g' ${config}"
	else
		run "sed -i'' 's/__DOCKER_LOGS_ERROR__/no/g' ${config}"
		run "sed -i'' 's/__DOCKER_LOGS_ACCESS__/no/g' ${config}"
	fi
}


###
### Set HTTP2_ENABLE
###
vhost_gen_http2() {
	local enable="${1}"
	local config="${2}"

	if [ "${enable}" -eq "1" ]; then
		run "sed -i'' 's/__HTTP2_ENABLE__/True/g' ${config}"
	else
		run "sed -i'' 's/__HTTP2_ENABLE__/False/g' ${config}"
	fi
}


###
### Set PHP_FPM
###
vhost_gen_php_fpm() {
	local enable="${1}"
	local addr="${2}"
	local port="${3}"
	local timeout="${4}"
	local config="${5}"

	if [ "${enable}" -eq "1" ]; then
		run "sed -i'' 's/__PHP_ENABLE__/yes/g' ${config}"
		run "sed -i'' 's/__PHP_ADDR__/${addr}/g' ${config}"
		run "sed -i'' 's/__PHP_PORT__/${port}/g' ${config}"
		run "sed -i'' 's/__PHP_TIMEOUT__/${timeout}/g' ${config}"
	else
		run "sed -i'' 's/__PHP_ENABLE__/no/g' ${config}"
	fi
}



# -------------------------------------------------------------------------------------------------
# MAIN VHOST FUNCTIONS
# -------------------------------------------------------------------------------------------------

###
### Enable HTTPD status page?
###
vhost_gen_main_vhost_httpd_status() {
	local enable="${1}"
	local alias="${2}"
	local config="${3}"

	if [ "${enable}" -eq "1" ]; then
		run "sed -i'' 's|__ENABLE_STATUS__|yes|g' ${config}"
		run "sed -i'' 's|__STATUS_ALIAS__|${alias}|g' ${config}"
	else
		run "sed -i'' 's|__ENABLE_STATUS__|no|g' ${config}"
	fi
}


###
### Generate Main vhost?
###
vhost_gen_main_generate() {
	local enable="${1}"
	local docroot="${2}"
	local backend="${3}"
	local config="${4}"
	local template="${5}"
	local ssl_type="${6}"

	local verbose
	local reverse=0

	# Check if reverse proxy or not
	if [ -n "${backend}" ]; then
		be_type="$( get_backend_conf_type "${backend}" )"  # phpfpm or rproxy
		be_prot="$( get_backend_conf_prot "${backend}" )"  # tcp, http, https
		be_host="$( get_backend_conf_host "${backend}" )"  # <host>
		be_port="$( get_backend_conf_port "${backend}" )"  # <port>
		if [ "${be_type}" = "rproxy" ]; then
			reverse=1
		fi
	fi

	if [ "${enable}" -eq "1" ]; then
		# vhost-gen verbosity
		if [ "${DEBUG_ENTRYPOINT}" -gt "1" ]; then
			verbose="-v"
		else
			verbose=""
		fi

		if [ "${reverse}" = "1" ]; then
			run "vhost-gen -n localhost -r ${be_prot}://${be_host}:${be_port} -l / -t /etc/vhost-gen/templates-main/ -c ${config} -o ${template} ${verbose} -d -s -m ${ssl_type}"
		else
			# Adding custom nginx vhost template to ensure paths like:
			# /vendor/index.php/arg1/arg2 will also work (just like Apache)
			# https://www.reddit.com/r/nginx/comments/a6pw31/phpfpm_does_not_handle_subpathindexphparg1arg2/
			run "vhost-gen -n localhost -p ${docroot} -t /etc/vhost-gen/templates-main/ -c ${config} -o ${template} ${verbose} -d -s -m ${ssl_type}"
		fi
	fi
}



# -------------------------------------------------------------------------------------------------
# MASS VHOST FUNCTIONS
# -------------------------------------------------------------------------------------------------

###
### Set DOCROOT_SUFFIX
###
vhost_gen_mass_vhost_docroot() {
	local enable="${1}"
	local docroot="${2}"
	local config="${3}"

	if [ "${enable}" -eq "1" ]; then
		run "sed -i'' 's|__DOCROOT_SUFFIX__|${docroot}|g' ${config}"
	fi
}


###
### Set TLD
###
vhost_gen_mass_vhost_tld() {
	local enable="${1}"
	local tld="${2}"
	local config="${3}"

	if [ "${enable}" -eq "1" ]; then
		run "sed -i'' 's/__TLD__/${tld}/g' ${config}"
	fi
}
