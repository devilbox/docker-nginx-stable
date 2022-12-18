#!/usr/bin/env bash

set -e
set -u
set -o pipefail

###
### This file holds functions to validate the given environment variables
###


# -------------------------------------------------------------------------------------------------
# MAIN VALIDATOR
# -------------------------------------------------------------------------------------------------

###
### Validate environment variables
###
### This function is just a gate-keeper and calls the validate_<ENV>()
### function for each environment variable to ensure the assigned
### value is correct.
###
env_var_validate() {
	local name="${1}"
	local value

	value="$( env_get "${name}" )"
	func="validate_$( echo "${name}" | awk '{print tolower($0)}' )"

	# Call specific validator function: validate_<ENV>()
	$func "${name}" "${value}"
}



# -------------------------------------------------------------------------------------------------
# VALIDATE FUNCTIONS: GENERAL
# -------------------------------------------------------------------------------------------------

###
### Validate NEW_UID
###
validate_new_uid() {
	local name="${1}"
	local value="${2}"

	# Ignore if empty (no change)
	if [ -z "${value}" ]; then
		_log_env_valid "ignore" "${name}" "${value}" "(not specified)"
		return 0
	fi
	if ! is_uid "${value}"; then
		_log_env_valid "invalid" "${name}" "${value}" "Must be positive integer"
		exit 1
	fi
	_log_env_valid "valid" "${name}" "${value}" "User ID (uid)" "${value}"
}


###
### Validate NEW_GID
###
validate_new_gid() {
	local name="${1}"
	local value="${2}"

	# Ignore if empty (no change)
	if [ -z "${value}" ]; then
		_log_env_valid "ignore" "${name}" "${value}" "(not specified)"
		return 0
	fi
	if ! is_gid "${value}"; then
		_log_env_valid "invalid" "${name}" "${value}" "Must be positive integer"
		exit 1
	fi
	_log_env_valid "valid" "${name}" "${value}" "Group ID (gid)" "${value}"
}


###
### Validate TIMEZONE
###
validate_timezone() {
	local name="${1}"
	local value="${2}"

	# Show ignored
	if [ "${value}" = "UTC" ]; then
		_log_env_valid "ignore" "${name}" "${value}" "(not specified)"
		return 0
	fi
	if [ ! -f "/usr/share/zoneinfo/${value}" ]; then
		_log_env_valid "invalid" "${name}" "${value}" "File '${value}' must exist in: " "/usr/share/zoneinfo/"
		exit 1
	fi
	_log_env_valid "valid" "${name}" "${value}" "Timezone" "${value}"
}



# -------------------------------------------------------------------------------------------------
# VALIDATE FUNCTIONS: MAIN VHOST
# -------------------------------------------------------------------------------------------------


###
### Validate MAIN_VHOST_ENABLE
###
validate_main_vhost_enable() {
	local name="${1}"
	local value="${2}"
	_validate_bool "${name}" "${value}" "Default vhost"
}


###
### Validate MAIN_VHOST_BACKEND: <type>:<addr>:<port>
###
validate_main_vhost_backend() {
	local name="${1}"
	local value="${2}"
	_validate_vhost_backend "${name}" "${value}" "main" "${MAIN_VHOST_ENABLE}"
}


###
### Validate MAIN_VHOST_BACKEND_TIMEOUT
###
validate_main_vhost_backend_timeout() {
	local name="${1}"
	local value="${2}"
	_validate_vhost_backend_timeout "${name}" "${value}" "${MAIN_VHOST_ENABLE}"
}


###
### Validate MAIN_VHOST_DOCROOT
###
validate_main_vhost_docroot() {
	local name="${1}"
	local value="${2}"
	local base_path="${MAIN_DOCROOT_BASE}"
	_validate_vhost_docroot "${name}" "${value}" "${MAIN_VHOST_ENABLE}" "${MAIN_VHOST_BACKEND}" "${base_path}/${value}"
}


