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

### The following env variables are set inside the Dockerfiles
###   MY_USER
###   MY_GROUP
###   HTTPD_START
###   HTTPD_RELOAD
###   VHOSTGEN_HTTPD_SERVER  # 'nginx', 'apache22' or 'apache24'

###
### Can be any of 'nginx', 'apache22' or 'apache24'
###
# VHOSTGEN_HTTPD_SERVER is set via Dockerfile
VHOSTGEN_HTTPD_SERVER_TEMPLATE="${VHOSTGEN_HTTPD_SERVER}.yml"

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
CA_KEY_FILE=/ca/devilbox-ca.key
CA_CRT_FILE=/ca/devilbox-ca.crt

###
### Path to scripts to source
###
ENTRYPOINT_DIR="/docker-entrypoint.d"              # All entrypoint scripts
VHOSTGEN_TEMPLATE_DIR="/etc/vhost-gen/templates"   # vhost-gen default templates
VHOSTGEN_CUST_TEMPLATE_DIR="/etc/vhost-gen.d"      # vhost-gen custom templates (must be mounted to add)

###
### Defailt aliases copied from previous images, just for the record
###
#MAIN_VHOST_ALIASES_ALLOW='/devilbox-api/:/var/www/default/api, /vhost.d/:/etc/httpd'
#MASS_VHOST_ALIASES_ALLOW='/devilbox-api/:/var/www/default/api:http(s)?://(.*)$'

###
### Wait this many seconds to start watcherd after httpd has been started
###
WATCHERD_STARTUP_DELAY="3"



###################################################################################################
###################################################################################################
###
### INCLUDES
###
###################################################################################################
###################################################################################################

###
### Bootstrap
###
# shellcheck disable=SC1090,SC1091
. "${ENTRYPOINT_DIR}/bootstrap/bootstrap.sh"



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
# SET ENVIRONMENT VARIABLES AND DEFAULT VALUES
# -------------------------------------------------------------------------------------------------

###
### Show Debug level
###
log "info" "Entrypoint debug: $( env_get "DEBUG_ENTRYPOINT" )"
log "info" "Runtime debug: $( env_get "DEBUG_RUNTIME" )"


###
### Show environment vars
###
log "info" "-------------------------------------------------------------------------"
log "info" "Environment Variables (set/default)"
log "info" "-------------------------------------------------------------------------"

log "info" "Variables: General:"
env_var_export "NEW_UID"
env_var_export "NEW_GID"
env_var_export "TIMEZONE" "UTC"

log "info" "Variables: Main Vhost:"
env_var_export "MAIN_VHOST_ENABLE" "1"
env_var_export "MAIN_VHOST_DOCROOT_DIR" "htdocs"
env_var_export "MAIN_VHOST_TEMPLATE_DIR" "cfg"
env_var_export "MAIN_VHOST_ALIASES_ALLOW" ""
env_var_export "MAIN_VHOST_ALIASES_DENY" '/\.git, /\.ht.*'
env_var_export "MAIN_VHOST_BACKEND"
env_var_export "MAIN_VHOST_BACKEND_TIMEOUT" "180"
env_var_export "MAIN_VHOST_SSL_TYPE" "plain"
env_var_export "MAIN_VHOST_SSL_CN" "localhost"
env_var_export "MAIN_VHOST_STATUS_ENABLE" "0"
env_var_export "MAIN_VHOST_STATUS_ALIAS" "/httpd-status"

log "info" "Variables: Mass Vhost:"
env_var_export "MASS_VHOST_ENABLE" "0"
env_var_export "MASS_VHOST_DOCROOT_DIR" "htdocs"
env_var_export "MASS_VHOST_TEMPLATE_DIR" "cfg"
env_var_export "MASS_VHOST_ALIASES_ALLOW" ""
env_var_export "MASS_VHOST_ALIASES_DENY" '/\.git, /\.ht.*'
env_var_export "MASS_VHOST_BACKEND"
env_var_export "MASS_VHOST_BACKEND_REWRITE"
env_var_export "MASS_VHOST_BACKEND_TIMEOUT" "180"
env_var_export "MASS_VHOST_SSL_TYPE" "plain"
env_var_export "MASS_VHOST_TLD_SUFFIX" ".loc"

log "info" "Variables: Misc:"
if [ "${VHOSTGEN_HTTPD_SERVER}" = "nginx" ]; then
	env_var_export "WORKER_CONNECTIONS" "1024"
	env_var_export "WORKER_PROCESSES" "auto"
