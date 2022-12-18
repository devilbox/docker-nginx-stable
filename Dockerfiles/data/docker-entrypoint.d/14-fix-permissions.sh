#!/usr/bin/env bash

set -e
set -u
set -o pipefail


############################################################
# Functions
############################################################


###
### Fix permissions for MY_USER:MY_GROUP
###
fix_perm() {
	local directory="${1}"
	local recursive="${2}"

	# These are set in the Dockerfile
	local perm="${MY_USER}:${MY_GROUP}"

	if [ "${recursive}" = "1" ]; then
		run "chown -R ${perm} ${directory}"
	else
		run "chown ${perm} ${directory}"
	fi
}
