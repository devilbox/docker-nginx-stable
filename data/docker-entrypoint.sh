#!/usr/bin/env bash

set -e
set -u
set -o pipefail



################################################################################
# VARIABLES
################################################################################

MY_USER="nginx"
MY_GROUP="nginx"
DEBUG_COMMANDS=0

###
### Defaults
###


################################################################################
# FUNCTIONS
################################################################################

run() {
	_cmd="${1}"
	_debug="0"

	_red="\033[0;31m"
	_green="\033[0;32m"
	_reset="\033[0m"
	_user="$(whoami)"


	# If 2nd argument is set and enabled, allow debug command
	if [ "${#}" = "2" ]; then
		_debug="${2}"
	fi

	if [ "${DEBUG_COMMANDS}" -gt "1" ] || [ "${_debug}" -gt "1" ]; then
		printf "${_red}%s \$ ${_green}${_cmd}${_reset}\n" "${_user}"
	fi
	sh -c "LANG=C LC_ALL=C ${_cmd}"
}

log() {
	_lvl="${1}"
	_msg="${2}"

	_clr_ok="\033[0;32m"
	_clr_info="\033[0;34m"
	_clr_warn="\033[0;33m"
	_clr_err="\033[0;31m"
	_clr_rst="\033[0m"

	if [ "${_lvl}" = "ok" ]; then
		printf "${_clr_ok}[OK]   %s${_clr_rst}\n" "${_msg}"
	elif [ "${_lvl}" = "info" ]; then
		printf "${_clr_info}[INFO] %s${_clr_rst}\n" "${_msg}"
	elif [ "${_lvl}" = "warn" ]; then
		printf "${_clr_warn}[WARN] %s${_clr_rst}\n" "${_msg}" 1>&2	# stdout -> stderr
	elif [ "${_lvl}" = "err" ]; then
		printf "${_clr_err}[ERR]  %s${_clr_rst}\n" "${_msg}" 1>&2	# stdout -> stderr
	else
		printf "${_clr_err}[???]  %s${_clr_rst}\n" "${_msg}" 1>&2	# stdout -> stderr
	fi
}

# Test if argument is an integer.
#
# @param  mixed
# @return integer	0: is int | 1: not an int
isint() {
	echo "${1}" | grep -Eq '^([0-9]|[1-9][0-9]*)$'
}



################################################################################
# SETTING INJECTABLES
################################################################################

###
### Debug Mode Entrypoint?
###
if set | grep '^DEBUG_ENTRYPOINT=' >/dev/null 2>&1; then
	if [ "${DEBUG_ENTRYPOINT}" = "1" ]; then
		DEBUG_COMMANDS=1
	elif [ "${DEBUG_ENTRYPOINT}" = "2" ]; then
		DEBUG_COMMANDS=2
	else
		log "err" "Wrong value for \$DEBUG_ENTRYPOINT: '${DEBUG_ENTRYPOINT}'"
		log "err" "Allowed values: 0, 1 and 2"
		exit 1
	fi
fi


###
### Debug Mode Runtime?
###
_RUNTIME_DEBUG_RUNTIME="0"
if set | grep '^DEBUG_RUNTIME=' >/dev/null 2>&1; then
	if [ "${DEBUG_RUNTIME}" = "1" ]; then
		_RUNTIME_DEBUG_RUNTIME="1"
	fi
fi


###
### Use docker logs?
###
_RUNTIME_DOCKER_LOGS="0"
if ! set | grep '^DOCKER_LOGS=' >/dev/null 2>&1; then
	log "info" "\$DOCKER_LOGS not set. Logging errors and access to log files inside container."
