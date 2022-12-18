#!/usr/bin/env bash

set -e
set -u
set -o pipefail

###################################################################################################
###################################################################################################
###
### GLOBAL VARIABLES
###
###################################################################################################
###################################################################################################

# -------------------------------------------------------------------------------------------------
# GENERAL GLOBAL VARIABLES
# -------------------------------------------------------------------------------------------------

### The following env variables are set inside the Dockerfiles
###   MY_USER
###   MY_GROUP
###   HTTPD_START
###   HTTPD_RELOAD

###
### Base path for main (default) document root
###
MAIN_DOCROOT_BASE="/var/www/default"
MASS_DOCROOT_BASE="/shared/httpd"

###
### OpenSSL Certificate Authority file to generate
###
### If the /ca directory is mounted and those files already exist
### a new ca will not be generated, but reused.
###
CA_KEY=/ca/devilbox-ca.key
CA_CRT=/ca/devilbox-ca.crt

###
### Path to scripts to source
###
ENTRYPOINT_DIR="/docker-entrypoint.d"          # All entrypoint scripts
VHOST_GEN_DIR="/etc/vhost-gen/templates"   # vhost-gen default templates
VHOST_GEN_CUST_DIR="/etc/vhost-gen.d"      # vhost-gen custom templates (must be mounted to add)

###
### Wait this many seconds to start watcherd after httpd has been started
###
WATCHERD_STARTUP_DELAY="3"


# -------------------------------------------------------------------------------------------------
# DEFAULT LOGGER
# -------------------------------------------------------------------------------------------------

###
### Set the default debug level for entrypoint and runtime
###
DEFAULT_DEBUG_ENTRYPOINT="2"
DEFAULT_DEBUG_RUNTIME="1"

###
### Ensure that the following globals have a value:
###
###    DEBUG_ENTRYPOINT
###    DEBUG_RUNTIME
###
### If not, fall back to these
###
###    DEFAULT_DEBUG_ENTRYPOINT
###    DEFAULT_DEBUG_RUNTIME
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
if [ "${DEBUG_RUNTIME}" != "0" ] \
	&& [ "${DEBUG_RUNTIME}" != "1" ] \
	&& [ "${DEBUG_RUNTIME}" != "2" ]; then
	# Arbitrary integer (set to highest value
	if [ -n "${DEBUG_RUNTIME##*[!0-9]*}" ]; then
		DEBUG_RUNTIME=2
	else
		DEBUG_RUNTIME="${DEFAULT_DEBUG_RUNTIME}"
	fi
fi

export "DEBUG_ENTRYPOINT"
export "DEBUG_RUNTIME"



###################################################################################################
###################################################################################################
###
### INCLUDES
###
###################################################################################################
###################################################################################################

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
for f in $( ls -1 "${ENTRYPOINT_DIR}/"*.sh | sort -u ); do
	# shellcheck disable=SC1090
	. "${f}"
done



###################################################################################################
###################################################################################################
###
### MAIN ENTRYPOINT
###
###################################################################################################
###################################################################################################

# -------------------------------------------------------------------------------------------------
# LOG SETTINGS
# -------------------------------------------------------------------------------------------------

###
### Set Debug level
###
DEBUG_LEVEL="$( env_get "DEBUG_ENTRYPOINT" "${DEFAULT_DEBUG_ENTRYPOINT}" )"
log "info" "Debug level: ${DEBUG_LEVEL}"

DEBUG_RUNTIME="$( env_get "DEBUG_RUNTIME" "${DEFAULT_DEBUG_RUNTIME}" )"
log "info" "Runtime debug: ${DEBUG_RUNTIME}"


# -------------------------------------------------------------------------------------------------
# SET ENVIRONMENT VARIABLES AND DEFAULT VALUES
# -------------------------------------------------------------------------------------------------

log "info" "-------------------------------------------------------------------------"
log "info" "Environment Variables (set/default)"
log "info" "-------------------------------------------------------------------------"

env_var_export "NEW_UID"
env_var_export "NEW_GID"
env_var_export "TIMEZONE" "UTC"

env_var_export "MAIN_VHOST_ENABLE" "1"
env_var_export "MAIN_VHOST_BACKEND"
env_var_export "MAIN_VHOST_BACKEND_TIMEOUT" "180"
env_var_export "MAIN_VHOST_DOCROOT" "htdocs"
env_var_export "MAIN_VHOST_SSL_TYPE" "plain"
env_var_export "MAIN_VHOST_SSL_CN" "localhost"
env_var_export "MAIN_VHOST_TPL" "cfg"
env_var_export "MAIN_VHOST_STATUS_ENABLE" "0"
env_var_export "MAIN_VHOST_STATUS_ALIAS" "/httpd-status"

