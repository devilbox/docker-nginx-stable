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
### Wrapper for run_run command
###
### Internally used function to execute commands and also be able to show
### these commands to stdout/stderr prior executing.
###
### DEBUG_ENTRYPOINT=0 -
### DEBUG_ENTRYPOINT=1 -
### DEBUG_ENTRYPOINT=2 -
### DEBUG_ENTRYPOINT=3 show command
### DEBUG_ENTRYPOINT=4 show command and output
###
run() {
	local cmd="${1}"

	# Show commands in debug level
	log "debug" "$(whoami)> ${cmd}"

	# Show outputs on failure
	if ! STDOUT="$( /bin/sh -c "LANG=C LC_ALL=C ${cmd}" )"; then
		if [ -n "${STDOUT}" ]; then
			log "err" "${STDOUT}"
		fi
		exit 1
	fi
	# Show command outputs in trace level
	if [ -n "${STDOUT}" ]; then
		log "trace" "${STDOUT}"
	fi
}


# -------------------------------------------------------------------------------------------------
# SANITY CHECKS
# -------------------------------------------------------------------------------------------------

###
### The following commands are required and used in the current script.
###
if ! command -v whoami >/dev/null 2>&1; then
	>&2 "Error, whoami not found, but required."
	exit 1
fi