else
	if [ "${DOCKER_LOGS}" = "1" ]; then
		log "info" "\$DOCKER_LOGS enabled. Redirecting errors and access to Docker log (stderr and stdout)."
		_RUNTIME_DOCKER_LOGS="1"
	elif [ "${DOCKER_LOGS}" = "0" ]; then
		log "info" "\$DOCKER_LOGS explicitly disabled. Logging errors and access to log files inside container."
	else
		log "err" "Invalid value for \$DOCKER_LOGS: ${DOCKER_LOGS}"
		log "err" "Must be '1' (for On) or '0' (for Off)"
		exit 1
	fi
fi


###
### Timezone
###
if ! set | grep '^TIMEZONE=' >/dev/null 2>&1; then
	log "info" "\$TIMEZONE not set."
else
	if [ -f "/usr/share/zoneinfo/${TIMEZONE}" ]; then
		# Unix Time
		log "info" "Setting docker timezone to: ${TIMEZONE}"
		run "ln -sf /usr/share/zoneinfo/${TIMEZONE} /etc/localtime"
	else
		log "err" "Invalid timezone for \$TIMEZONE."
		log "err" "\$TIMEZONE: '${TIMEZONE}' does not exist."
		exit 1
	fi
fi
log "info" "Docker date set to: $(date)"


###
### Change UID
###
if ! set | grep '^NEW_UID=' >/dev/null 2>&1; then
	log "info" "\$NEW_UID not set. Keeping default uid of '${MY_USER}'."
else
	if ! isint "${NEW_UID}"; then
		log "err" "\$NEW_UID is not an integer: '${NEW_UID}'"
		exit 1
	else
		if _user_line="$( getent passwd "${NEW_UID}" )"; then
			_user_name="${_user_line%%:*}"
			if [ "${_user_name}" != "${MY_USER}" ]; then
				log "warn" "User with ${NEW_UID} already exists: ${_user_name}"
				log "info" "Changing UID of ${_user_name} to 9999"
				run "usermod -u 9999 ${_user_name}"
			fi
		fi
		log "info" "Changing user '${MY_USER}' uid to: ${NEW_UID}"
		run "usermod -u ${NEW_UID} ${MY_USER}"
	fi
fi


###
### Change GID
###
if ! set | grep '^NEW_GID=' >/dev/null 2>&1; then
	log "info" "\$NEW_GID not set. Keeping default gid of '${MY_GROUP}'."
else
	if ! isint "${NEW_GID}"; then
		log "err" "\$NEW_GID is not an integer: '${NEW_GID}'"
		exit 1
	else
		if _group_line="$( getent group "${NEW_GID}" )"; then
			_group_name="${_group_line%%:*}"
			if [ "${_group_name}" != "${MY_GROUP}" ]; then
				log "warn" "Group with ${NEW_GID} already exists: ${_group_name}"
				log "info" "Changing GID of ${_group_name} to 9999"
				run "groupmod -g 9999 ${_group_name}"
			fi
		fi
		log "info" "Changing group '${MY_GROUP}' gid to: ${NEW_GID}"
		run "groupmod -g ${NEW_GID} ${MY_GROUP}"
	fi
fi



################################################################################
# MAIN VHOST INJECTABLES
################################################################################

###
### Disable default vhost?
###
_RUNTIME_MAIN_VHOST_ENABLE=1
if ! set | grep '^MAIN_VHOST_DISABLE=' >/dev/null 2>&1; then
	log "info" "\$MAIN_VHOST_DISABLE not set. Not disabling the default vhost."
else
	if [ "${MAIN_VHOST_DISABLE}" -eq "0" ]; then
		log "info" "\$MAIN_VHOST_DISABLE set to 0. Not disabling the default vhost."
	elif [ "${MAIN_VHOST_DISABLE}" -eq "1" ]; then
		log "info" "\$MAIN_VHOST_DISABLE set to 1. Disabling the default vhost."
		_RUNTIME_MAIN_VHOST_ENABLE=0
	else
		log "err" "\$MAIN_VHOST_DISABLE is set to  ${MAIN_VHOST_DISABLE}, but must be 0 or 1."
		exit 1
	fi
fi


