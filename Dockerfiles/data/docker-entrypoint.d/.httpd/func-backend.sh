#!/usr/bin/env bash

set -e
set -u
set -o pipefail

###
### This file defines how the *_VHOST_BACKEND variable evaluates and validates.
###
### Supported backends formats:
### -------------------------------------------
###   Format-1: conf:<type>:<proto>:<host>:<port>
###   Format-2: file:<file>
###
###
### Format-1: conf:<type>:<proto>:<host>:<port>
### -------------------------------------------
###   Requirement:
###       1. type == "rproxy" is only supported for $MAIN_VHOST_BACKEND
###
###   Valid formats:
###       conf:phpfpm:tcp:<host>:<port>    # Remote PHP-FPM server at <host>:<port>
###       conf:rproxy:http:<host>:<port>   # Reverse Proxy server at http://<host>:<port>
###       conf:rproxy:https:<host>:<port>  # Reverse Proxy server at https://<host>:<port>
###       conf:rproxy:ws:<host>:<port>     # Reverse Proxy (websocket) at ws://<host>:<port>
###       conf:rproxy:wss:<host>:<port>    # Reverse Proxy (websocket) at wss://<host>:<port>
###
###
### Format-2: file:<file>
### -------------------------------------------
###   Requirement:
###       1. Only supported for $MASS_VHOST_BACKEND
###       2. Only supported for "rproxy" type
###
###   It must be a file in the project directory, as each project will probably use
###   a different backend host/port:
###       File path: ${$MASS_VHOST_DOCROOT_DIR}/${$MASS_VHOST_TPL_DIR}/<file>
###       Default:   /shared/httpd/<project>/cfg/<file>
###
###   The file must have the following content format:
###       conf:rproxy:<proto>:<host>:<port>
###   Examples:
###       conf:rproxy:http:10.0.0.1:3000
###       conf:rproxy:https:mydomain.com:8080
###       conf:rproxy:ws:10.0.0.1:3000
###       conf:rproxy:wss:10.0.0.1:3000
###
###   Note: If no file is found, a warning will be logged and no Reverse proxy will be created.
###



# -------------------------------------------------------------------------------------------------
# *_VHOST_BACKEND FUNCTIONS
# -------------------------------------------------------------------------------------------------

###
### Check if a backend is specified
###
backend_has_backend() {
	# If the backend string is empty, we do not have a backend
	if [ -z "${1}" ]; then
		return 1
	fi
}


###
### This is a generick backend_string validator for 'conf', which also returns an error message.
###
backend_conf_is_valid() {
	# Do we have a backend defined?
	if ! backend_has_backend "${1}"; then
		return 0
	fi
	backend_prefix="$( get_backend_prefix "${1}" )"           # file or conf
	backend_conf_type="$( get_backend_conf_type "${1}" )"     # phpfpm or rproxy
	backend_conf_prot="$( get_backend_conf_prot "${1}" )"     # tpc, http, https
	#backend_conf_host="$( get_backend_conf_host "${1}" )"     # <host>
	#backend_conf_port="$( get_backend_conf_port "${1}" )"     # <port>

	###
	### Generic validation
	###
	# 1. Prefix: only 'conf' is allowed
	if [ "${backend_prefix}" != "conf" ]; then
		echo  "Invalid backend string '${1}'. It must start with 'conf:'"
		return 1
	fi
	# 2. Type: 'phpfpm' or 'rproxy'
	if ! backend_is_valid_conf_type "${1}"; then
		echo "Invalid backend conf:<type> in: '${1}'. It must be 'phpfpm' or 'rproxy'"
		return 1
	fi
	# 3. Protocol: 'tcp', 'http' or 'https'
	if ! backend_is_valid_conf_prot "${1}"; then
		# Apache 2.2 does not have websocket support
		if [ "${VHOSTGEN_HTTPD_SERVER}" = "apache22" ]; then
			echo "Invalid backend conf:<prot> in: '${1}'. It must be 'tcp', 'http' or 'https'."
		# All other webserver have websocket support
		else
			echo "Invalid backend conf:<prot> in: '${1}'. It must be 'tcp', 'http', 'https', 'ws' or 'wss'."
		fi
		return 1
	fi
	# 4. Host
	if ! backend_is_valid_conf_host "${1}"; then
		echo "Invalid backend conf:<host> in: '${1}'. It must be valid hostname, IPv4 or IPv6 addr"
		return 1
	fi
	# 5. Port
	if ! backend_is_valid_conf_port "${1}"; then
		echo "Invalid backend conf:<port> in: '${1}'. It must be a valid port"
		return 1
	fi

	###
	### Specific validation
	###
	# 6. Validate conf <protocol> phpfpm == tcp
	if [ "${backend_conf_type}" = "phpfpm" ]; then
		if [ "${backend_conf_prot}" != "tcp" ]; then
			echo "Invalid backend conf:<prot> in: '${1}'. 'phpfpm' only supports 'tcp'"
			return 1
		fi
	fi
	# 7. Validate conf <protocol> rproxy == http(s)?
	if [ "${backend_conf_type}" = "rproxy" ]; then
		# Apache 2.2 does not have websocket support
		if [ "${VHOSTGEN_HTTPD_SERVER}" = "apache22" ]; then
			if [ "${backend_conf_prot}" != "http" ] \
			&& [ "${backend_conf_prot}" != "https" ]; then
				echo "Invalid backend conf:<prot> in: '${1}'. 'rproxy' only supports 'http' and 'https'"
				return 1
			fi
		# All other webserver have websocket support
		else
			if [ "${backend_conf_prot}" != "http" ] \
			&& [ "${backend_conf_prot}" != "https" ] \
			&& [ "${backend_conf_prot}" != "ws" ] \
			&& [ "${backend_conf_prot}" != "wss" ]; then
				echo "Invalid backend conf:<prot> in: '${1}'. 'rproxy' only supports 'http', 'https', 'ws' and 'wss'"
				return 1
			fi
		fi
	fi
}