###
### Validate MAIN_VHOST_SSL_TYPE
###
validate_main_vhost_ssl_type() {
	local name="${1}"
	local value="${2}"
	_validate_vhost_ssl_type "${name}" "${value}" "${MAIN_VHOST_ENABLE}"
}


###
### Validate MAIN_VHOST_SSL_CN
###
validate_main_vhost_ssl_cn() {
	local name="${1}"
	local value="${2}"

	# Show ignored
	if [ "${MAIN_VHOST_ENABLE}" = "0" ]; then
		_log_env_valid "ignore" "${name}" "${value}" "(vhost disabled)"
		return
	fi
	if [ "${MAIN_VHOST_SSL_TYPE}" = "plain" ]; then
		_log_env_valid "ignore" "${name}" "${value}" "(no ssl)"
		return
	fi
	_log_env_valid "valid" "${name}" "${value}" "SSL cert subject" "CN = ${value}"
}


###
### Validate MAIN_VHOST_TPL: vhost-gen template directory
###
validate_main_vhost_tpl() {
	local name="${1}"
	local value="${2}"
	local base_path="${MAIN_DOCROOT_BASE}"
	_validate_vhost_tpl "${name}" "${value}" "${MAIN_VHOST_ENABLE}" "${base_path}/${value}"
}


###
### Validate MAIN_VHOST_STATUS_ENABLE: Status page enable/disable
###
validate_main_vhost_status_enable() {
	local name="${1}"
	local value="${2}"

	if ! is_bool "${value}"; then
		_log_env_valid "invalid" "${name}" "${value}" "Must be 0 or 1" ""
		exit 1
	fi
	# Show ignored
	if [ "${MAIN_VHOST_ENABLE}" = "0" ]; then
		_log_env_valid "ignore" "${name}" "${value}" "(vhost disabled)"
		return
	fi
	if [ "${value}" = "0" ]; then
		_log_env_valid "valid" "${name}" "${value}" "Status page" "Disabled"
	else
		_log_env_valid "valid" "${name}" "${value}" "Status page" "Enabled"
	fi
}


###
### Validate MAIN_VHOST_STATUS_ALIAS: Status page URL
###
validate_main_vhost_status_alias() {
	local name="${1}"
	local value="${2}"

	# Show ignored
	if [ "${MAIN_VHOST_ENABLE}" = "0" ]; then
		_log_env_valid "ignore" "${name}" "${value}" "(vhost disabled)"
		return
	fi
	if [ "${MAIN_VHOST_STATUS_ENABLE}" = "0" ]; then
		_log_env_valid "ignore" "${name}" "${value}" "(status disabled)"
		return
	fi
	_log_env_valid "valid" "${name}" "${value}" "Status page URL" "${value}"
}



# -------------------------------------------------------------------------------------------------
# VALIDATE FUNCTIONS: MASS VHOST
# -------------------------------------------------------------------------------------------------

###
### Validate MASS_VHOST_ENABLE
###
validate_mass_vhost_enable() {
	local name="${1}"
	local value="${2}"
	_validate_bool "${name}" "${value}" "Mass vhost"

	# Ensure either of MASS or MAIN is actually enabled
	if [ "${value}" = "0" ] && [ "${MAIN_VHOST_ENABLE}" = "0" ]; then
		_log_env_valid "invalid" "${name}" "${value}" "MAIN_VHOST and MASS_HOST are both disabled" ""
		exit 1
	fi
}


###
### Validate MASS_VHOST_BACKEND <type>:<addr>:<port>
###
validate_mass_vhost_backend() {
	local name="${1}"
	local value="${2}"
	_validate_vhost_backend "${name}" "${value}" "mass" "${MASS_VHOST_ENABLE}"
}


###
### Validate MASS_VHOST_BACKEND_TIMEOUT
###
validate_mass_vhost_backend_timeout() {
	local name="${1}"
	local value="${2}"
	_validate_vhost_backend_timeout "${name}" "${value}" "${MASS_VHOST_ENABLE}"
}


