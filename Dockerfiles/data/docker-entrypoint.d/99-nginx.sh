#!/usr/bin/env bash

set -e
set -u
set -o pipefail


############################################################
# Functions
############################################################

###
### Change worker_processes
###
nginx_set_worker_processess() {
	local value="${1}"
	local config="/etc/nginx/nginx.conf"

	log "info" "Setting Nginx worker_processes to: ${value}"
	run "sed -i'' 's/__WORKER_PROCESSES__/${value}/g' ${config}"
}


###
### Change worker_connections
###
nginx_set_worker_connections() {
	local value="${1}"
	local config="/etc/nginx/nginx.conf"

	log "info" "Setting Nginx worker_connections to: ${value}"
	run "sed -i'' 's/__WORKER_CONNECTIONS__/${value}/g' ${config}"
}