###
### Check if the backend prefix inside the backend string is valid ('conf' or 'file')
###
backend_is_valid_prefix() {
	local value
	value="$( get_backend_prefix "${1}" )"

	if [ "${value}" != "conf" ] && [ "${value}" != "file" ]; then
		return 1
	fi
	return 0
}


###
### Check if the backend file is a valid filename
###
backend_is_valid_file_file() {
	local value
	value="$( get_backend_file_file "${1}" )"

	# Is valid filename?
	if ! is_file "${value}"; then
		return 1
	fi
	# No spaces allowed in filename allowed
	if echo "${value}" | grep -E '\s' >/dev/null; then
		return 1
	fi
	# No weired characters in filename allowed
	if echo "${value}" | grep -E '!|\$|\(|\)\[|\]' >/dev/null; then
		return 1
	fi
}


###
### Check if the backend type inside the backend string is valid.
###
backend_is_valid_conf_type() {
	local value
	value="$( get_backend_conf_type "${1}" )"

	if [ "${value}" != "phpfpm" ] && [ "${value}" != "rproxy" ]; then
		return 1
	fi
	return 0
}


###
### Check if the backend protocol inside the backend string is valid.
###
backend_is_valid_conf_prot() {
	local value
	value="$( get_backend_conf_prot "${1}" )"

	if [ "${VHOSTGEN_HTTPD_SERVER}" = "apache22" ];then
		if [ "${value}" != "tcp" ] && [ "${value}" != "http" ] && [ "${value}" != "https" ]; then
			return 1
		fi
	else
		if [ "${value}" != "tcp" ] && [ "${value}" != "http" ] && [ "${value}" != "https" ] && [ "${value}" != "ws" ] && [ "${value}" != "wss" ]; then
			return 1
		fi
	fi
	return 0
}


###
### Check if the backend host inside the backend string is valid.
###
backend_is_valid_conf_host() {
	local value
	value="$( get_backend_conf_host "${1}" )"

	if ! is_ip_addr "${value}" && ! is_hostname "${value}"; then
		return 1
	fi
	return 0
}


###
### Check if the backend port inside the backend string is valid.
###
backend_is_valid_conf_port() {
	local value
	value="$( get_backend_conf_port "${1}" )"

	if ! is_port "${value}"; then
		return 1
	fi
	return 0
}



# -------------------------------------------------------------------------------------------------
# GETTER FUNCTIONS
# -------------------------------------------------------------------------------------------------

###
### Get Backend prefix (conf or file)
###
### Returns the first element from either:
###    conf:<type>:<proto>:<host>:<port>
###    file:<file>
###
get_backend_prefix() {
	echo "${1}" | awk -F':' '{print $1}'
}


###
### Get backend file name
###
### Returns the second element from file:<file>
###
get_backend_file_file() {
	echo "${1}" | awk -F':' '{print $2}'
}


###
### Get Backend type (phpfpm or rproxy)
###
### Returns the second element from conf:<type>:<proto>:<host>:<port>
###
get_backend_conf_type() {
	echo "${1}" | awk -F':' '{print $2}'
}


###
### Get Backend protocol (tcp, http or https)
###
### Returns the third element from conf:<type>:<proto>:<host>:<port>
###
get_backend_conf_prot() {
	echo "${1}" | awk -F':' '{print $3}'
}


###
### Get Backend host
###
### Returns the 4th to 2nd last element from conf:<type>:<proto>:<host>:<port>
###
get_backend_conf_host() {
	echo "${1}" | awk -F ':' -v OFS=':' '{$1="";$2="";$3="";$NF="";print}' | sed -e 's/^::://g' -e 's/:$//g'
}


###
### Get Backend port
###
### Returns the last element from conf:<type>:<proto>:<host>:<port>
###
get_backend_conf_port() {
	echo "${1}" | awk -F':' '{print $NF}'
}
