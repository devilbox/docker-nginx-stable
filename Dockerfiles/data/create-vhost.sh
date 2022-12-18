#!/usr/bin/env bash

set -e
set -u
set -o pipefail

VHOST_PATH="${1}"     # watcherd (%%p): Absolute path to project directory
VHOST_NAME="${2}"     # watcherd (%%n): Project directory name
VHOST_TLD="${3}"      # ${MASS_VHOST_TLD_SUFFIX}
VHOST_TPL="${4}"      # %%p/${MASS_VHOST_TPL}
MASS_VHOST_DOCROOT="${5}"
HTTP2_ENABLE="${6}"
DOCKER_LOGS="${7}"
TIMEOUT="${8}"
CA_KEY="${9}"         # ${CA_KEY}
CA_CRT="${10}"         # ${CA_CRT}
GENERATE_SSL="${11}"   # ${MASS_VHOST_SSLGEN}
GEN_MODE="${12}"       # ${MASS_VHOST_SSL_TYPE}
BACKEND="${13}"        # ${MASS_VHOST_BACKEND}
VERBOSE="${14:-}"     # "-v" or empty


# -------------------------------------------------------------------------------------------------
# ENTRYPOINT BOOTSTRAP START (copied from docker-entrypoint.sh)
# -------------------------------------------------------------------------------------------------

###
### This allows us to be able to access all entrypoint functions
###

###
### DEBUG_ENTRYPOINT
###
if [ -z "${DEBUG_ENTRYPOINT:-}" ]; then
	DEBUG_ENTRYPOINT="${DEFAULT_DEBUG_ENTRYPOINT}"
fi
if [ "${DEBUG_ENTRYPOINT}" != "0" ] \
	&& [ "${DEBUG_ENTRYPOINT}" != "1" ] \
	&& [ "${DEBUG_ENTRYPOINT}" != "2" ] \
	&& [ "${DEBUG_ENTRYPOINT}" != "3" ] \
	&& [ "${DEBUG_ENTRYPOINT}" != "4" ]; then
	# Arbitrary integer (set to highest value
	if [ -n "${DEBUG_ENTRYPOINT##*[!0-9]*}" ]; then
		DEBUG_ENTRYPOINT=4
	else
		DEBUG_ENTRYPOINT="${DEFAULT_DEBUG_ENTRYPOINT}"
	fi
fi

###
### DEBUG_RUNTIME
###
if [ -z "${DEBUG_RUNTIME:-}" ]; then
	DEBUG_RUNTIME="${DEFAULT_DEBUG_RUNTIME}"
fi
if [ "${DEBUG_RUNTIME}" != "0" ] && [ "${DEBUG_RUNTIME}" != "1" ]; then
	DEBUG_RUNTIME="${DEFAULT_DEBUG_RUNTIME}"
fi

export "DEBUG_ENTRYPOINT"
export "DEBUG_RUNTIME"

ENTRYPOINT_DIR="/docker-entrypoint.d"          # All entrypoint scripts

###
### Source available library functions
###
# shellcheck disable=SC2012
for f in $( ls -1 "${ENTRYPOINT_DIR}/.lib/"*.sh | sort -u ); do
	# shellcheck disable=SC1090
	. "${f}"
done

###
### Source available HTTPD functions
###
# shellcheck disable=SC2012
for f in $( ls -1 "${ENTRYPOINT_DIR}/.httpd/"*.sh | sort -u ); do
	# shellcheck disable=SC1090
	. "${f}"
done

###
### Source available entrypoint scripts
###
# shellcheck disable=SC2012
#for f in $( ls -1 "${ENTRYPOINT_DIR}/"*.sh | sort -u ); do
#	# shellcheck disable=SC1090
#	. "${f}"
#done



# -------------------------------------------------------------------------------------------------
# SSL
# -------------------------------------------------------------------------------------------------

###
### Generate vhost SSL certificate
###
if [ "${GENERATE_SSL}" = "1" ]; then
	if [ ! -d "/etc/httpd/cert/mass" ]; then
		mkdir -p "/etc/httpd/cert/mass"
	fi
	_email="admin@${VHOST_NAME}${VHOST_TLD}"
	_domain="${VHOST_NAME}${VHOST_TLD}"
	_domains="*.${VHOST_NAME}${VHOST_TLD}"
	_out_key="/etc/httpd/cert/mass/${VHOST_NAME}${VHOST_TLD}.key"
	_out_csr="/etc/httpd/cert/mass/${VHOST_NAME}${VHOST_TLD}.csr"
	_out_crt="/etc/httpd/cert/mass/${VHOST_NAME}${VHOST_TLD}.crt"
	if ! cert-gen -v -c DE -s Berlin -l Berlin -o Devilbox -u Devilbox -n "${_domain}" -e "${_email}" -a "${_domains}" "${CA_KEY}" "${CA_CRT}" "${_out_key}" "${_out_csr}" "${_out_crt}"; then
		echo "[FAILED] Failed to add SSL certificate for ${VHOST_NAME}${VHOST_TLD}"
		exit 1
	fi
fi



# -------------------------------------------------------------------------------------------------
# VHOST-GEN
# -------------------------------------------------------------------------------------------------

