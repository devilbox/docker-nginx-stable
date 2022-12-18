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
