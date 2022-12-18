#!/usr/bin/env bash

set -e
set -u
set -o pipefail

###
### This file holds useful validator functions
###


# -------------------------------------------------------------------------------------------------
# HELPER FUNCTIONS
# -------------------------------------------------------------------------------------------------

###
### Check if given value is a positive integer
###
is_int() {
	if [ -z "${1}" ]; then
		return 1
	fi
	test -n "${1##*[!0-9]*}"
}


###
### Check if given value is a bool ('0' or '1')
###
is_bool() {
	if [ "${1}" != "0" ] && [ "${1}" != "1" ]; then
		return 1
	fi
}


###
### Check if given value is valid uid
###
is_uid() {
	is_int "${1}"
}


###
### Check if given value is valid gid
###
is_gid() {
	is_int "${1}"
}


###
### Check if given value is a valid port (1-65535)
###
is_port() {
	if ! is_int "${1}"; then
		return 1
	fi
	if [ "${1}" -lt "1" ]; then
		return 1
	fi
	if [ "${1}" -gt "65535" ]; then
		return 1
	fi
}


###
### Check if given string is a valid domain
###
is_domain() {
	# Cannot be empty
	if [ -z "${1}" ]; then
		return 1
	fi
	# Leading . (dot)
	if echo "${1}" | grep -E '^\.' > /dev/null; then
		return 1
	fi
	# Trailing . (dot)
	if echo "${1}" | grep -E '\.$' > /dev/null; then
		return 1
	fi
	# Space
	if echo "${1}" | grep -E '\s' > /dev/null; then
		return 1
	fi
	# Some common-sense characters
	if echo "${1}" | grep -E '&|@|\*|\(|\)|,|\?|_|#|\$|:|;|\\|/|%|\+|=|a<|>' > /dev/null; then
		return 1
	fi
}


###
### Check if given value is valid hostname
###
is_hostname() {
	# Cannot be empty
	if [ -z "${1}" ]; then
		return 1
	fi
	# TODO: Add some hostname regex
	return 0
}


###
### Check if given value is valid IPv4 or IPv6 address
###
is_ip_addr() {
	if is_ipv4_addr "${1}"; then
		return 0
	fi
	if is_ipv6_addr "${1}"; then
		return 0
	fi
	return 1
}


###
### Check if given value is valid IPv4 address
###
is_ipv4_addr() {
	# Cannot be empty
	if [ -z "${1}" ]; then
		return 1
	fi

	# This is only a very basic check to prevent typos during startup
	echo "${1}" | grep -E '^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$' >/dev/null
}


###
### Check if given value is valid IPv6 address
###
is_ipv6_addr() {
	# Cannot be empty
	if [ -z "${1}" ]; then
		return 1
	fi
	# This is only a very basic check to prevent typos during startup
	echo "${1}" | grep -E '^([A-Fa-f0-9:]+:+)+[A-Fa-f0-9]+$' >/dev/null
}


###
### Check if given value is a valid filename (no sub-/parent dir)
###
is_file() {
	# Cannot be empty
	if [ -z "${1}" ]; then
		return 1
	fi

	# Not a sub-directory prefix
	if [ "$( basename "${1}" )" != "${1}" ]; then
		return 1
	fi

	# Not a parent directory suffix
	if [ "$( dirname "${1}" )" != "." ]; then
		return 1
	fi
}