###
### Validate Backend
###
if [ -n "${BACKEND}" ]; then
	###
	### Backend=file:<file>
	###
	if echo "${BACKEND}" | grep -E '^file:' >/dev/null; then
		# No need to validate backend string, has been done already in entrypoint
		BACKEND_FILE_NAME="$( echo "${BACKEND}" | awk -F':' '{print $2}' )"
		BACKEND_FILE_PATH="${VHOST_TPL}${BACKEND_FILE_NAME}"
		log "info" "[Project: ${VHOST_NAME}] Backend config specified via file: ${VHOST_TPL}${BACKEND_FILE_NAME}"
		if [ ! -f "${BACKEND_FILE_PATH}" ]; then
			log "info" "[Project: ${VHOST_NAME}] Backend file does not exist: ${VHOST_TPL}${BACKEND_FILE_NAME}"
			log "info" "[Project: ${VHOST_NAME}] Backend defaulting to: serve static files only"
			BACKEND="" # Empty the backend
		else
			BACKEND_CONFIG="$( cat "${BACKEND_FILE_PATH}" )"
			log "info" "[Project: ${VHOST_NAME}] Backend config file contents: ${BACKEND_CONFIG}"
			if ! BACKEND_ERROR="$( backend_conf_is_valid "${BACKEND_CONFIG}" )"; then
				log "warn" "[Project: ${VHOST_NAME}] Backend config is invalid: ${BACKEND_ERROR}"
				log "warn" "[Project: ${VHOST_NAME}] Backend defaulting to: serve static files only"
				BACKEND="" # Empty the backend
			else
				BACKEND="${BACKEND_CONFIG}" # Use config from file
			fi
		fi
	###
	### Backend=conf:<type>:<proto>:<host>:<port>
	###
	else
		log "info" "[Project: ${VHOST_NAME}] Backend config specified via env: ${BACKEND}"
		# No need to validate backend string, has been done already in entrypoint
	fi
else
	log "info" "[Project: ${VHOST_NAME}] No Backend specified: Serving static files only"
fi


###
### Evaluate Backend
###
if [ -n "${BACKEND}" ]; then
	be_type="$( get_backend_conf_type "${BACKEND}" )"     # phpfpm or rproxy
	be_prot="$( get_backend_conf_prot "${BACKEND}" )"     # tpc, http, https
	be_host="$( get_backend_conf_host "${BACKEND}" )"     # <host>
	be_port="$( get_backend_conf_port "${BACKEND}" )"     # <port>
	if [ "${be_type}" = "phpfpm" ]; then
		log "info" "[Project: ${VHOST_NAME}] Backend PHP-FPM Remote: ${be_prot}://${be_host}:${be_port}"
		# TODO: Generate cmd
	elif [ "${be_type}" = "rproxy" ]; then
		log "info" "[Project: ${VHOST_NAME}] Backend Reverse Proxy: ${be_prot}://${be_host}:${be_port}"
		# TODO: Generate cmd
	fi
else
	# TODO: Generate cmd
	be_type=""
	be_prot=""
	be_host=""
	be_port=""
fi

INDICES="index.html, index.htm"
PHP_FPM_ENABLE=0
if [ "${be_type}" = "phpfpm" ]; then
	INDICES="index.php, index.html, index.htm"
	PHP_FPM_ENABLE=1
fi


VHOST_GEN_CONFIG_NAME="mass-${VHOST_NAME}.yml"
VHOST_GEN_CONFIG_PATH="/etc/vhost-gen/${VHOST_GEN_CONFIG_NAME}"

###
### Generate vhost-gen config file (not template)
###
# TODO: variablize nginx
# TODO: variablize alias
generate_vhostgen_conf \
	"nginx" \
	"/etc/httpd/vhost.d" \
	"${VHOST_TLD}" \
	"${MASS_VHOST_DOCROOT}" \
	"${INDICES}" \
	"$( to_python_bool "${HTTP2_ENABLE}" )" \
	"/etc/httpd/cert/mass" \
	"/etc/httpd/cert/mass" \
	"" \
	"$( to_python_bool "${DOCKER_LOGS}" )" \
	"$( to_python_bool "${PHP_FPM_ENABLE}" )" \
	"${be_host}" \
	"${be_port}" \
	"${TIMEOUT}" \
	'/devilbox-api/:/var/www/default/api:http(s)?://(.*)$' \
	"no" \
	"/httpd-status" > "${VHOST_GEN_CONFIG_PATH}"


###
### Default vhost-gen command
###

if [ "${DEBUG_ENTRYPOINT}" -gt "1" ]; then
	verbose="-v"
else
	verbose=""
fi


if [ "${be_type}" = "rproxy" ]; then
	cmd="vhost-gen -r \"${be_prot}://${be_host}:${be_port}\" -l / -n \"${VHOST_NAME}\" -c \"${VHOST_GEN_CONFIG_PATH}\" -o \"${VHOST_TPL}\" -s ${verbose} -m ${GEN_MODE}"
else
	cmd="vhost-gen -p \"${VHOST_PATH}\" -n \"${VHOST_NAME}\" -c \"${VHOST_GEN_CONFIG_PATH}\" -o \"${VHOST_TPL}\" -s ${verbose} -m ${GEN_MODE}"
fi

# TODO: do we use tempalte-main/ ? Check other nginx images
#run "vhost-gen -n localhost -r ${be_prot}://${be_host}:${be_port} -l / -t /etc/vhost-gen/templates-main/ -c ${config} -o ${template} ${verbose} -d -s -m ${ssl_type}"


# -------------------------------------------------------------------------------------------------
# VHOST-GEN
# -------------------------------------------------------------------------------------------------


###
### Verbose output?
###
if [ -n "${VERBOSE}" ]; then
	echo "\$ ${cmd}"
fi

###
### Execute
###
if ! eval "${cmd}"; then
	echo "[FAILED] Failed to add vhost for ${VHOST_NAME}${VHOST_TLD}"
	exit 1
fi