###
### Validate MASS_VHOST_DOCROOT
###
validate_mass_vhost_docroot() {
	local name="${1}"
	local value="${2}"
	local base_path="${MASS_DOCROOT_BASE}"
	_validate_vhost_docroot "${name}" "${value}" "${MASS_VHOST_ENABLE}" "${MASS_VHOST_BACKEND}" "${base_path}/<project>/${value}"
}


###
### Validate MASS_VHOST_TLD_SUFFIX (top-level domain suffix)
###
validate_mass_vhost_tld_suffix() {
	local name="${1}"
	local value="${2}"

	# If value is not empty
	if [ -n "${value}" ]; then
		if ! echo "${value}" | grep -E '^\.' > /dev/null; then
			_log_env_valid "invalid" "${name}" "${value}" "Must start with a leading '.' when set" ""
			_log_env_valid "invalid" "${name}" "<project>${value}" "Not a valid project name" ""
		fi
		# Note: ${value:1} means it starts at the second character,
		#       when handing it over to the is_domain() check function.
		if ! is_domain "${value:1}"; then
			_log_env_valid "invalid" "${name}" "<project>${value}" "Must be a valid domain name or empty" ""
			exit 1
		fi
	fi
	# Show ignored
	if [ "${MASS_VHOST_ENABLE}" = "0" ]; then
		_log_env_valid "ignore" "${name}" "${value}" "(vhost disabled)"
		return
	fi
	if [ -z "${value}" ]; then
		_log_env_valid "valid" "${name}" "${value}" "vHost domain" "<project>"
	else
		_log_env_valid "valid" "${name}" "${value}" "Vhost domain" "<project>${value}"
	fi
}


###
### Validate MASS_VHOST_SSL_TYPE
###
validate_mass_vhost_ssl_type() {
	local name="${1}"
	local value="${2}"
	_validate_vhost_ssl_type "${name}" "${value}" "${MASS_VHOST_ENABLE}"
}


###
### Validate MASS_VHOST_TPL: vhost-gen template directory
###
validate_mass_vhost_tpl() {
	local name="${1}"
	local value="${2}"
	local base_path="${MASS_DOCROOT_BASE}"
	_validate_vhost_tpl "${name}" "${value}" "${MASS_VHOST_ENABLE}" "${base_path}/<project>/${value}"
}



# -------------------------------------------------------------------------------------------------
# VALIDATE FUNCTIONS: MISC VALIDATION
# -------------------------------------------------------------------------------------------------

###
### Validate WORKER_CONNECTIONS
###
validate_worker_connections() {
	local name="${1}"
	local value="${2}"
	_log_env_valid "valid" "${name}" "${value}" "worker_connections" "${value}"
}


###
### Validate WORKER_PROCESSES
###
validate_worker_processes() {
	local name="${1}"
	local value="${2}"
	_log_env_valid "valid" "${name}" "${value}" "worker_processes" "${value}"
}


###
### Validate HTTPD2_ENABLE
###
validate_http2_enable() {
	local name="${1}"
	local value="${2}"
	_validate_bool "${name}" "${value}" "HTTP/2"
}


###
### Validate DOCKER_LOGS
###
validate_docker_logs() {
	local name="${1}"
	local value="${2}"
	_validate_bool "${name}" "${value}" "Log to" "0" "stdout and stderr" "/var/log/"
}



# -------------------------------------------------------------------------------------------------
# HELPER FUNCTIONS
# -------------------------------------------------------------------------------------------------

