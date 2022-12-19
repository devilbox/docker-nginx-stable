#!/usr/bin/env bash

set -e
set -u
set -o pipefail

###
### This file holds the global run function to wrap all executed commands.
###


# -------------------------------------------------------------------------------------------------
# RUN
# -------------------------------------------------------------------------------------------------

###
### Wrapper to run simple commands.
###
### Internally used function to execute commands and also be able to show
### these commands to stdout/stderr prior executing.
###
### DEBUG_ENTRYPOINT=0 -
### DEBUG_ENTRYPOINT=1 -
### DEBUG_ENTRYPOINT=2 show output
### DEBUG_ENTRYPOINT=3 show output and its command
### DEBUG_ENTRYPOINT=4 show output and its command
###
run() {
	local cmd="${1}"
	local fail_msg="${2:-}"

	# https://unix.stackexchange.com/questions/124407/what-color-codes-can-i-use-in-my-bash-ps1-prompt
	local clr_gray="\033[38;5;240m"
	local crl_cmd="\033[38;5;236m"   # dark gray
	#local clr_blue="\033[0;34m"
	#local clr_green="\033[0;32m"
	#local clr_yellow="\033[0;33m"
	local clr_red="\033[0;31m"
	local clr_rst="\033[0m"

	###
	### Failure
	###
	if ! OUTPUT="$( /bin/sh -c "LANG=C LC_ALL=C ${cmd}" 2>&1 )"; then
		if [ -n "${fail_msg}" ]; then
			printf "${clr_red}[FAIL] %s${clr_rst}\n" "${fail_msg}" 1>&2	# (opt) msg: stdout -> stderr
		fi
		printf "${clr_red}[FAIL] %s${clr_rst}\n" "${cmd}" 1>&2	        # command:   stdout -> stderr
		if [ -n "${OUTPUT}" ]; then
			printf "${clr_red}%s${clr_rst}\n" "${OUTPUT}" 1>&2	# output:    stdout -> stderr
		fi
		return 1
	fi

	###
	### Success
	###
	if [ "${DEBUG_ENTRYPOINT}" -gt "2" ]; then
		printf "${crl_cmd}[CMD]  %s${clr_rst}\n" "${cmd}"
		if [ -n "${OUTPUT}" ]; then
			printf "${clr_gray}%s${clr_rst}\n" "${OUTPUT}"
		fi
	elif [ "${DEBUG_ENTRYPOINT}" -gt "1" ]; then
		if [ -n "${OUTPUT}" ]; then
			printf "${clr_gray}%s${clr_rst}\n" "${OUTPUT}"
		fi
	fi
}


###
### Wrapper to run commands during runtime.
### This includes all commands triggered once the main entrypoint service is running.
###
### Internally used function to execute commands and also be able to show
### these commands to stdout/stderr prior executing.
###
### DEBUG_RUNTIME=0 -
### DEBUG_RUNTIME=1 show output
### DEBUG_RUNTIME=2 show output and its command
###
runtime() {
	local cmd="${1}"
	local fail_msg="${2:-}"

	# https://unix.stackexchange.com/questions/124407/what-color-codes-can-i-use-in-my-bash-ps1-prompt
	local clr_gray="\033[38;5;240m"
	local crl_cmd="\033[38;5;236m"   # dark gray
	#local clr_blue="\033[0;34m"
	#local clr_green="\033[0;32m"
	#local clr_yellow="\033[0;33m"
	local clr_red="\033[0;31m"
	local clr_rst="\033[0m"

	###
	### Failure
	###
	if ! OUTPUT="$( /bin/sh -c "LANG=C LC_ALL=C ${cmd}" 2>&1 )"; then
		if [ -n "${fail_msg}" ]; then
			printf "${clr_red}[FAIL] %s${clr_rst}\n" "${fail_msg}" 1>&2	# (opt) msg: stdout -> stderr
		fi
		printf "${clr_red}[FAIL] %s${clr_rst}\n" "${cmd}" 1>&2	        # command:   stdout -> stderr
		if [ -n "${OUTPUT}" ]; then
			printf "${clr_red}%s${clr_rst}\n" "${OUTPUT}" 1>&2	# output:    stdout -> stderr
		fi
		return 1
	fi

	###
	### Success
	###
	if [ "${DEBUG_RUNTIME}" -gt "1" ]; then
		printf "${crl_cmd}[CMD]  %s${clr_rst}\n" "${cmd}"
		if [ -n "${OUTPUT}" ]; then
			printf "${clr_gray}%s${clr_rst}\n" "${OUTPUT}"
		fi
	elif [ "${DEBUG_RUNTIME}" -gt "0" ]; then
		if [ -n "${OUTPUT}" ]; then
			printf "${clr_gray}%s${clr_rst}\n" "${OUTPUT}"
		fi
	fi
}