env_var_export "MASS_VHOST_ENABLE" "0"
env_var_export "MASS_VHOST_BACKEND"
env_var_export "MASS_VHOST_BACKEND_TIMEOUT" "180"
env_var_export "MASS_VHOST_DOCROOT" "htdocs"
env_var_export "MASS_VHOST_TLD_SUFFIX" ".loc"
env_var_export "MASS_VHOST_SSL_TYPE" "plain"
env_var_export "MASS_VHOST_TPL" "cfg"

env_var_export "WORKER_CONNECTIONS" "1024"
env_var_export "WORKER_PROCESSES" "auto"
env_var_export "HTTP2_ENABLE" "1"
env_var_export "DOCKER_LOGS" "1"

export MAIN_VHOST_SSL_GEN=0
export MASS_VHOST_SSL_GEN=0
if [ "${MAIN_VHOST_SSL_TYPE}" != "plain" ]; then export MAIN_VHOST_SSL_GEN=1; fi
if [ "${MASS_VHOST_SSL_TYPE}" != "plain" ]; then export MASS_VHOST_SSL_GEN=1; fi


# -------------------------------------------------------------------------------------------------
# VERIFY ENVIRONMENT VARIABLES
# -------------------------------------------------------------------------------------------------

log "info" "-------------------------------------------------------------------------"
log "info" "Validate Settings"
log "info" "-------------------------------------------------------------------------"

log "info" "Settings: General:"
env_var_validate "NEW_UID"
env_var_validate "NEW_GID"
env_var_validate "TIMEZONE"

log "info" "Settings: Main Vhost:"
env_var_validate "MAIN_VHOST_ENABLE"
env_var_validate "MAIN_VHOST_BACKEND"
env_var_validate "MAIN_VHOST_BACKEND_TIMEOUT"
env_var_validate "MAIN_VHOST_DOCROOT"
env_var_validate "MAIN_VHOST_SSL_TYPE"
env_var_validate "MAIN_VHOST_SSL_CN"
env_var_validate "MAIN_VHOST_TPL"
env_var_validate "MAIN_VHOST_STATUS_ENABLE"
env_var_validate "MAIN_VHOST_STATUS_ALIAS"

log "info" "Settings: Mass Vhost:"
env_var_validate "MASS_VHOST_ENABLE"
env_var_validate "MASS_VHOST_BACKEND"
env_var_validate "MASS_VHOST_BACKEND_TIMEOUT"
env_var_validate "MASS_VHOST_DOCROOT"
env_var_validate "MASS_VHOST_TLD_SUFFIX"
env_var_validate "MASS_VHOST_SSL_TYPE"
env_var_validate "MASS_VHOST_TPL"

log "info" "Settings: Misc:"
env_var_validate "WORKER_CONNECTIONS"
env_var_validate "WORKER_PROCESSES"
env_var_validate "HTTP2_ENABLE"
env_var_validate "DOCKER_LOGS"


# -------------------------------------------------------------------------------------------------
# APPLY SETTINGS
# -------------------------------------------------------------------------------------------------

log "info" "-------------------------------------------------------------------------"
log "info" "Apply Settings"
log "info" "-------------------------------------------------------------------------"

###
### Change uid/gid
###
set_uid "${NEW_UID}" "${MY_USER}"
set_gid "${NEW_GID}" "${MY_USER}" "${MY_GROUP}"

###
### Set timezone
###
set_timezone "${TIMEZONE}"



# -------------------------------------------------------------------------------------------------
# VHOST-GEN: ALL
# -------------------------------------------------------------------------------------------------

###
### Copy custom vhost-gen template (if they are mounted and exist)
###
vhost_gen_copy_custom_template "${VHOST_GEN_CUST_DIR}" "${VHOST_GEN_DIR}" "nginx.yml" "${DEBUG_LEVEL}"



# -------------------------------------------------------------------------------------------------
# VHOST-GEN: MAIN
# -------------------------------------------------------------------------------------------------


###
### Generate
###
vhost_gen_main_generate_config \
	"nginx" \
	"${MAIN_VHOST_BACKEND}" \
	"${HTTP2_ENABLE}" \
	"${MAIN_VHOST_STATUS_ENABLE}" \
	"${MAIN_VHOST_STATUS_ALIAS}" \
	"${DOCKER_LOGS}" \
	"${MAIN_VHOST_BACKEND_TIMEOUT}" \
	"/etc/vhost-gen/main.yml"

