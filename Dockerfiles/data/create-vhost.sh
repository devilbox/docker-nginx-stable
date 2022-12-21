#!/usr/bin/env bash

set -e
set -u
set -o pipefail


###
### Inputs (watcherd will call this script)
###
VHOST_NAME="${1}"             # vhost project directory name (via watcherd: "%n")
VHOST_PATH="${2}"             # vhost project directory path (via watcherd: "%p")
VHOST_DOCROOT_NAME="${3}"     # Document root subdir inside VHOST_PATH
VHOST_TLD_SUFFIX="${4}"       # TLD_SUFFIX to append to VHOST_NAME
VHOST_ALIASES_ALLOW="${5}"    # Additional allow aliases to generate (path:, url: cors:)
VHOST_ALIASES_DENY="${6}"     # Additional deny aliases to generate
VHOST_SSL_TYPE="${7}"         # SSL_TYPE: "plain", "ssl", "both", "redir"
VHOST_BACKEND="${8}"          # Backend string: file:* or cfg:*
VHOST_BACKEND_REWRITE="${9}"  # Backend Rewrite string: file:*
VHOST_BACKEND_TIMEOUT="${10}" # Timeout for backend in seconds
HTTP2_ENABLE="${11}"          # Enable HTTP2?
DOCKER_LOGS="${12}"           # Enable Docker logs?
CA_KEY_FILE="${13}"           # Path to CA key file
CA_CRT_FILE="${14}"           # Path to CA crt file
VHOSTGEN_TEMPLATE_DIR="${15}" # vhost-gen template dir (via watcherd: "%p/${MASS_VHOST_TPL_DIR}")
VHOSTGEN_HTTPD_SERVER="${16}" # nginx, apache22 or apache24 (determines the template to choose)



# -------------------------------------------------------------------------------------------------
# BOOTSTRAP
# -------------------------------------------------------------------------------------------------

###
### Bootstrap (Debug level and source .lib/ and .httpd/ functions)
###
# shellcheck disable=SC1090,SC1091
. "/docker-entrypoint.d/bootstrap/bootstrap.sh"



# -------------------------------------------------------------------------------------------------
# GENERATE SSL CERTIFICATES?
# -------------------------------------------------------------------------------------------------

###
### Generate vhost SSL certificate
###
if [ "${VHOST_SSL_TYPE}" != "plain" ]; then
	if [ ! -d "/etc/httpd/cert/mass" ]; then
		runtime "mkdir -p /etc/httpd/cert/mass"
	fi
	_email="admin@${VHOST_NAME}${VHOST_TLD_SUFFIX}"
	_domain="${VHOST_NAME}${VHOST_TLD_SUFFIX}"
	_domains="*.${VHOST_NAME}${VHOST_TLD_SUFFIX}"
	_out_key="/etc/httpd/cert/mass/${VHOST_NAME}${VHOST_TLD_SUFFIX}.key"
	_out_csr="/etc/httpd/cert/mass/${VHOST_NAME}${VHOST_TLD_SUFFIX}.csr"
	_out_crt="/etc/httpd/cert/mass/${VHOST_NAME}${VHOST_TLD_SUFFIX}.crt"
	if ! runtime \
		"cert-gen -v -c DE -s Berlin -l Berlin -o Devilbox -u Devilbox -n \"${_domain}\" -e \"${_email}\" -a \"${_domains}\" \"${CA_KEY_FILE}\" \"${CA_CRT_FILE}\" \"${_out_key}\" \"${_out_csr}\" \"${_out_crt}\"" \
		"Failed to add SSL certificate for ${VHOST_NAME}${VHOST_TLD_SUFFIX}"; then
		exit 1
	fi
fi



# -------------------------------------------------------------------------------------------------
# BACKEND string
# -------------------------------------------------------------------------------------------------