###
### Set main vhost document root sufix
###
_RUNTIME_MAIN_VHOST_DOCROOT="htdocs"
if ! set | grep '^MAIN_VHOST_DOCROOT=' >/dev/null 2>&1; then
	log "info" "\$MAIN_VHOST_DOCROOT not specified. Keeping default: ${_RUNTIME_MAIN_VHOST_DOCROOT}"
else
	log "info" "\$MAIN_VHOST_DOCROOT is set to: ${MAIN_VHOST_DOCROOT}"
	_RUNTIME_MAIN_VHOST_DOCROOT="${MAIN_VHOST_DOCROOT}"
fi


###
### Set main vhost template directory
###
_RUNTIME_MAIN_VHOST_TPL="cfg"
if ! set | grep '^MAIN_VHOST_TPL=' >/dev/null 2>&1; then
	log "info" "\$MAIN_VHOST_TPL not specified. Keeping default: ${_RUNTIME_MAIN_VHOST_TPL}"
else
	log "info" "\$MAIN_VHOST_TPL is set to: ${_RUNTIME_MAIN_VHOST_TPL}"
	_RUNTIME_MAIN_VHOST_TPL="${MAIN_VHOST_TPL}"
fi



################################################################################
# MASS VHOST INJECTABLES
################################################################################

###
### Enable mass vhosts?
###
_RUNTIME_MASS_VHOST_ENABLE=0
if ! set | grep '^MASS_VHOST_ENABLE=' >/dev/null 2>&1; then
	log "info" "\$MASS_VHOST_ENABLE not set. Disabbling mass vhosts."
else
	if [ "${MASS_VHOST_ENABLE}" -eq "0" ]; then
		log "info" "\$MASS_VHOST_ENABLE set to 0. Disabling mass vhosts."
	elif [ "${MASS_VHOST_ENABLE}" -eq "1" ]; then
		log "info" "\$MASS_VHOST_ENABLE set to 1. Enabling mass vhosts."
		_RUNTIME_MASS_VHOST_ENABLE=1
	else
		log "err" "\$MASS_VHOST_ENABLE is set to  ${MASS_VHOST_ENABLE}, but must be 0 or 1."
		exit 1
	fi
fi


###
### Set mass vhost TLD
###
_RUNTIME_MASS_VHOST_TLD=".local"
if ! set | grep '^MASS_VHOST_TLD=' >/dev/null 2>&1; then
	log "info" "\$MASS_VHOST_TLD not set. Keeping default: ${_RUNTIME_MASS_VHOST_TLD}"
else
	log "info" "\$MASS_VHOST_TLD set to: ${MASS_VHOST_TLD}"
	_RUNTIME_MASS_VHOST_TLD="${MASS_VHOST_TLD}"
fi


###
### Set mass vhost document root sufix
###
_RUNTIME_MASS_VHOST_DOCROOT="htdocs"
if ! set | grep '^MASS_VHOST_DOCROOT=' >/dev/null 2>&1; then
	log "info" "\$MASS_VHOST_DOCROOT not specified. Keeping default: ${_RUNTIME_MASS_VHOST_DOCROOT}"
else
	log "info" "\$MASS_VHOST_DOCROOT is set to: ${MASS_VHOST_DOCROOT}"
	_RUNTIME_MASS_VHOST_DOCROOT="${MASS_VHOST_DOCROOT}"
fi


###
### Set mass vhost template directory
###
_RUNTIME_MASS_VHOST_TPL="cfg"
if ! set | grep '^MASS_VHOST_TPL=' >/dev/null 2>&1; then
	log "info" "\$MASS_VHOST_TPL not specified. Keeping default: ${_RUNTIME_MASS_VHOST_TPL}"
else
	log "info" "\$MASS_VHOST_TPL is set to: ${_RUNTIME_MASS_VHOST_TPL}"
	_RUNTIME_MASS_VHOST_TPL="${MASS_VHOST_TPL}"
fi