vhost_gen_main_generate \
	"${MAIN_VHOST_ENABLE}" \
	"${MAIN_DOCROOT_BASE}/${MAIN_VHOST_DOCROOT}" \
	"${MAIN_VHOST_BACKEND}" \
	"/etc/vhost-gen/main.yml" \
	"${MAIN_DOCROOT_BASE}/${MAIN_VHOST_TPL}" \
	"${MAIN_VHOST_SSL_TYPE}"



# -------------------------------------------------------------------------------------------------
# CERT-GEN CONFIGURATION
# -------------------------------------------------------------------------------------------------


###
### Create Certificate Signing request
###
cert_gen_generate_ca "${CA_KEY}" "${CA_CRT}"


###
### Generate main vhost ssl certificate
###
# shellcheck disable=SC2153
cert_gen_generate_cert \
	"${MAIN_VHOST_ENABLE}" \
	"${MAIN_VHOST_SSL_TYPE}" \
	"${CA_KEY}" \
	"${CA_CRT}" \
	"/etc/httpd/cert/main/localhost.key" \
	"/etc/httpd/cert/main/localhost.csr" \
	"/etc/httpd/cert/main/localhost.crt" \
	"${MAIN_VHOST_SSL_CN}"



# -------------------------------------------------------------------------------------------------
# FIX DIRECTORY PERMISSIONS
# -------------------------------------------------------------------------------------------------

fix_perm "/ca" "1"



# -------------------------------------------------------------------------------------------------
# NGINX-SPECIFIC BASIC SETTINGS
# -------------------------------------------------------------------------------------------------

###
### Nginx settings
###
nginx_set_worker_processess "${WORKER_PROCESSES}"
nginx_set_worker_connections "${WORKER_CONNECTIONS}"



# -------------------------------------------------------------------------------------------------
# MAIN ENTRYPOINT
# -------------------------------------------------------------------------------------------------

_HTTPD_VERSION="$( nginx -V 2>&1 | head -1 | awk '{print $3}' )"
_SUPVD_VERSION="$( supervisord -v )"

log "info" "-------------------------------------------------------------------------"
log "info" "Main Entrypoint"
log "info" "-------------------------------------------------------------------------"

###
### MASS_VHOST requires supervisor to run (watcherd)
###
if [ "${MASS_VHOST_ENABLE}" -eq "1" ]; then
	# watcherd always starts with '-v' regardless of DEBUG_RUNTIME
	verbose="-v"
	if [ "${DEBUG_RUNTIME}" -gt "0" ]; then
		verbose="-v"
	fi

	# Create watcherd sub commands
	watcherd_add="create-vhost.sh"
	watcherd_add+=" \\\"%%p\\\""
	watcherd_add+=" \\\"%%n\\\""
	watcherd_add+=" \\\"${MASS_VHOST_TLD_SUFFIX}\\\""
	watcherd_add+=" \\\"%%p/${MASS_VHOST_TPL}/\\\""
	watcherd_add+=" \\\"${MASS_VHOST_DOCROOT}\\\""
	watcherd_add+=" \\\"${HTTP2_ENABLE}\\\""
	watcherd_add+=" \\\"${DOCKER_LOGS}\\\""
	watcherd_add+=" \\\"${MASS_VHOST_BACKEND_TIMEOUT}\\\""
	watcherd_add+=" \\\"${CA_KEY}\\\""
	watcherd_add+=" \\\"${CA_CRT}\\\""
	watcherd_add+=" \\\"${MASS_VHOST_SSL_GEN}\\\""
	watcherd_add+=" \\\"${MASS_VHOST_SSL_TYPE}\\\""
	watcherd_add+=" \\\"${MASS_VHOST_BACKEND}\\\""
	watcherd_add+=" \\\"${verbose}\\\""

	watcherd_del="rm /etc/httpd/vhost.d/%%n.conf"
	watcherd_tri="${HTTPD_RELOAD}"

	supervisord_create \
		"${HTTPD_START}" \
		"bash -c 'sleep ${WATCHERD_STARTUP_DELAY} && exec watcherd -c ${verbose} -p ${MASS_DOCROOT_BASE} -a \"${watcherd_add}\" -d \"${watcherd_del}\" -t \"${watcherd_tri}\"'" \
		"/etc/supervisord.conf"

	log "done" "Starting supervisord: ${_SUPVD_VERSION} [HTTPD: ${_HTTPD_VERSION}]"
	exec /usr/bin/supervisord -c /etc/supervisord.conf

###
### No MASS_VHOST: just start HTTPD as process 1.
###
else
	_HTTPD_VERSION="$( nginx -V 2>&1 | head -1 | awk '{print $3}' )"
	log "done" "Starting webserver: ${_HTTPD_VERSION}"
	exec "${HTTPD_START}"
fi
