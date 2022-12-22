#!/usr/bin/env bash

set -e
set -u
set -o pipefail

###
### This file holds functions to manipiate vhosts
###


# -------------------------------------------------------------------------------------------------
# ALL VHOST FUNCTIONS
# -------------------------------------------------------------------------------------------------

###
### Copy custom vhost-gen override template (user-mounted)
###
vhostgen_copy_custom_template() {
	local input_dir="${1}"
	local output_dir="${2}"
	local template_name="${3}"

	if [ ! -d "${input_dir}" ]; then
		run "mkdir -p ${input_dir}"
	fi

	if [ -f "${input_dir}/${template_name}" ]; then
		log "info" "vhost-gen: applying custom global template: ${input_dir}/${template_name}"
		run "cp ${input_dir}/${template_name} ${output_dir}/${template_name}"
	else
		log "info" "vhost-gen: no custom global template found in: ${input_dir}/${template_name}"
	fi
}



# -------------------------------------------------------------------------------------------------
# MAIN VHOST FUNCTIONS
# -------------------------------------------------------------------------------------------------

###
### Generate config for MAIN_VHOST
###
vhostgen_main_generate_config() {
	local httpd_server="${1}"  # nginx, apache22 or apache24
	local backend_string="${2}"
	local http2_enable="${3}"
	local aliases_allow="${4}"
	local aliases_deny="${5}"
	local status_enable="${6}"
	local status_alias="${7}"
	local docker_logs="${8}"
	local timeout="${9}"
	local outpath="${10}"

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
		"${httpd_server}" \
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
		"${aliases_allow}" \
		"${aliases_deny}" \
		"$( to_python_bool "${status_enable}" )" \
		"${status_alias}"  \
		> "${outpath}"
}


###
### Generate vhost for MAIN_VHOST (if enabled)
###
vhostgen_main_generate() {
	local enable="${1}"
	local docroot="${2}"
	local backend="${3}"
	local config="${4}"
	local template="${5}"
	local ssl_type="${6}"
	local custom_template_dir="${7:-}"  # Specifies a different vhost-gen template dir (Dockerfile might copy custom vhost-gen templates)

	# Not using main virtual host, so no need to generate it
	if [ "${enable}" -eq "0" ]; then
		return
	fi

	# vhost-gen always runs with minimum INFO verbosity level
	local verbose="-v"
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

	# increase vhost-gen verbosity?
	if [ "${DEBUG_RUNTIME}" -gt "1" ]; then
		verbose="-vv"
	elif [ "${DEBUG_RUNTIME}" -gt "0" ]; then
		verbose="-v"
	fi

	if [ "${reverse}" = "1" ]; then
		if [ -n "${custom_template_dir}" ]; then
			if ! run \
				"vhost-gen ${verbose} -d -n \"localhost\" -r \"${be_prot}://${be_host}:${be_port}\" -l / -c \"${config}\" -o \"${template}\" -s -m \"${ssl_type}\" -t \"${custom_template_dir}\"" \
				"Failed to create default vhost"; then
				exit 1
			fi
		else
			if ! run \
				"vhost-gen ${verbose} -d -n \"localhost\" -r \"${be_prot}://${be_host}:${be_port}\" -l / -c \"${config}\" -o \"${template}\" -s -m \"${ssl_type}\"" \
				"Failed to create default vhost"; then
				exit 1
			fi
		fi
	else
		if [ -n "${custom_template_dir}" ]; then
			if ! run \
				"vhost-gen ${verbose} -d -n \"localhost\" -p \"${docroot}\" -c \"${config}\" -o \"${template}\" -s -m \"${ssl_type}\" -t \"${custom_template_dir}\"" \
				"Failed to create default vhost"; then
				exit 1
			fi
		else
			if ! run \
				"vhost-gen ${verbose} -d -n \"localhost\" -p \"${docroot}\" -c \"${config}\" -o \"${template}\" -s -m \"${ssl_type}\"" \
				"Failed to create default vhost"; then
				exit 1
			fi
		fi
	fi
	log "trace" "$( grep -v '^[[:blank:]]*$' "/etc/httpd/conf.d/localhost.conf" )"
}
