#!/usr/bin/env bash

set -e
set -u
set -o pipefail

###
### This file holds functions to ensures all environment variables are set or defaulted
###


# -------------------------------------------------------------------------------------------------
# EXPORT FUNCTIONS
# -------------------------------------------------------------------------------------------------

###
### Ensure that env variables are exported.
###
### In case an environment variable was not specified, assign
### a default value and export it to the environment.
###
env_var_export() {
	local env_varname="${1}"
	local default="${2:-}"

	if ! env_set "${env_varname}"; then
		_log_env_export "unset" "${env_varname}" "${default}"
	else
		default="$( env_get "${env_varname}" )"
		_log_env_export "set" "${env_varname}" "${default}"
	fi
	export "${env_varname}=${default}"
}



# -------------------------------------------------------------------------------------------------
# HELPER FUNCTIONS
# -------------------------------------------------------------------------------------------------

###
### Use custom logger to log env variable status
###
_log_env_export() {
	local state="${1}"    # 'set' or 'unset'
	local name="${2}"     # Variable name
	local value="${3}"    # Variable value (either set value or default value)

	local clr_set="\033[0;32m"   # green
	#local clr_unset="\033[0;34m" # blue
	local clr_value="\033[0;32m" # green
	local clr_info="\033[0;34m"  # blue
	local clr_rst="\033[0m"

	if [ "${state}" = "set" ]; then
		log "info" "$( \
			printf "${clr_info}%-11s${clr_rst}%-8s${clr_set}\$%-27s${clr_rst}%-9s${clr_value}%s${clr_rst}\n" \
				"[INFO]" \
				"Set" \
				"${name}" \
				"Value:" \
				"${value}" \
		)" "1"
	elif [ "${state}" = "unset" ]; then
		log "info" "$( \
			printf "${clr_info}%-11s${clr_rst}%-8s${clr_rst}\$%-27s${clr_rst}%-9s${clr_value}%s${clr_rst}\n" \
				"[INFO]" \
				"Unset" \
				"${name}" \
				"Default:" \
				"${value}" \
		)" "1"
	else
		log "????" "Internal: Wrong value given to _log_env_export"
		exit 1
	fi
}