fi
# Apache 2.2 does not have HTTP/2 support
if [ "${VHOSTGEN_HTTPD_SERVER}" != "apache22" ]; then
	env_var_export "HTTP2_ENABLE" "1"
else
	export HTTP2_ENABLE=0
fi
env_var_export "DOCKER_LOGS" "1"



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
env_var_validate "MAIN_VHOST_DOCROOT_DIR"
env_var_validate "MAIN_VHOST_TEMPLATE_DIR"
env_var_validate "MAIN_VHOST_ALIASES_ALLOW"
env_var_validate "MAIN_VHOST_ALIASES_DENY"
env_var_validate "MAIN_VHOST_BACKEND"
env_var_validate "MAIN_VHOST_BACKEND_TIMEOUT"
env_var_validate "MAIN_VHOST_SSL_TYPE"
env_var_validate "MAIN_VHOST_SSL_CN"
env_var_validate "MAIN_VHOST_STATUS_ENABLE"
env_var_validate "MAIN_VHOST_STATUS_ALIAS"

log "info" "Settings: Mass Vhost:"
env_var_validate "MASS_VHOST_ENABLE"
env_var_validate "MASS_VHOST_DOCROOT_DIR"
env_var_validate "MASS_VHOST_TEMPLATE_DIR"
env_var_validate "MASS_VHOST_ALIASES_ALLOW"
env_var_validate "MASS_VHOST_ALIASES_DENY"
env_var_validate "MASS_VHOST_BACKEND"
env_var_validate "MASS_VHOST_BACKEND_REWRITE"
env_var_validate "MASS_VHOST_BACKEND_TIMEOUT"
env_var_validate "MASS_VHOST_SSL_TYPE"
env_var_validate "MASS_VHOST_TLD_SUFFIX"

log "info" "Settings: Misc:"
if [ "${VHOSTGEN_HTTPD_SERVER}" = "nginx" ]; then
	env_var_validate "WORKER_CONNECTIONS"
	env_var_validate "WORKER_PROCESSES"
fi
# Apache 2.2 does not have HTTP/2 support
if [ "${VHOSTGEN_HTTPD_SERVER}" != "apache22" ]; then
	env_var_validate "HTTP2_ENABLE"
fi
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

###
### Copy custom user-mounted vhost-gen template (if they are mounted and exist)
###
vhostgen_copy_custom_template \
	"${VHOSTGEN_CUST_TEMPLATE_DIR}" \
	"${VHOSTGEN_TEMPLATE_DIR}" \
	"${VHOSTGEN_HTTPD_SERVER_TEMPLATE}"

###
### Generate vhost-gen config file (MAIN_VHOST)
###
vhostgen_main_generate_config \
	"${VHOSTGEN_HTTPD_SERVER}" \
	"${MAIN_VHOST_BACKEND}" \
	"${HTTP2_ENABLE}" \
	"${MAIN_VHOST_ALIASES_ALLOW}" \
	"${MAIN_VHOST_ALIASES_DENY}" \
	"${MAIN_VHOST_STATUS_ENABLE}" \
	"${MAIN_VHOST_STATUS_ALIAS}" \
	"${DOCKER_LOGS}" \
	"${MAIN_VHOST_BACKEND_TIMEOUT}" \
	"/etc/vhost-gen/main.yml"

###
### Generate vhost (MAIN_VHOST)
###
if [ "${VHOSTGEN_HTTPD_SERVER}" = "nginx" ]; then
	# Adding custom nginx vhost template to ensure paths like:
	# /vendor/index.php/arg1/arg2 will also work (just like Apache)
	# https://www.reddit.com/r/nginx/comments/a6pw31/phpfpm_does_not_handle_subpathindexphparg1arg2/
	vhostgen_main_generate \
		"${MAIN_VHOST_ENABLE}" \
		"${MAIN_DOCROOT_BASE}/${MAIN_VHOST_DOCROOT_DIR}" \
		"${MAIN_VHOST_BACKEND}" \
		"/etc/vhost-gen/main.yml" \
		"${MAIN_DOCROOT_BASE}/${MAIN_VHOST_TEMPLATE_DIR}" \
		"${MAIN_VHOST_SSL_TYPE}" \
		"/etc/vhost-gen/templates-main/"
else
	vhostgen_main_generate \
		"${MAIN_VHOST_ENABLE}" \
		"${MAIN_DOCROOT_BASE}/${MAIN_VHOST_DOCROOT_DIR}" \
		"${MAIN_VHOST_BACKEND}" \
		"/etc/vhost-gen/main.yml" \
		"${MAIN_DOCROOT_BASE}/${MAIN_VHOST_TEMPLATE_DIR}" \
		"${MAIN_VHOST_SSL_TYPE}"
