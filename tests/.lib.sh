#!/usr/bin/env bash

set -e
set -u
set -o pipefail


###
### Run
###
run() {
	_cmd="${1}"

	#_red="\033[0;31m"
	_green="\033[0;32m"
	#_yellow="\033[0;33m"
	_reset="\033[0m"
	#_user="$(whoami)"

	printf "${_green}%s${_cmd}${_reset}\n" "\$ "
	sh -c "LANG=C LC_ALL=C ${_cmd}"
}


log() {
	local type="${1}"
	local message="${2}"

	local clr_gray="\033[38;5;244m"
	local clr_green="\033[0;32m"
	local clr_red="\033[0;31m"
	local clr_rst="\033[0m"

	if [ "${type}" = "fail" ]; then
		printf "${clr_red}%s${clr_rst}\n" "--------------------------------------------------------------------------------" 1>&2
		printf "${clr_red}[FAIL] %s${clr_rst}\n" "${message}" 1>&2
		printf "${clr_red}%s${clr_rst}\n" "--------------------------------------------------------------------------------" 1>&2
	elif [ "${type}" = "ok" ]; then
		printf "${clr_green}%s${clr_rst}\n" "--------------------------------------------------------------------------------" 1>&2
		printf "${clr_green}[SUCC] %s${clr_rst}\n" "${message}"
		printf "${clr_green}%s${clr_rst}\n" "--------------------------------------------------------------------------------" 1>&2
	elif [ "${type}" = "loop" ]; then
		printf "${clr_gray}%s${clr_rst}\n" "--------------------------------------------------------------------------------" 1>&2
		printf "${clr_gray}[LOOP] %s${clr_rst}\n" "${message}"
		printf "${clr_gray}%s${clr_rst}\n" "--------------------------------------------------------------------------------" 1>&2
	else
		printf "${clr_red}%s${clr_rst}\n" "--------------------------------------------------------------------------------" 1>&2
		printf "${clr_red}[SYS]  %s${clr_rst}\n" "Unknown log type: ${type}" 1>&1
		printf "${clr_red}%s${clr_rst}\n" "--------------------------------------------------------------------------------" 1>&2
		return 1
	fi
}


###
### Get 15 character random word
###
function get_random_name() {
	local chr=(a b c d e f g h i j k l m o p q r s t u v w x y z)
	local len="${#chr[@]}"
	local name=

	# shellcheck disable=SC2034
	for i in {1..15}; do
		rand="$( shuf -i "0-${len}" -n 1 )"
		rand=$(( rand - 1 ))
		name="${name}${chr[$rand]}"
	done
	echo "${name}"
}

tmp_dir() {
	local tmp_dir=
	tmp_dir="$( mktemp -d )"
	chmod 755 "${tmp_dir}"
	echo "${tmp_dir}"
}


while_retry() {
	local cmd_condition="${1}"   # while loop condition
	local retries="${2:-30}"     # how many times to loop

	count=0
	output=""
	log "loop" "${cmd_condition}"
	while ! output="$( sh -c "LANG=C LC_ALL=C ${cmd_condition}" )"; do
		printf "."
		if [ "${count}" = "${retries}" ]; then
			printf "\\n"
			return 1
		fi
		count=$(( count + 1 ))
		sleep 1
	done
	printf "\\n"
	echo "${output}"
}
