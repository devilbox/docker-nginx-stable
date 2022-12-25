#!/usr/bin/env bash

set -e
set -u
set -o pipefail

###
### This file defines vhost-gen generator functions.
###


# -------------------------------------------------------------------------------------------------
# vhost-gen
# -------------------------------------------------------------------------------------------------

###
### Generate vhost-gen config file (not template)
###
generate_vhostgen_conf() {
	local httpd_server="${1}"   # nginx, apache22, apache24
	local conf_dir="${2}" # Store generated httpd.conf in this directory
	local tld_suffix="${3}"
	local docroot_subdir="${4}"
	local index="${5}"    # comma separated list of index files, e.g.: "index.html, index.php"
	local http2_enable="${6}"   # "yes" or "no"
	local dir_crt="${7}"
	local dir_key="${8}"
	local log_prefix="${9}"     # "yes" or "no"
	local docker_logs="${10}"     # "yes" or "no"
	local php_fpm_enable="${11}"
	local php_fpm_addr="${12}"
	local php_fpm_port="${13}"
	local timeout="${14}"
	local alias_allow="${15}"   # alias1:path1[:cors], alias2:path2[:cors]
	local alias_deny="${16}"    # alias1[,alias2]
	local server_status_enable="${17}"
	local server_status_alias="${18}"

	alias_allow_block="alias: []"
	if [ -n "${alias_allow}" ]; then
		alias_allow_block="alias:\n"
		# Ensure to convert ',' to space, to have items to iterate over
		for item in ${alias_allow//,/ }; do
			item_alias="$( echo "${item}" | awk -F':' '{print $1}' )"
			item_path="$(  echo "${item}" | awk -F':' '{print $2}' )"
			item_cors="$(  echo "${item}" | awk -F':' -v OFS=':' '{$1="";$2="";print}' | sed -e 's/^://g' -e 's/^://g' )"
			alias_allow_block+="    - alias: ${item_alias}\n"
			alias_allow_block+="      path: ${item_path}\n"
			if [ -n "${item_cors}" ]; then
				alias_allow_block+="      xdomain_request:\n"
				alias_allow_block+="        enable: yes\n"
				alias_allow_block+="        origin: ${item_cors}\n"
			fi
		done
	fi

	alias_deny_block="deny: []"
	if [ -n "${alias_deny}" ]; then
		alias_deny_block="deny:\n"
		# Ensure to convert ',' to space, to have items to iterate over
		for item_alias in ${alias_deny//,/ }; do
			alias_deny_block+="    - alias: '${item_alias}'\n"
		done
	fi


	# https://github.com/devilbox/vhost-gen/blob/master/etc/conf.yml
	OUT=$(cat <<EOF
---
server: ${httpd_server}
conf_dir: ${conf_dir}
vhost:
  port: 80
  ssl_port: 443
  name:
    prefix:
    suffix: ${tld_suffix}
  docroot:
    suffix: ${docroot_subdir}
  index: [${index}]
  ssl:
    http2: ${http2_enable}
    dir_crt: ${dir_crt}
    dir_key: ${dir_key}
    protocols: 'TLSv1 TLSv1.1 TLSv1.2'
    honor_cipher_order: 'on'
    ciphers: 'HIGH:!aNULL:!MD5'
  log:
    access:
      prefix: ${log_prefix}
      stdout: ${docker_logs}
    error:
      prefix: ${log_prefix}
      stderr: ${docker_logs}
    dir:
      create: yes
      path: /var/log/httpd
  php_fpm:
    enable: ${php_fpm_enable}
    address: "${php_fpm_addr}"
    port: ${php_fpm_port}
    timeout: ${timeout}
  ${alias_allow_block}
  # Denies locations
  ${alias_deny_block}
  # Enable server status on the following alias
  server_status:
    enable: ${server_status_enable}
    alias: ${server_status_alias}
EOF
	)
	echo -e "${OUT}"
}