fi

###
### Create Certificate Signing request
###
cert_gen_generate_ca "${CA_KEY_FILE}" "${CA_CRT_FILE}"

###
### Generate main vhost ssl certificate (MAIN_VHOST)
###
# shellcheck disable=SC2153
cert_gen_generate_cert \
	"${MAIN_VHOST_ENABLE}" \
	"${MAIN_VHOST_SSL_TYPE}" \
	"${CA_KEY_FILE}" \
	"${CA_CRT_FILE}" \
	"/etc/httpd/cert/main/localhost.key" \
	"/etc/httpd/cert/main/localhost.csr" \
	"/etc/httpd/cert/main/localhost.crt" \
	"${MAIN_VHOST_SSL_CN}"

###
### Fix CA directory/file permissions (in case it is mounted)
###
fix_perm "/ca" "1"



# -------------------------------------------------------------------------------------------------
# NGINX-SPECIFIC BASIC SETTINGS
# -------------------------------------------------------------------------------------------------

###
### Nginx settings
###
if [ "${VHOSTGEN_HTTPD_SERVER}" = "nginx" ]; then
	nginx_set_worker_processess "${WORKER_PROCESSES}"
	nginx_set_worker_connections "${WORKER_CONNECTIONS}"
fi



# -------------------------------------------------------------------------------------------------
# MAIN ENTRYPOINT
# -------------------------------------------------------------------------------------------------

# shellcheck disable=SC2153
_HTTPD_VERSION="$( eval "${HTTPD_VERSION}" || true )"  # Set via Dockerfile
_SUPVD_VERSION="$( supervisord -v )"

log "info" "-------------------------------------------------------------------------"
log "info" "Main Entrypoint"
log "info" "-------------------------------------------------------------------------"

###
### MASS_VHOST requires supervisor to run (watcherd)
###
if [ "${MASS_VHOST_ENABLE}" -eq "1" ]; then
	# Create watcherd sub commands
	watcherd_add="create-vhost.sh"
	watcherd_add+=" \\\"%%n\\\""  # vhost project directory name
	watcherd_add+=" \\\"%%p\\\""  # vhost project directory path (absolute)
	watcherd_add+=" \\\"${MASS_VHOST_DOCROOT_DIR}\\\""
	watcherd_add+=" \\\"${MASS_VHOST_TLD_SUFFIX}\\\""
	watcherd_add+=" \\\"${MASS_VHOST_ALIASES_ALLOW}\\\""
	watcherd_add+=" \\\"${MASS_VHOST_ALIASES_DENY}\\\""
	watcherd_add+=" \\\"${MASS_VHOST_SSL_TYPE}\\\""
	watcherd_add+=" \\\"${MASS_VHOST_BACKEND}\\\""
	watcherd_add+=" \\\"${MASS_VHOST_BACKEND_REWRITE}\\\""
	watcherd_add+=" \\\"${MASS_VHOST_BACKEND_TIMEOUT}\\\""
	watcherd_add+=" \\\"${HTTP2_ENABLE}\\\""
	watcherd_add+=" \\\"${DOCKER_LOGS}\\\""
	watcherd_add+=" \\\"${CA_KEY_FILE}\\\""
	watcherd_add+=" \\\"${CA_CRT_FILE}\\\""
	watcherd_add+=" \\\"%%p/${MASS_VHOST_TEMPLATE_DIR}/\\\""
	watcherd_add+=" \\\"${VHOSTGEN_HTTPD_SERVER}\\\""

	watcherd_del="rm /etc/httpd/vhost.d/%%n.conf"
	watcherd_tri="${HTTPD_RELOAD}"

	supervisord_create \
		"${HTTPD_START}" \
		"bash -c 'sleep ${WATCHERD_STARTUP_DELAY} && exec watcherd -c -v -p ${MASS_DOCROOT_BASE} -a \"${watcherd_add}\" -d \"${watcherd_del}\" -t \"${watcherd_tri}\"'" \
		"/etc/supervisord.conf"

	log "done" "Starting supervisord: ${_SUPVD_VERSION} [HTTPD: ${_HTTPD_VERSION}]"
	exec /usr/bin/supervisord -c /etc/supervisord.conf

###
### No MASS_VHOST: just start HTTPD as process 1.
###
else
	log "done" "Starting webserver: ${_HTTPD_VERSION}"
	exec "${HTTPD_START}"
fi
