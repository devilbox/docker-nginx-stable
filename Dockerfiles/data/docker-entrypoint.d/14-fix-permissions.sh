#!/usr/bin/env bash

set -e
set -u
set -o pipefail

###
### This file holds functions to work on file system permissions
###


# -------------------------------------------------------------------------------------------------
# ACTION FUNCTIONS
# -------------------------------------------------------------------------------------------------

###
### Fix permissions for MY_USER:MY_GROUP
###
fix_perm() {
	local directory="${1}"
	local recursive="${2}"

	uid="$( id -u "${MY_USER}" )"
	gid="$( id -g "${MY_USER}" )"

	# These are set in the Dockerfile
	local perm="${uid}:${gid}"

	if [ "${recursive}" = "1" ]; then
		log "info" "Fixing ownership (recursively) in: ${directory}"
		run "chown -R ${perm} ${directory}"
	else
		log "info" "Fixing ownership in: ${directory}"
		run "chown ${perm} ${directory}"
	fi
}


# -------------------------------------------------------------------------------------------------
# SANITY CHECKS
# -------------------------------------------------------------------------------------------------

###
### The following commands are required and used in the current script.
###
if ! command -v id >/dev/null 2>&1; then
	log "err" "id not found, but required."
	exit 1
fi
