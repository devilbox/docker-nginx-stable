#!/usr/bin/env bash

set -e
set -u
set -o pipefail

###
### This file holds misc functions.
###


# -------------------------------------------------------------------------------------------------
# ENV FUNCTIONS
# -------------------------------------------------------------------------------------------------

###
### Cast a bash bool ("0" or "1") to Python bool ("yes" or "no")
###
to_python_bool() {
	if [ "${1}" = "0" ]; then
		echo "no"
	elif [ "${1}" = "1" ]; then
		echo "yes"
	fi
}


###
### Get Random alphanumeric string
###
get_random_alphanum() {
	local len="${1:-15}"  # length defaults to 15
	tr -dc A-Za-z0-9 < /dev/urandom | head -c "${len}" | xargs || true
}



# -------------------------------------------------------------------------------------------------
# SANITY CHECKS
# -------------------------------------------------------------------------------------------------

###
### The following commands are required and used in the current script.
###
if ! command -v tr >/dev/null 2>&1; then
	>&2 echo "Error, tr not found, but required."
	exit 1
fi
if ! command -v xargs >/dev/null 2>&1; then
	>&2 echo "Error, xargs not found, but required."
	exit 1
fi
