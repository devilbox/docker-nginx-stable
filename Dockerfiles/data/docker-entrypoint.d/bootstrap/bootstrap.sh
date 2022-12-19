#!/usr/bin/env bash

set -e
set -u
set -o pipefail

###
### This is the bootstrap file - it must be called first.
###
### It will boostrap the entrypoint (or any other scripts which wants to use
### .http/ and .lib/ scripts.
###
###  1. Bootstrap debug level (set and export)
###  2. Source .lib/   (basic generic functions)
###  3. Source .httpd/ (basic httpd functions)
###


# -------------------------------------------------------------------------------------------------
# BOOTSTRAP DEBUG LEVEL
# -------------------------------------------------------------------------------------------------

###
### Default Debug Levels
###
DEFAULT_DEBUG_ENTRYPOINT="2"
DEFAULT_DEBUG_RUNTIME="1"


###
### DEBUG_ENTRYPOINT
###
# 1. Not set (gets default value)
if [ -z "${DEBUG_ENTRYPOINT:-}" ]; then
	DEBUG_ENTRYPOINT="${DEFAULT_DEBUG_ENTRYPOINT}"
fi
# 2. Not an integer (gets default value)
if [ -z "${DEBUG_ENTRYPOINT##*[!0-9]*}" ]; then
	DEBUG_ENTRYPOINT="${DEFAULT_DEBUG_ENTRYPOINT}"
fi
# 3. Not between 0 and 4 (gets highest value)
if [ "${DEBUG_ENTRYPOINT}" != "0" ] \
	&& [ "${DEBUG_ENTRYPOINT}" != "1" ] \
	&& [ "${DEBUG_ENTRYPOINT}" != "2" ] \
	&& [ "${DEBUG_ENTRYPOINT}" != "3" ] \
	&& [ "${DEBUG_ENTRYPOINT}" != "4" ]; then
	DEBUG_ENTRYPOINT=4
fi

###
### DEBUG_RUNTIME
###
# 1. Not set (gets default value)
if [ -z "${DEBUG_RUNTIME:-}" ]; then
	DEBUG_RUNTIME="${DEFAULT_DEBUG_RUNTIME}"
fi
# 2. Not an integer (gets default value)
if [ -z "${DEBUG_RUNTIME##*[!0-9]*}" ]; then
	DEBUG_RUNTIME="${DEFAULT_DEBUG_RUNTIME}"
fi
# 3. Not between 0 and 4 (gets highest value)
if [ "${DEBUG_RUNTIME}" != "0" ] \
	&& [ "${DEBUG_RUNTIME}" != "1" ] \
	&& [ "${DEBUG_RUNTIME}" != "2" ]; then
	DEBUG_RUNTIME=2
fi

###
### Export
###
export "DEBUG_ENTRYPOINT"
export "DEBUG_RUNTIME"



# -------------------------------------------------------------------------------------------------
# SOURCE LIBRARIES
# -------------------------------------------------------------------------------------------------

###
### Full path to this script
###
SCRIPTPATH="$( cd "$(dirname "${BASH_SOURCE[0]}")" && pwd )"

###
### Source available library functions
###
# shellcheck disable=SC2012
for f in $( ls -1 "${SCRIPTPATH}/../.lib/"*.sh | sort -u ); do
	# shellcheck disable=SC1090
	. "${f}"
done

###
### Source available HTTPD functions
###
# shellcheck disable=SC2012
for f in $( ls -1 "${SCRIPTPATH}/../.httpd/"*.sh | sort -u ); do
	# shellcheck disable=SC1090
	. "${f}"
done