###
### Generic validator for bool (Enabled/Disabled)
###
_validate_bool() {
	local name="${1}"
	local value="${2}"
	local message="${3}"
	local ignore="${4:-0}"
	local on="${5:-Enabled}"
	local off="${5:-Disabled}"

	# Validate
	if ! is_bool "${value}"; then
		_log_env_valid "invalid" "${name}" "${value}" "Must be 0 or 1" ""
		exit 1
	fi

	# Check if we ignore the value
	if [ "${ignore}" = "1" ]; then
		_log_env_valid "ignore" "${name}" "${value}" "(disabled)"
		return
	fi

	# Show status
	if [ "${value}" = "0" ]; then
		_log_env_valid "valid" "${name}" "${value}" "${message}" "${off}"
	else
		_log_env_valid "valid" "${name}" "${value}" "${message}" "${on}"
	fi
}


###
### Validate *_VHOST_BACKEND
###     string: conf:<type>:<proto>:<host>:<port>
###     string: file:<file>
###
_validate_vhost_backend() {
	local name="${1}"
	local value="${2}"
	local vhost="${3}"          # either "main" or "mass"
	local vhost_enabled="${4}"  # either "0" or "1"

	backend_prefix="$( get_backend_prefix "${value}" )"           # file or conf
	backend_file_name="$( get_backend_file_file "${value}" )"     # filename
	backend_conf_type="$( get_backend_conf_type "${value}" )"     # phpfpm or rproxy
	backend_conf_prot="$( get_backend_conf_prot "${value}" )"     # tpc, http, https
	backend_conf_host="$( get_backend_conf_host "${value}" )"     # <host>
	backend_conf_port="$( get_backend_conf_port "${value}" )"     # <port>

	# 1. If no backend is specified
	if ! backend_has_backend "${value}"; then
		# Check if vhost is disabled
		if [ "${vhost_enabled}" = "0" ]; then
			_log_env_valid "ignore" "${name}" "${value}" "(vhost disabled)"
		else
			_log_env_valid "valid" "${name}" "${value}" "No remote backend" "Serving static files only"
		fi
		return
	fi

	# 2. Validate prefix
	if [ "${backend_prefix}" != "file" ] && [ "${backend_prefix}" != "conf" ]; then
		_log_env_valid "invalid" "${name}" "${value}" "Invalid format"
		_log_env_valid "invalid" "${name}" "${backend_prefix}" "Valid backend prefix: " "'conf' or 'file'"
		_log_backend_examples "all"
		exit 1
	fi

	# 3. Validate file:<file> - the filename
	if [ "${backend_prefix}" = "file" ]; then
		if ! backend_is_valid_file_file "${value}"; then
			_log_env_valid "invalid" "${name}" "${value}" "Invalid format"
			_log_env_valid "invalid" "${name}" "${backend_file_name}" "filename is invalid"
			_log_backend_examples "file"
			exit 1
		fi
	fi

	if [ "${backend_prefix}" = "conf" ]; then

		# 4. Validate conf <type>
		if ! backend_is_valid_conf_type "${value}"; then
			_log_env_valid "invalid" "${name}" "${value}" "Invalid format"
			_log_env_valid "invalid" "${name}" "${backend_conf_type}" "<type> is invalid. Must be: " "'phpfpm' or 'rproxy'"
			_log_backend_examples "conf"
			exit 1
		fi
		# 5. Validate conf <protocol>
		if ! backend_is_valid_conf_prot "${value}"; then
			_log_env_valid "invalid" "${name}" "${value}" "Invalid format"
			_log_env_valid "invalid" "${name}" "${backend_conf_prot}" "<proto> is invalid. Must be: " "'tcp', 'http' or 'https'"
			_log_backend_examples "conf"
			exit 1
		fi
		# 6. Validate conf <protocol> phpfpm == tcp
		if [ "${backend_conf_type}" = "phpfpm" ]; then
			if [ "${backend_conf_prot}" != "tcp" ]; then
				_log_env_valid "invalid" "${name}" "${value}" "Invalid format"
				_log_env_valid "invalid" "${name}" "${backend_conf_prot}" "phpfpm only supports protocol " "'tcp'"
				_log_backend_examples "conf"
				exit 1
			fi
		fi
		# 7. Validate conf <protocol> rproxy == http(s)?
		if [ "${backend_conf_type}" = "rproxy" ]; then
			if [ "${backend_conf_prot}" != "http" ] && [ "${backend_conf_prot}" != "https" ]; then
				_log_env_valid "invalid" "${name}" "${value}" "Invalid format"
				_log_env_valid "invalid" "${name}" "${backend_conf_prot}" "rproxy only supports protocol " "'http' or 'https'"
				_log_backend_examples "conf"
				exit 1
			fi
		fi
		# 8. Validate conf <host>
		if ! backend_is_valid_conf_host "${value}"; then
			_log_env_valid "invalid" "${name}" "${value}" "Invalid format"
			_log_env_valid "invalid" "${name}" "${backend_conf_host}" "<host> is invalid. Must be: " "hostname, IPv4 or IPv6 addr"
			_log_backend_examples "conf"
			exit 1
		fi
		# 8. Validate conf <port>
		if ! backend_is_valid_conf_port "${value}"; then
			_log_env_valid "invalid" "${name}" "${value}" "Invalid format"
			_log_env_valid "invalid" "${name}" "${backend_conf_port}" "<port> is invalid. Must be valid port"
			_log_backend_examples "conf"
			exit 1
		fi

	fi

	# 9. Validate MAIN_VHOST_BACKEND (does not YET support file:<file>)
	# TODO: implement file:<file> support for MAIN_VHOST
	if [ "${vhost}" = "main" ]; then
		if [ "${backend_prefix}" = "file" ]; then
			_log_env_valid "invalid" "${name}" "${value}" "Unsupported"
			_log_env_valid "invalid" "${name}" "${backend_prefix}" "\$MAIN_VHOST_BACKEND does not support 'file'. Use: " "'conf'"
			_log_backend_examples "conf"
			exit 1
		fi
	fi

	# 10. MASS_VHOST_BACKEND cannot use rproxy, otherwise all autogenerated mass vhosts
	#     would reverse proxy to the same <host>:<port>, which does not make any sense at all.
	#     Instead, it only supports file:<file>, so that each project can define it's own reverse
	#     proxy definition in a file and each can have different hosts and ports.
	if [ "${vhost}" = "mass" ]; then
		if [ "${backend_prefix}" = "conf" ] && [ "${backend_conf_type}" = "rproxy" ]; then
			_log_env_valid "invalid" "${name}" "${value}" "Unsupported"
			_log_env_valid "invalid" "${name}" "\$MASS_VHOST_BACKEND' does not support 'conf' with type 'rproxy"
			log "err" ""
			log "err" "Why is this?"
			log "err" "    The MASS_VHOST automatically creates a vhost for each directory present in: ${MASS_DOCROOT_BASE}/"
			log "err" "    Now imagine you specify a reverse proxy at http://example:3000."
			log "err" "    Then every automatically created virtual host would point to that address."
			log "err" "    You will end up with many virtual hosts all pointing the the same backend."
			log "err" "    This makes only sense with 'phpfpm'."
			log "err" ""
			log "err" "What should I do?"
			log "err" "    Use 'MASS_VHOST_BACKEND=file:config.txt' instead!"
			log "err" "    This allows you to add a config file to every project at: ${MASS_DOCROOT_BASE}/<project>/${MASS_VHOST_TPL}/config.txt"
			log "err" "    Then every project can define its own reverse proxy backend."
			log "err" ""
			log "err" "What is in that file?"
			log "err" "    The file contains a single line with the same config string you supplied for MASS_VHOST_BACKEND:"
			log "err" ""
			log "err" "        ${value}"
			log "err" ""
			log "err" "    Each project config file can also have different protocol/host/port values to make sense."
			exit 1
		fi
	fi

	# 11. Check if vhost is disabled
	if [ "${vhost_enabled}" = "0" ]; then
		_log_env_valid "ignore" "${name}" "${value}" "(vhost disabled)"
		return
	fi

	# 12. Show settings (file)
	if [ "${backend_prefix}" = "file" ]; then
		if [ "${vhost}" = "main" ]; then
			_log_env_valid "valid" "${name}" "${value}" "Backend set in file" "${MAIN_DOCROOT_BASE}/${MAIN_VHOST_TPL}/${backend_file_name}"
		else
			_log_env_valid "valid" "${name}" "${value}" "Backend set in file" "${MASS_DOCROOT_BASE}/<project>/${MASS_VHOST_TPL}/${backend_file_name}"
		fi
	# 13. Show settings (conf)
	elif [ "${backend_prefix}" = "conf" ]; then
		if [ "${backend_conf_type}" = "phpfpm" ]; then
			_log_env_valid "valid" "${name}" "${value}" "PHP via PHP-FPM" "Remote: ${backend_conf_prot}://${backend_conf_host}:${backend_conf_port}"
		elif [ "${backend_conf_type}" = "rproxy" ]; then
			_log_env_valid "valid" "${name}" "${value}" "Reverse Proxy" "Remote: ${backend_conf_prot}://${backend_conf_host}:${backend_conf_port}"
		fi
	fi
}


