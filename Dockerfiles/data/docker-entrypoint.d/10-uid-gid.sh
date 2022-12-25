#!/usr/bin/env bash

set -e
set -u
set -o pipefail

###
### This file holds functions to change user id/gid
###


# -------------------------------------------------------------------------------------------------
# [SET] FUNCTIONS
# -------------------------------------------------------------------------------------------------

###
### Change UID
###
set_uid() {
	local uid="${1}"
	local username="${2}"
	local spare_uid=9876	# spare uid to change another user to

	# If uid is empty, end this function
	if [ -z "${uid}" ]; then
		return
	fi

	# Check if username with given uid already exists
	if target_username="$( _get_username_by_uid "${uid}" )"; then
		# It is not our user, so we need to changes his/her uid to something else first
		if [ "${target_username}" != "${username}" ]; then
			log "info" "User with ${uid} already exists: ${target_username}"
			log "info" "Changing UID of ${target_username} to ${spare_uid}"
			run "usermod -u ${spare_uid} ${target_username}"
		fi
	fi
	log "info" "Setting uid to ${uid} (user: ${username})"
	run "usermod -u ${uid} ${username}"
	run "id ${username}"
}


###
### Change GID
###
set_gid() {
	local gid="${1}"
	local username="${2}"
	local groupname="${3}"

	local spare_gid=9876	# spare gid to change another group to

	# If gid is empty, end this function
	if [ -z "${gid}" ]; then
		return
	fi

	# Groupname with this gid already exists
	if target_groupname="$( _get_groupname_by_gid "${gid}" )"; then
		# It is not our group, so we need to changes his/her gid to something else first
		if [ "${target_groupname}" != "${groupname}" ]; then
			log "info" "Group with ${gid} already exists: ${target_groupname}"
			log "info" "Changing GID of ${target_groupname} to ${spare_gid}"
			run "groupmod -g ${spare_gid} ${target_groupname}"
		fi
	fi
	# Change ugd and fix homedir permissions
	log "info" "Setting gid to ${gid} (group: ${groupname})"
	run "groupmod -g ${gid} ${groupname}"
	run "id ${username}"
}



# -------------------------------------------------------------------------------------------------
# HELPER FUNCTIONS
# -------------------------------------------------------------------------------------------------

###
### Get username by its uid
###
_get_username_by_uid() {
	if getent="$( getent passwd "${1}" )"; then
		echo "${getent//:*}"
		return 0
	fi
	return 1
}


###
### Get groupname by its gid
###
_get_groupname_by_gid() {
	if getent="$( getent group "${1}" )"; then
		echo "${getent//:*}"
		return 0
	fi
	return 1
}


###
### Get home directory by username
###
_get_homedir_by_username() {
	getent passwd "${1}" | cut -d: -f6
}


###
### Get home directory by groupname
###
_get_homedir_by_groupname() {
	grep -E ".*:x:[0-9]+:[0-9]+:$( _get_groupname_by_gid "${1}" ).*" /etc/passwd | cut -d: -f6
}



# -------------------------------------------------------------------------------------------------
# SANITY CHECKS
# -------------------------------------------------------------------------------------------------

###
### The following commands are required and used in the current script.
###
if ! command -v usermod >/dev/null 2>&1; then
	log "err" "usermod not found, but required."
	exit 1
fi
if ! command -v groupmod >/dev/null 2>&1; then
	log "err" "groupmod not found, but required."
	exit 1
fi
if ! command -v getent >/dev/null 2>&1; then
	log "err" "getent not found, but required."
	exit 1
fi
