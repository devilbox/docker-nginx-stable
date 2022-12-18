#!/usr/bin/env bash

set -e
set -u
set -o pipefail

###
### This file holds functions to change the timezone
###


# -------------------------------------------------------------------------------------------------
# [SET] FUNCTIONS
# -------------------------------------------------------------------------------------------------

###
### Set Timezone
###
set_timezone() {
	local timezone="${1}"

	# If uid is empty, end this function
	if [ "${timezone}" = "UTC" ]; then
		log "info" "Skipping timezone. Already set to UTC: $(date)"
		return
	fi

	# Unix Time
	log "info" "Setting timezone to ${timezone}"
	run "ln -sf /usr/share/zoneinfo/${timezone} /etc/localtime"
	log "info" "Current date: $(date)"
}
