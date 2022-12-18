#!/usr/bin/env bash

set -e
set -u
set -o pipefail


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
		return
	fi

	# Unix Time
	log "info" "Setting timezone to ${timezone}"
	run "ln -sf /usr/share/zoneinfo/${timezone} /etc/localtime"
	run "date"
}