###
### Validate Backend
###
if [ -n "${VHOST_BACKEND}" ]; then
	###
	### Check if BACKEND_REWRITE is set
	###
	if [ -n "${VHOST_BACKEND_REWRITE}" ]; then
		# No need to validate backend string, has been done already in entrypoint
		BACKEND_REWRITE_FILE_NAME="$( echo "${VHOST_BACKEND_REWRITE}" | awk -F':' '{print $2}' )"
		BACKEND_REWRITE_FILE_PATH="${VHOSTGEN_TEMPLATE_DIR}${BACKEND_REWRITE_FILE_NAME}"

		# Backend file exists
		if [ -f "${BACKEND_REWRITE_FILE_PATH}" ]; then
			BACKEND_REWRITE_CONFIG="$( cat "${BACKEND_REWRITE_FILE_PATH}" )"
			log "info" "[${VHOST_NAME}${VHOST_TLD_SUFFIX}] Backend rewrite found:  ${BACKEND_REWRITE_FILE_PATH}"
			log "info" "[${VHOST_NAME}${VHOST_TLD_SUFFIX}] Backend rewrite config: ${BACKEND_REWRITE_CONFIG}"
			# Rewrite config is invalid
			if ! BACKEND_REWRITE_ERROR="$( backend_conf_is_valid "${BACKEND_REWRITE_CONFIG}" )"; then
				log "warn" "[${VHOST_NAME}${VHOST_TLD_SUFFIX}] Backend rewrite config is invalid: ${BACKEND_REWRITE_ERROR}"
				log "warn" "[${VHOST_NAME}${VHOST_TLD_SUFFIX}] Backend rewrite: skipping"
			else
				# Apply the overwrite
				log "info" "[${VHOST_NAME}${VHOST_TLD_SUFFIX}] Overwriting MASS_VHOST_BACKEND config"
				VHOST_BACKEND="${BACKEND_REWRITE_CONFIG}" # Use config from file
			fi
		fi
	fi

	###
	### BACKEND=file:<file>
	###
	if echo "${VHOST_BACKEND}" | grep -E '^file:' >/dev/null; then
		# No need to validate backend string, has been done already in entrypoint
		BACKEND_FILE_NAME="$( echo "${VHOST_BACKEND}" | awk -F':' '{print $2}' )"
		BACKEND_FILE_PATH="${VHOSTGEN_TEMPLATE_DIR}${BACKEND_FILE_NAME}"
		log "info" "[${VHOST_NAME}${VHOST_TLD_SUFFIX}] Backend config specified via file: ${VHOSTGEN_TEMPLATE_DIR}${BACKEND_FILE_NAME}"

		# [1/2] Backend file does not exist
		if [ ! -f "${BACKEND_FILE_PATH}" ]; then
			log "info" "[${VHOST_NAME}${VHOST_TLD_SUFFIX}] Backend file does not exist: ${VHOSTGEN_TEMPLATE_DIR}${BACKEND_FILE_NAME}"
			log "info" "[${VHOST_NAME}${VHOST_TLD_SUFFIX}] Backend defaulting to: serve static files only"
			VHOST_BACKEND="" # Empty the backend

		# [2/2] Backend exists (need to validate it)
		else
			BACKEND_CONFIG="$( cat "${BACKEND_FILE_PATH}" )"
			log "info" "[${VHOST_NAME}${VHOST_TLD_SUFFIX}] Backend config file contents: ${BACKEND_CONFIG}"
			if ! BACKEND_ERROR="$( backend_conf_is_valid "${BACKEND_CONFIG}" )"; then
				log "warn" "[${VHOST_NAME}${VHOST_TLD_SUFFIX}] Backend config is invalid: ${BACKEND_ERROR}"
				log "warn" "[${VHOST_NAME}${VHOST_TLD_SUFFIX}] Backend defaulting to: serve static files only"
				VHOST_BACKEND="" # Empty the backend
			else
				VHOST_BACKEND="${BACKEND_CONFIG}" # Use config from file
			fi
		fi
	###
	### Backend=conf:<type>:<proto>:<host>:<port>
	###
	else
		log "info" "[${VHOST_NAME}${VHOST_TLD_SUFFIX}] Backend config specified via env: ${VHOST_BACKEND}"
		# No need to validate backend string, has been done already in entrypoint
	fi