################################################################################
# SHARED VHOST INJECTABLES (MAIN & MASS)
################################################################################

###
### Enable PHP-FPM
###
_RUNTIME_PHP_FPM_ENABLE=0
if ! set | grep '^PHP_FPM_ENABLE=' >/dev/null 2>&1; then
	log "info" "\$PHP_FPM_ENABLE not set. Not enabling PHP-FPM."
else
	if [ "${PHP_FPM_ENABLE}" -eq "0" ]; then
		log "info" "\$PHP_FPM_ENABLE set to 0. Not enabling PHP-FPM."
	elif [ "${PHP_FPM_ENABLE}" -eq "1" ]; then
		log "info" "\$PHP_FPM_ENABLE set to 1. Enabling PHP-FPM."
		_RUNTIME_PHP_FPM_ENABLE=1

		###
		### PHP-FPM Addres
		###
		# Check if PHP-FPM address is set
		if ! set | grep '^PHP_FPM_SERVER_ADDR=' >/dev/null 2>&1; then
			log "err" "PHP-FPM is enabled, but \$PHP_FPM_SERVER_ADDR not specified."
			exit 1
		fi
		# Check if PHP-FPM address is not empty
		if [ -z "${PHP_FPM_SERVER_ADDR}" ]; then
			log "err" "PHP-FPM enabled, but \$PHP_FPM_SERVER_ADDR is empty."
			exit 1
		fi
		log "info" "\$PHP_FPM_SERVER_ADDR is set to: ${PHP_FPM_SERVER_ADDR}"

	else
		log "err" "\$PHP_FPM_ENABLE is set to  ${PHP_FPM_ENABLE}, but must be 0 or 1."
		exit 1
	fi
fi


###
### PHP-FPM Port
###
_RUNTIME_PHP_FPM_SERVER_PORT="9000"
if ! set | grep '^PHP_FPM_SERVER_PORT=' >/dev/null 2>&1; then
	log "info" "\$PHP_FPM_SERVER_PORT not specified. Keeping default: ${_RUNTIME_PHP_FPM_SERVER_PORT}"
else
	# Check if PHP-FPM port is not empty
	if [ -z "${PHP_FPM_SERVER_PORT}" ]; then
		log "err" "\$PHP_FPM_SERVER_PORT specified, but is empty."
		exit 1
	fi
	# Check if PHP-FPM port is an integer
	if ! isint "${PHP_FPM_SERVER_PORT}"; then
		log "err" "\$PHP_FPM_SERVER_PORT is not a valid integer: ${PHP_FPM_SERVER_PORT}"
		exit 1
	fi
	# Check if PHP-FPM port is in port range
	if [ "${PHP_FPM_SERVER_PORT}" -lt 1 ] || [ "${PHP_FPM_SERVER_PORT}" -gt 65535 ] ; then
		log "err" "\$PHP_FPM_SERVER_PORT is not in a valid port range: ${PHP_FPM_SERVER_PORT}"
		exit 1
	fi
	log "info" "\$PHP_FPM_SERVER_PORT is set to: ${PHP_FPM_SERVER_PORT}"
	_RUNTIME_PHP_FPM_SERVER_PORT="${_RUNTIME_PHP_FPM_SERVER_PORT}"
fi



################################################################################
# SETUP CONFIGURATION
################################################################################

###
### Default and/or mass vhost must be enabled (at least one of them)
###
if [ "${_RUNTIME_MAIN_VHOST_ENABLE}" -eq "0" ] && [ "${_RUNTIME_MASS_VHOST_ENABLE}" -eq "0" ]; then
	log "err" "Default vhost and mass vhosts are disabled."
	exit 1
fi


