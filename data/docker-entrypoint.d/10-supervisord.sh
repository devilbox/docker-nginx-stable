#!/usr/bin/env bash

set -e
set -u
set -o pipefail


############################################################
# Functions
############################################################


###
### Create supervisord.conf
###
supervisord_create() {
	local httpd_command="${1}"
	local watcherd_command="${2}"
	local config="${3}"

	if [ -d "$( basename "${config}" )" ]; then
		mkdir -p "$( basename "${config}" )"
	fi

	{
		echo "[supervisord]"
		echo "user=root"
		echo "nodaemon=true"
		echo
		echo "[program:httpd]"
		echo "command=${httpd_command}"
		echo "autostart=false"
		echo "autorestart=false"
		echo "stdout_logfile=/dev/stdout"
		echo "stdout_logfile_maxbytes=0"
		echo "stderr_logfile=/dev/stderr"
		echo "stderr_logfile_maxbytes=0"
		echo "stdout_events_enabled=true"
		echo "stderr_events_enabled=true"
		echo
		echo "[program:watcherd]"
		echo "command=${watcherd_command}"
		echo "autorestart=false"
		echo "stdout_logfile=/dev/stdout"
		echo "stdout_logfile_maxbytes=0"
		echo "stderr_logfile=/dev/stderr"
		echo "stderr_logfile_maxbytes=0"
		echo "stdout_events_enabled=true"
		echo "stderr_events_enabled=true"
	} > "${config}"
}