###
### Validate *_VHOST_BACKEND_TIMEOUT
###
_validate_vhost_backend_timeout() {
	local name="${1}"
	local value="${2}"
	local vhost_enabled="${3}"

	if ! is_int "${value}"; then
		_log_env_valid "invalid" "${name}" "${value}" "Invalid timeout. Must be positive integer"
		exit 1
	fi
	# Check if vhost is disabled
	if [ "${vhost_enabled}" = "0" ]; then
		_log_env_valid "ignore" "${name}" "${value}" "(vhost disabled)"
		return
	fi
	_log_env_valid "valid" "${name}" "${value}" "Timeout: " "${value}sec"
}


###
### Validate *_VHOST_DOCROOT
###
_validate_vhost_docroot() {
	local name="${1}"
	local value="${2}"
	local vhost_enabled="${3}"
	local vhost_backend="${4}"
	local docroot_path="${5}"

	# Show ignored
	if [ "${vhost_enabled}" = "0" ]; then
		_log_env_valid "ignore" "${name}" "${value}" "(vhost disabled)"
		return
	fi
	# Check if we have a backend defined
	if backend_has_backend "${value}"; then
		if [ "$( get_backend_conf_type "${vhost_backend}" )" = "rproxy" ]; then
			_log_env_valid "ignore" "${name}" "${value}" "(using rproxy)"
			return
		fi
	fi
	_log_env_valid "valid" "${name}" "${value}" "Document root: " "${docroot_path}"
}