###
### vhost-gen
###
if [ "${_RUNTIME_PHP_FPM_ENABLE}" -eq "1" ]; then
	run "sed -i'' 's/__PHP_ENABLE__/yes/g' /etc/vhost-gen/conf.yml"
	run "sed -i'' 's/__PHP_ENABLE__/yes/g' /etc/vhost-gen/main.yml"
	run "sed -i'' 's/__PHP_ADDR__/${PHP_FPM_SERVER_ADDR}/g' /etc/vhost-gen/conf.yml"
	run "sed -i'' 's/__PHP_ADDR__/${PHP_FPM_SERVER_ADDR}/g' /etc/vhost-gen/main.yml"
	run "sed -i'' 's/__PHP_PORT__/${_RUNTIME_PHP_FPM_SERVER_PORT}/g' /etc/vhost-gen/conf.yml"
	run "sed -i'' 's/__PHP_PORT__/${_RUNTIME_PHP_FPM_SERVER_PORT}/g' /etc/vhost-gen/main.yml"
else
	run "sed -i'' 's/__PHP_ENABLE__/no/g' /etc/vhost-gen/conf.yml"
	run "sed -i'' 's/__PHP_ENABLE__/no/g' /etc/vhost-gen/main.yml"
fi

if [ "${_RUNTIME_DOCKER_LOGS}" -eq "1" ]; then
	run "sed -i'' 's/__DOCKER_LOGS_ERROR__/yes/g' /etc/vhost-gen/conf.yml"
	run "sed -i'' 's/__DOCKER_LOGS_ERROR__/yes/g' /etc/vhost-gen/main.yml"
	run "sed -i'' 's/__DOCKER_LOGS_ACCESS__/yes/g' /etc/vhost-gen/conf.yml"
	run "sed -i'' 's/__DOCKER_LOGS_ACCESS__/yes/g' /etc/vhost-gen/main.yml"
else
	run "sed -i'' 's/__DOCKER_LOGS_ERROR__/no/g' /etc/vhost-gen/conf.yml"
	run "sed -i'' 's/__DOCKER_LOGS_ERROR__/no/g' /etc/vhost-gen/main.yml"
	run "sed -i'' 's/__DOCKER_LOGS_ACCESS__/no/g' /etc/vhost-gen/conf.yml"
	run "sed -i'' 's/__DOCKER_LOGS_ACCESS__/no/g' /etc/vhost-gen/main.yml"
fi


###
### Main vhost
###
if [ "${_RUNTIME_MAIN_VHOST_ENABLE}" -eq "1" ]; then
	if [ "${DEBUG_COMMANDS}" -gt "0" ]; then
		_verb="-v"
	else
		_verb=""
	fi
	run "vhost_gen.py -n _ -p /var/www/default/${_RUNTIME_MAIN_VHOST_DOCROOT} -c /etc/vhost-gen/main.yml -o /var/www/default/${_RUNTIME_MAIN_VHOST_TPL} ${_verb} -s"
fi


###
### Mass vhost (watcher config setup)
###
if [ "${_RUNTIME_MASS_VHOST_ENABLE}" -eq "1" ]; then
	run "sed -i'' 's/__DOCROOT_SUFFIX__/${_RUNTIME_MASS_VHOST_DOCROOT}/g' /etc/vhost-gen/conf.yml"
	run "sed -i'' 's/__TLD__/${_RUNTIME_MASS_VHOST_TLD}/g' /etc/vhost-gen/conf.yml"
fi



################################################################################
# RUN
################################################################################

###
### Supervisor or plain
###
if [ "${_RUNTIME_MASS_VHOST_ENABLE}" -eq "1" ]; then
	if [ "${_RUNTIME_DEBUG_RUNTIME}" -gt "0" ]; then
		_verb="-v"
	else
		_verb=""
	fi
	run "sed -i'' 's/__MASS_VHOST_TPL__/${_RUNTIME_MASS_VHOST_TPL}/g' /etc/supervisord.conf"
	run "sed -i'' 's/__VERBOSE__/${_verb}/g' /etc/supervisord.conf"
	exec /usr/bin/supervisord -c /etc/supervisord.conf
else
	exec /usr/sbin/nginx -g 'daemon off;'
fi
