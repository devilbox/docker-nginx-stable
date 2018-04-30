#!/usr/bin/env bash

set -e
set -u
set -o pipefail

###
### Globals
###

MY_USER=nginx
MY_GROUP=nginx

# OpenSSL Certificate Authority file to generate
CA_KEY=/ca/devilbox-ca.key
CA_CRT=/ca/devilbox-ca.crt


# Path to scripts to source
CONFIG_DIR="/docker-entrypoint.d"


###
### Source libs
###
init="$( find "${CONFIG_DIR}" -name '*.sh' -type f | sort -u )"
for f in ${init}; do
	# shellcheck disable=SC1090
	. "${f}"
done



#############################################################
## Entry Point
#############################################################

###
### Set Debug level
###
DEBUG_LEVEL="$( env_get "DEBUG_ENTRYPOINT" "0" )"
log "info" "Debug level: ${DEBUG_LEVEL}" "${DEBUG_LEVEL}"

DEBUG_RUNTIME="$( env_get "DEBUG_RUNTIME" "0" )"
log "info" "Runtime debug: ${DEBUG_RUNTIME}" "${DEBUG_LEVEL}"


###
### Change uid/gid
###
set_uid "NEW_UID" "${MY_USER}"  "${DEBUG_LEVEL}"
set_gid "NEW_GID" "${MY_GROUP}" "${DEBUG_LEVEL}"


###
### Set timezone
###
set_timezone "TIMEZONE" "${DEBUG_LEVEL}"


###
### Ensure the following env variables are set and exported
###

# Docker Logs
export_docker_logs "DOCKER_LOGS" "${DEBUG_LEVEL}"

# PHP-FPM
export_php_fpm_enable "PHP_FPM_ENABLE" "${DEBUG_LEVEL}"
export_php_fpm_server_addr "PHP_FPM_SERVER_ADDR" "${DEBUG_LEVEL}"
export_php_fpm_server_port "PHP_FPM_SERVER_PORT" "${DEBUG_LEVEL}"

# Main vhost
export_main_vhost_enable "MAIN_VHOST_ENABLE" "${DEBUG_LEVEL}"
export_main_vhost_ssl_type "MAIN_VHOST_SSL_TYPE" "${DEBUG_LEVEL}"
export_main_vhost_ssl_gen "MAIN_VHOST_SSL_GEN" "${DEBUG_LEVEL}"
export_main_vhost_docroot "MAIN_VHOST_DOCROOT" "${DEBUG_LEVEL}"
export_main_vhost_tpl "MAIN_VHOST_TPL" "${DEBUG_LEVEL}"
export_main_vhost_status_enable "MAIN_VHOST_STATUS_ENABLE" "${DEBUG_LEVEL}"
export_main_vhost_status_alias "MAIN_VHOST_STATUS_ALIAS" "${DEBUG_LEVEL}"

# Mass vhost
export_mass_vhost_enable "MASS_VHOST_ENABLE" "${DEBUG_LEVEL}"
export_mass_vhost_ssl_type "MASS_VHOST_SSL_TYPE" "${DEBUG_LEVEL}"
export_mass_vhost_ssl_gen "MASS_VHOST_SSL_GEN" "${DEBUG_LEVEL}"
export_mass_vhost_tld "MASS_VHOST_TLD" "${DEBUG_LEVEL}"
export_mass_vhost_docroot "MASS_VHOST_DOCROOT" "${DEBUG_LEVEL}"
export_mass_vhost_tpl "MASS_VHOST_TPL" "${DEBUG_LEVEL}"



################################################################################
# SETUP CONFIGURATION
################################################################################

###
### Create Certificate Signing request
###
if [ ! -f "${CA_KEY}" ] || [ ! -f "${CA_CRT}" ]; then
	run "openssl genrsa -out ${CA_KEY} 2048" "${DEBUG_LEVEL}"
	run "openssl req -new -x509 -days 3650 -key ${CA_KEY} -subj '/C=DE/ST=Berlin/L=Berlin/O=Devilbox/OU=Devilbox/CN=Devilbox Root CA' -extensions v3_ca -out ${CA_CRT}" "${DEBUG_LEVEL}"
fi


###
### Default and/or mass vhost must be enabled (at least one of them)
###
if [ "${MAIN_VHOST_ENABLE}" -eq "0" ] && [ "${MASS_VHOST_ENABLE}" -eq "0" ]; then
	log "err" "Default vhost and mass vhosts are disabled." "${DEBUG_LEVEL}"
	exit 1
fi


###
### vhost-gen
###
if [ "${PHP_FPM_ENABLE}" -eq "1" ]; then
	run "sed -i'' 's/__PHP_ENABLE__/yes/g' /etc/vhost-gen/mass.yml" "${DEBUG_LEVEL}"
	run "sed -i'' 's/__PHP_ENABLE__/yes/g' /etc/vhost-gen/main.yml" "${DEBUG_LEVEL}"
	run "sed -i'' 's/__PHP_ADDR__/${PHP_FPM_SERVER_ADDR}/g' /etc/vhost-gen/mass.yml" "${DEBUG_LEVEL}"
	run "sed -i'' 's/__PHP_ADDR__/${PHP_FPM_SERVER_ADDR}/g' /etc/vhost-gen/main.yml" "${DEBUG_LEVEL}"
	run "sed -i'' 's/__PHP_PORT__/${PHP_FPM_SERVER_PORT}/g' /etc/vhost-gen/mass.yml" "${DEBUG_LEVEL}"
	run "sed -i'' 's/__PHP_PORT__/${PHP_FPM_SERVER_PORT}/g' /etc/vhost-gen/main.yml" "${DEBUG_LEVEL}"