###
### Validate *_VHOST_SSL_TYPE
###
_validate_vhost_ssl_type() {
	local name="${1}"
	local value="${2}"
	local vhost_enabled="${3}"

	if [ "${value}" != "plain" ] && [ "${value}" != "ssl" ] && [ "${value}" != "both" ] && [ "${value}" != "redir" ]; then
		_log_env_valid "invalid" "${name}" "${value}" "Invalid type. Must be one of: " "plain, ssl, both, redir"
		exit 1
	fi

	# Show ignored
	if [ "${vhost_enabled}" = "0" ]; then
		_log_env_valid "ignore" "${name}" "${value}" "(vhost disabled)"
		return
	fi

	if [ "${value}" = "plain" ]; then
		_log_env_valid "valid" "${name}" "${value}" "Vhost protocol" "HTTP only"
	elif [ "${value}" = "ssl" ]; then
		_log_env_valid "valid" "${name}" "${value}" "Vhost protocol" "HTTPS only"
	elif [ "${value}" = "both" ]; then
		_log_env_valid "valid" "${name}" "${value}" "Vhost protocol" "HTTP and HTTPS"
	elif [ "${value}" = "redir" ]; then
		_log_env_valid "valid" "${name}" "${value}" "Vhost protocol" "Redirect HTTP -> HTTPS"
	fi
}


