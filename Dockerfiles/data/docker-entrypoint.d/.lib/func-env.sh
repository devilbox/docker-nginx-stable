#!/usr/bin/env bash

set -e
set -u
set -o pipefail

###
### This file holds functions to set/get environment variables
###


# -------------------------------------------------------------------------------------------------
# ENV FUNCTIONS
# -------------------------------------------------------------------------------------------------

###
### Is env variable set?
###
env_set() {
	printenv "${1}" >/dev/null 2>&1
}


###
### Get env variable by name
###
### This function allows an optional second parameter, which sets
### the default value, if the environment variable was not set.
###
### ${1}: name of the environment variable
### ${2}: (optional) default value, if not set
###
env_get() {
	# Did we have a default value set?
	if [ "${#}" -gt "1" ]; then
		if ! env_set "${1}"; then
			echo "${2}"
			return 0
		fi
	fi
	# Just output the env value
	printenv "${1}"
}



# -------------------------------------------------------------------------------------------------
# SANITY CHECKS
# -------------------------------------------------------------------------------------------------

###
### The following commands are required and used in the current script.
###
if ! command -v printenv >/dev/null 2>&1; then
	>&2 echo "Error, printenv not found, but required."
	exit 1
fi
