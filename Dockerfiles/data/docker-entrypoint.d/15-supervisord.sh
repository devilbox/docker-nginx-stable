#!/usr/bin/env bash

set -e
set -u
set -o pipefail

###
### This file holds functions to conigure supervisord
###


# -------------------------------------------------------------------------------------------------
# ACTION FUNCTIONS
# -------------------------------------------------------------------------------------------------

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

	# Enable supervisorctl (default: disabled)
	SVCTL_ENABLE="${SVCTL_ENABLE:-0}"
	SVCTL_LISTEN_ADDR="0.0.0.0"
	SVCTL_LISTEN_PORT=9001
	SVCTL_USER="$( get_random_alphanum "10" )"
	SVCTL_PASS="$( get_random_alphanum "10" )"

	if [ "${SVCTL_LISTEN_ADDR}" = "0.0.0.0" ] || [ "${SVCTL_LISTEN_ADDR}" = "*" ]; then
		SVCTL_CONNECT_ADDR="127.0.0.1"
	fi

	# This allows for 'supvervisorctl restart watcherd
	{
		# Use 'echo_supervisord_conf' to generate an example config
		if [ "${SVCTL_ENABLE}" = "1" ]; then
			echo "[rpcinterface:supervisor]"
			echo "supervisor.rpcinterface_factory = supervisor.rpcinterface:make_main_rpcinterface"

			echo "[inet_http_server]          ; inet (TCP) server disabled by default"
			echo "port=${SVCTL_LISTEN_ADDR}:${SVCTL_LISTEN_PORT} ; ip_address:port specifier, *:port for all iface"
			echo "username=${SVCTL_USER}      ; default is no username (open server)"
			echo "password=${SVCTL_PASS}      ; default is no password (open server)"

			echo "[supervisorctl]"
			echo ";serverurl=unix:///tmp/supervisor.sock ; use a unix:// URL  for a unix socket"
			echo "serverurl=http://${SVCTL_CONNECT_ADDR}:${SVCTL_LISTEN_PORT} ; http:// url to specify an inet socket"
			echo "username=${SVCTL_USER}      ; should be same as in [*_http_server] if set"
			echo "password=${SVCTL_PASS}      ; should be same as in [*_http_server] if set"
			echo ";prompt=mysupervisor        ; cmd line prompt (default 'supervisor')"
			echo ";history_file=~/.sc_history ; use readline history if available"
		fi

		echo "[supervisord]"
		echo "user=root"
		echo "nodaemon=true"
		echo "loglevel=warn"
		echo
		echo "[program:httpd]"
		echo "command=${httpd_command}"
		echo "priority=1"
		echo "autostart=true"
		echo "startretries=100"
		echo "startsecs=1"
		echo "autorestart=true"
		echo "stdout_logfile=/dev/stdout"
		echo "stderr_logfile=/dev/stderr"
		echo "stdout_logfile_maxbytes=0"
		echo "stderr_logfile_maxbytes=0"
		echo "stdout_events_enabled=true"
		echo "stderr_events_enabled=true"
		echo
		echo "[program:watcherd]"
		echo "command=${watcherd_command}"
		echo "priority=999"
		echo "autostart=true"
		echo "autorestart=true"
		echo "stdout_logfile=/dev/stdout"
		echo "stderr_logfile=/dev/stderr"
		echo "stdout_logfile_maxbytes=0"
		echo "stderr_logfile_maxbytes=0"
		echo "stdout_events_enabled=true"
		echo "stderr_events_enabled=true"
	} > "${config}"
}