else
	run "sed -i'' 's/__PHP_ENABLE__/no/g' /etc/vhost-gen/mass.yml" "${DEBUG_LEVEL}"
	run "sed -i'' 's/__PHP_ENABLE__/no/g' /etc/vhost-gen/main.yml" "${DEBUG_LEVEL}"
fi

if [ "${DOCKER_LOGS}" -eq "1" ]; then
	run "sed -i'' 's/__DOCKER_LOGS_ERROR__/yes/g' /etc/vhost-gen/mass.yml" "${DEBUG_LEVEL}"
	run "sed -i'' 's/__DOCKER_LOGS_ERROR__/yes/g' /etc/vhost-gen/main.yml" "${DEBUG_LEVEL}"
	run "sed -i'' 's/__DOCKER_LOGS_ACCESS__/yes/g' /etc/vhost-gen/mass.yml" "${DEBUG_LEVEL}"
	run "sed -i'' 's/__DOCKER_LOGS_ACCESS__/yes/g' /etc/vhost-gen/main.yml" "${DEBUG_LEVEL}"
else
	run "sed -i'' 's/__DOCKER_LOGS_ERROR__/no/g' /etc/vhost-gen/mass.yml" "${DEBUG_LEVEL}"
	run "sed -i'' 's/__DOCKER_LOGS_ERROR__/no/g' /etc/vhost-gen/main.yml" "${DEBUG_LEVEL}"
	run "sed -i'' 's/__DOCKER_LOGS_ACCESS__/no/g' /etc/vhost-gen/mass.yml" "${DEBUG_LEVEL}"
	run "sed -i'' 's/__DOCKER_LOGS_ACCESS__/no/g' /etc/vhost-gen/main.yml" "${DEBUG_LEVEL}"
fi


###
### Main vhost
###
if [ "${MAIN_VHOST_ENABLE}" -eq "1" ]; then

	# Enable status page?
	if [ "${MAIN_VHOST_STATUS_ENABLE}" -eq "1" ]; then
		run "sed -i'' 's/__ENABLE_STATUS__/yes/g' /etc/vhost-gen/main.yml" "${DEBUG_LEVEL}"
		run "sed -i'' 's|__STATUS_ALIAS__|${MAIN_VHOST_STATUS_ALIAS}|g' /etc/vhost-gen/main.yml" "${DEBUG_LEVEL}"
	else
		run "sed -i'' 's/__ENABLE_STATUS__/no/g' /etc/vhost-gen/main.yml" "${DEBUG_LEVEL}"
	fi

	# Debug creation?
	if [ "${DEBUG_RUNTIME}" -gt "0" ]; then
		_verb="-v"
	else
		_verb=""
	fi
	if [ "${MAIN_VHOST_SSL_GEN}" = "1" ]; then
		if [ ! -d "/etc/httpd/cert/main" ]; then
			run "mkdir -p /etc/httpd/cert/main" "${DEBUG_LEVEL}"
		fi
		# Allow:
		#  + localhost
		#  + devilbox
		#  + devilbox.TLD
		run "create-cert.sh '/etc/httpd/cert/main' 'localhost' '${CA_KEY}' '${CA_CRT}' '${DEBUG_RUNTIME}' 'devilbox' 'devilbox${MASS_VHOST_TLD}'" "${DEBUG_LEVEL}"
	fi
	run "vhost_gen.py -n localhost -p /var/www/default/${MAIN_VHOST_DOCROOT} -c /etc/vhost-gen/main.yml -o /var/www/default/${MAIN_VHOST_TPL} ${_verb} -d -s -m ${MAIN_VHOST_SSL_TYPE}" "${DEBUG_LEVEL}"
fi


###
### Mass vhost (watcher config setup)
###
if [ "${MASS_VHOST_ENABLE}" -eq "1" ]; then
	run "sed -i'' 's|__DOCROOT_SUFFIX__|${MASS_VHOST_DOCROOT}|g' /etc/vhost-gen/mass.yml" "${DEBUG_LEVEL}"
	run "sed -i'' 's/__TLD__/${MASS_VHOST_TLD}/g' /etc/vhost-gen/mass.yml" "${DEBUG_LEVEL}"
fi



################################################################################
# RUN
################################################################################

###
### Supervisor or plain
###
if [ "${MASS_VHOST_ENABLE}" -eq "1" ]; then
	if [ "${DEBUG_RUNTIME}" -gt "0" ]; then
		_verb="-v"
	else
		_verb=""
	fi
	if [ ! -d "/etc/httpd/cert/mass" ]; then
		run "mkdir -p /etc/httpd/cert/mass" "${DEBUG_LEVEL}"
	fi
	run "sed -i'' 's|__MASS_VHOST_TPL__|${MASS_VHOST_TPL}|g' /etc/supervisord.conf" "${DEBUG_LEVEL}"
	run "sed -i'' 's|__VERBOSE__|${_verb}|g'                 /etc/supervisord.conf" "${DEBUG_LEVEL}"
	run "sed -i'' 's|__TLD__|${MASS_VHOST_TLD}|g'            /etc/supervisord.conf" "${DEBUG_LEVEL}"
	run "sed -i'' 's|__CA_KEY__|${CA_KEY}|g'                 /etc/supervisord.conf" "${DEBUG_LEVEL}"
	run "sed -i'' 's|__CA_CRT__|${CA_CRT}|g'                 /etc/supervisord.conf" "${DEBUG_LEVEL}"
	log "info" "Starting supervisord: $(supervisord -v)" "${DEBUG_LEVEL}"
	exec /usr/bin/supervisord -c /etc/supervisord.conf
else
	log "info" "Starting Nginx: $(nginx -v 2>&1 | awk '{print $3}')" "${DEBUG_LEVEL}"
	exec /usr/sbin/nginx -g 'daemon off;'
fi
