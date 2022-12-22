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
	_gray="\033[38;5;244m"
	#_green="\033[0;32m"
	#_yellow="\033[0;33m"
	_reset="\033[0m"
	#_user="$(whoami)"

	printf "${_gray}%s${_cmd}${_reset}\n" "\$ "
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
		#printf "${clr_green}%s${clr_rst}\n" "--------------------------------------------------------------------------------" 1>&2
		printf "${clr_green}[SUCC] %s${clr_rst}\n" "${message}"
		#printf "${clr_green}%s${clr_rst}\n" "--------------------------------------------------------------------------------" 1>&2
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


docker_logs() {
	local container_name="${1}"
	docker logs "${container_name}" || true
}

docker_stop() {
	local container_name="${1}"
	docker stop "${container_name}"  >/dev/null 2>&1 || true
	docker rm -f "${container_name}" >/dev/null 2>&1 || true
}


# --------------------------------------------------------------------------------------------------
# TESTS
# --------------------------------------------------------------------------------------------------

###
### Application 1
###
create_app() {
	local path="${1}"
	local docr="${2}"
	local name="${3}"
	local file="${4}"
	local cont="${5}"

	run "mkdir -p ${path}/${name}/${docr}"
	run "echo \"${cont}\" > ${path}/${name}/${docr}/${file}"
}



###
### Find expected string in URL
###
test_vhost_response() {
	local expect="${1}"
	local url="${2}"
	local header="${3:-}"

	#local clr_gray="\033[38;5;244m"
	local clr_rst="\033[0m"
	local clr_test="\033[0;34m"  # blue


	printf "${clr_test}%s${clr_rst}\n" "--------------------------------------------------------------------------------" 1>&2
	printf "${clr_test}[TEST] %s${clr_rst}\n" "Exec: curl -sS -k -L '${url}' -H '${header}'"
	printf "${clr_test}[TEST] %s${clr_rst}" "Find: '${expect}' "

	count=0
	retry=30
	output=""
	while ! output="$( sh -c "LANG=C LC_ALL=C curl --fail -sS -k -L '${url}' -H '${header}' 2>/dev/null | grep '^${expect}$'" )"; do
		printf "."
		if [ "${count}" = "${retry}" ]; then
			printf "\\n"
			sh -c "LANG=C LC_ALL=C curl -v --fail -sS -k -L '${url}' -H '${header}'" || true
			return 1
		fi
		count=$(( count + 1 ))
		sleep 1
	done

	# Print success
	printf "\\n"
	log "ok" "Resp: '${output}'"
	echo
}


###
### Check docker logs for Errors
###
test_docker_logs_err() {
	local container_name="${1}"

	local re_internal_upper='(\[(FAILURE|FAILED|FAIL|FATAL|ERROR|ERR|WARNING|WARN)\])'
	local re_internal_lower='(\[(failure|failed|fail|fatal|error|err|warning|warn)\])'
	local re_upper='(FAULT|FAIL|FATAL|ERROR|WARN)'
	local re_lower='(segfault|fail|fatal|error|warn)'
	local re_mixed='([Ss]egfault|[Ff]ail|[Ff]atal|[Ww]arn)'
	local regex="${re_internal_upper}|${re_internal_lower}|${re_upper}|${re_lower}|${re_mixed}"

	# Ignore this pattern
	local ignore1='creating Certificate Authority'
	local ignore2='error_log'            # nginx error log directive
	local ignore3="fastcgi_intercept_errors" # nginx
	local ignore4='LogLevel'             # Apache logging directive
	local ignore5='ErrorLog'             # Apache error log directive
	local ignore6='# Possible values'    # Apache httpd.conf contains a comment with verbosity levels
	local ignore7='# consult the online' # Apache httpd.conf contains a comment with warning
	local ignore8='stackoverflow'        # contains a link comment with 'error' in url
	local ignore9='\[warn\] NameVirtualHost'  # Apache specific, when massvhost projects are not yet loaded
	local ignore="${ignore1}|${ignore2}|${ignore3}|${ignore4}|${ignore5}|${ignore6}|${ignore7}|${ignore8}|${ignore9}"

	#local clr_gray="\033[38;5;244m"
	local clr_test="\033[0;34m"  # blue
	local clr_rst="\033[0m"

	printf "${clr_test}%s${clr_rst}\n" "--------------------------------------------------------------------------------" 1>&2
	printf "${clr_test}[TEST] %s${clr_rst}\n" "Exec: docker logs ${container_name}"
	printf "${clr_test}[TEST] %s${clr_rst}\n" "Find: '${regex}'"

	if docker logs "${container_name}" 2>&1 | grep -Ev "${ignore}" | grep -E "${regex}" >/dev/null; then
		log "fail" "Found: $( docker logs "${container_name}" 2>&1 | grep -Ev "${ignore}" | grep -E "${regex}" )"
		return 1
	fi

	# Print success
	log "ok" "Resp: Nothing found in docker logs"
	echo
}
