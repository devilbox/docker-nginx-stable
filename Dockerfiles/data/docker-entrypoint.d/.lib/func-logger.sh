#!/usr/bin/env bash

set -e
set -u
set -o pipefail

###
### This file holds the global logger function.
###


# -------------------------------------------------------------------------------------------------
# LOGGER
# -------------------------------------------------------------------------------------------------

###
### Log to stdout/stderr
###
### Internally used logger function to log 'ok', 'warn' and 'err' messages to stdout/stderr.
###
### DEBUG_ENTRYPOINT=0 done, err
### DEBUG_ENTRYPOINT=1 done, err, warn
### DEBUG_ENTRYPOINT=2 done, err, warn, ok, info
### DEBUG_ENTRYPOINT=3 done, err, warn, ok, info, debug
### DEBUG_ENTRYPOINT=4 done, err, warn, ok, info, debug, trace
###
log() {
	local type="${1}"
	local message="${2}"
	local disable_format="${3:-0}"    # disable colors and prefix

	# https://unix.stackexchange.com/questions/124407/what-color-codes-can-i-use-in-my-bash-ps1-prompt
	local clr_trace="\033[38;5;244m"  # gray
	local clr_debug="\033[38;5;244m"  # gray
	local clr_info="\033[0;34m"       # blue
	local clr_ok="\033[0;32m"         # green
	local clr_warn="\033[0;33m"       # yellow
	local clr_err="\033[0;31m"        # red
	local clr_rst="\033[0m"           # reset color

	# Always show ready messages
	if [ "${type}" = "done" ]; then
		if [ "${disable_format}" = "1" ]; then
			echo "${message}" 1>&1 # stdout -> stderr
		else
			printf "${clr_ok}[DONE] %s${clr_rst}\n" "${message}" 1>&2	# stdout -> stderr
		fi
	fi

	# Always show errors
	if [ "${type}" = "err" ]; then
		if [ "${disable_format}" = "1" ]; then
			echo "${message}" 1>&1 # stdout -> stderr
		else
			printf "${clr_err}[ERR]  %s${clr_rst}\n" "${message}" 1>&2	# stdout -> stderr
		fi
	fi

	# >= 1 (Errors & Warnings)
	if [ "${DEBUG_ENTRYPOINT}" -ge "1" ]; then
		if [ "${type}" = "warn" ]; then
			if [ "${disable_format}" = "1" ]; then
				echo "${message}" 1>&1 # stdout -> stderr
			else
				printf "${clr_warn}[WARN] %s${clr_rst}\n" "${message}" 1>&2	# stdout -> stderr
			fi
		fi
	fi
	# >= 2 (Errors, Warnings, OK & Info)
	if [ "${DEBUG_ENTRYPOINT}" -ge "2" ]; then
		if [ "${type}" = "ok" ]; then
			if [ "${disable_format}" = "1" ]; then
				echo "${message}"
			else
				printf "${clr_ok}[OK]   %s${clr_rst}\n" "${message}"
			fi
		fi
		if [ "${type}" = "info" ]; then
			if [ "${disable_format}" = "1" ]; then
				echo "${message}"
			else
				printf "${clr_info}[INFO] %s${clr_rst}\n" "${message}"
			fi
		fi
	fi
	# >= 3 (Errors, Warnings, OK, Info, Debug)
	if [ "${DEBUG_ENTRYPOINT}" -ge "3" ]; then
		if [ "${type}" = "debug" ]; then
			if [ "${disable_format}" = "1" ]; then
				echo "${message}"
			else
				printf "${clr_debug}[DBG]  %s${clr_rst}\n" "${message}"
			fi
		fi
	fi
	# >= 4 (Errors, Warnings, OK, Info, Debug, Trace)
	if [ "${DEBUG_ENTRYPOINT}" -ge "4" ]; then
		if [ "${type}" = "trace" ]; then
			if [ "${disable_format}" = "1" ]; then
				echo "${message}"
			else
				printf "${clr_trace}[TRC]  %s${clr_rst}\n" "${message}"
			fi
		fi
	fi
}