else
	log "info" "[${VHOST_NAME}${VHOST_TLD_SUFFIX}] No Backend specified: Serving static files only"
fi


###
### Evaluate Backend
###
be_type=""
be_prot=""
be_host=""
be_port=""
if [ -n "${VHOST_BACKEND}" ]; then
	be_type="$( get_backend_conf_type "${VHOST_BACKEND}" )"     # phpfpm or rproxy
	be_prot="$( get_backend_conf_prot "${VHOST_BACKEND}" )"     # tpc, http, https
	be_host="$( get_backend_conf_host "${VHOST_BACKEND}" )"     # <host>
	be_port="$( get_backend_conf_port "${VHOST_BACKEND}" )"     # <port>
	if [ "${be_type}" = "phpfpm" ]; then
		log "info" "[${VHOST_NAME}${VHOST_TLD_SUFFIX}] Backend PHP-FPM Remote: ${be_prot}://${be_host}:${be_port}"
	elif [ "${be_type}" = "rproxy" ]; then
		log "info" "[${VHOST_NAME}${VHOST_TLD_SUFFIX}] Backend Reverse Proxy: ${be_prot}://${be_host}:${be_port}"
	fi
fi

INDICES="index.html, index.htm"
PHP_FPM_ENABLE=0
if [ "${be_type}" = "phpfpm" ]; then
	INDICES="index.php, index.html, index.htm"
	PHP_FPM_ENABLE=1
fi



# -------------------------------------------------------------------------------------------------
# VHOSTGEN
# -------------------------------------------------------------------------------------------------

VHOSTGEN_CONFIG_NAME="mass-${VHOST_NAME}.yml"
VHOSTGEN_CONFIG_PATH="/etc/vhost-gen/${VHOSTGEN_CONFIG_NAME}"

###
### Generate vhost-gen config file (not template)
###
VHOSTGEN_TEMPLATE="$( \
	generate_vhostgen_conf \
		"${VHOSTGEN_HTTPD_SERVER}" \
		"/etc/httpd/vhost.d" \
		"${VHOST_TLD_SUFFIX}" \
		"${VHOST_DOCROOT_NAME}" \
		"${INDICES}" \
		"$( to_python_bool "${HTTP2_ENABLE}" )" \
		"/etc/httpd/cert/mass" \
		"/etc/httpd/cert/mass" \
		"" \
		"$( to_python_bool "${DOCKER_LOGS}" )" \
		"$( to_python_bool "${PHP_FPM_ENABLE}" )" \
		"${be_host}" \
		"${be_port}" \
		"${VHOST_BACKEND_TIMEOUT}" \
		"${VHOST_ALIASES_ALLOW}" \
		"${VHOST_ALIASES_DENY}" \
		"no" \
		"/httpd-status" \
)"
echo "${VHOSTGEN_TEMPLATE}" > "${VHOSTGEN_CONFIG_PATH}"
log "trace" "${VHOSTGEN_TEMPLATE}"

###
### Execute vhost-gen command
###
if [ "${be_type}" = "rproxy" ]; then
	if ! runtime \
		"vhost-gen -v -r \"${be_prot}://${be_host}:${be_port}\" -l / -n \"${VHOST_NAME}\" -c \"${VHOSTGEN_CONFIG_PATH}\" -o \"${VHOSTGEN_TEMPLATE_DIR}\" -s -m ${VHOST_SSL_TYPE}" \
		"Failed to add vhost for ${VHOST_NAME}${VHOST_TLD_SUFFIX}"; then
		exit 1
	fi
else
	if ! runtime \
		"vhost-gen -v -p \"${VHOST_PATH}\" -n \"${VHOST_NAME}\" -c \"${VHOSTGEN_CONFIG_PATH}\" -o \"${VHOSTGEN_TEMPLATE_DIR}\" -s -m ${VHOST_SSL_TYPE}" \
		"Failed to add vhost for ${VHOST_NAME}${VHOST_TLD_SUFFIX}"; then
		exit 1
	fi
fi
log "trace" "$( grep -v '^[[:blank:]]*$' "/etc/httpd/vhost.d/${VHOST_NAME}.conf" )"