###
### Validate *_VHOST_TPL: vhost-gen template directory
###
_validate_vhost_tpl() {
	local name="${1}"
	local value="${2}"
	local vhost_enabled="${3}"
	local template_path="${4}"

	# Show ignored
	if [ "${vhost_enabled}" = "0" ]; then
		_log_env_valid "ignore" "${name}" "${value}" "(vhost disabled)"
		return
	fi
	_log_env_valid "valid" "${name}" "${value}" "Template dir" "${template_path}"
}


# -------------------------------------------------------------------------------------------------
# Logger
# -------------------------------------------------------------------------------------------------

###
### Use custom logger to log env variable validity
###
_log_env_valid() {
	local state="${1}"         # 'valid', `ignore` or 'invalid'
	local name="${2}"          # Variable name
	local value="${3}"         # Variable value
	local message="${4:-}"     # Message: what will happen (valid) or expected format (invalid)
	local message_val="${5:-}" # value for message

	local clr_valid="\033[0;32m"    # green
	local clr_invalid="\033[0;31m"  # red

	local clr_expect="\033[0;31m"   # red
	local clr_ignore="\033[0;34m"   # red

	local clr_ok="\033[0;32m"       # green
	local clr_fail="\033[0;31m"     # red
	local clr_rst="\033[0m"

	if [ "${state}" = "valid" ]; then
		log "ok" "$( \
			printf "${clr_ok}%-11s${clr_rst}%-8s${clr_valid}\$%-27s${clr_rst}%-20s${clr_valid}%s${clr_rst}\n" \
				"[OK]" \
				"Valid" \
				"${name}" \
				"${message}" \
				"${message_val}" \
		)" "1"
	elif [ "${state}" = "ignore" ]; then
		log "ok" "$( \
			printf "${clr_ok}%-11s${clr_rst}%-8s${clr_rst}\$%-27s${clr_ignore}%-20s${clr_rst}%s\n" \
				"[OK]" \
				"Valid" \
				"${name}" \
				"ignored" \
				"${message}" \
		)" "1"
	elif [ "${state}" = "invalid" ]; then
		log "err" "$( \
			printf "${clr_fail}%-11s${clr_rst}%-8s${clr_invalid}\$%-27s${clr_rst}${clr_invalid}'%s'${clr_rst}. %s${clr_expect}%s${clr_rst}\n" \
				"[ERR]" \
				"Invalid" \
				"${name}" \
				"${value}" \
				"${message}" \
				"${message_val}" \
		)" "1"
	else
		log "????" "Internal: Wrong value given to _log_env_valid"
		exit 1
	fi
}


###
### Log backend examples as error messages
###
_log_backend_examples() {
	local show="${1}"  # "all", "file" or "conf"

	log "err" ""
	if [ "${show}" = "all" ] || [ "${show}" = "conf" ]; then
		log "err" "Format: conf:<type>:<proto>:<host>:<port>"
	fi
	if [ "${show}" = "all" ] || [ "${show}" = "file" ]; then
		log "err" "Format: file:<file>"
	fi

	if [ "${show}" = "all" ] || [ "${show}" = "conf" ]; then
		log "err" ""
		log "err" "Example: conf:phpfpm:tcp:10.0.0.100:9000"
		log "err" "Example: conf:phpfpm:tcp:domain.com:9000"
		log "err" ""
		log "err" "Example: conf:rproxy:http:10.0.0.100:3000"
		log "err" "Example: conf:rproxy:http:domain.com:443"
		log "err" ""
		log "err" "Example: conf:rproxy:https:10.0.0.100:8080"
		log "err" "Example: conf:rproxy:https:domain.com:8443"
	fi
	if [ "${show}" = "all" ] || [ "${show}" = "file" ]; then
		log "err" ""
		log "err" "Example: file:config.txt"
	fi
}
