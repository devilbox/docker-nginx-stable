#!/bin/sh -eu


NGINX_VERSION="stable"

if [ "${NGINX_VERSION}" = "stable" ]; then
	_extract="head -1"
elif [ "${NGINX_VERSION}" = "mainline" ]; then
	_extract="tail -1"
else
	echo "Invalid nginx version"
	exit 1
fi

##
## VARIABLES
##
VERSION_GOSU="1.2"
HTTPD_CONF="/etc/nginx/nginx.conf"






MY_USER="apache"
MY_GROUP="apache"
MY_UID="48"
MY_GID="48"


##
## FUNCTIONS
##
print_headline() {
	_txt="${1}"
	_blue="\033[0;34m"
	_reset="\033[0m"

	printf "${_blue}\n%s\n${_reset}" "--------------------------------------------------------------------------------"
	printf "${_blue}- %s\n${_reset}" "${_txt}"
	printf "${_blue}%s\n\n${_reset}" "--------------------------------------------------------------------------------"
}

run() {
	_cmd="${1}"

	_red="\033[0;31m"
	_green="\033[0;32m"
	_reset="\033[0m"
	_user="$(whoami)"

	printf "${_red}%s \$ ${_green}${_cmd}${_reset}\n" "${_user}"
	sh -c "LANG=C LC_ALL=C ${_cmd}"
}


################################################################################
# MAIN ENTRY POINT
################################################################################

##
## Adding Users
##
print_headline "1. Adding Users"
run "groupadd -g ${MY_GID} -r ${MY_GROUP}"
run "adduser ${MY_USER} -u ${MY_UID} -M -s /sbin/nologin -g ${MY_GROUP}"



###
### Adding Repositories
###
### (required for mod_xsendfile)
print_headline "2. Adding Repository"
#run "yum -y install epel-release"



###
### Updating Packages
###
print_headline "3. Updating Packages Manager"
run "yum clean all"
run "yum -y check"
run "yum -y update"



###
### Installing Packages
###
print_headline "4. Installing Packages"
run "yum -y install \
	gcc \
	make \
	openssl-devel \
	pcre-devel \
	zlib-devel \
	redhat-rpm-config \
	gperftools-devel \
	"
# redhat-rpm-config required for: /usr/lib/rpm/redhat/redhat-hardened-ld


# Get Nginx version (stable or mainline)
DL_URL="$( curl -q https://www.nginx.com/resources/wiki/start/topics/tutorials/install/ | grep -oE 'http[s]*://nginx.org/download/nginx-.*tar.gz' | eval ${_extract} )"
VERSION="$( echo "${DL_URL}" | grep -oE 'nginx-.*' | sed 's/.tar.gz//g' )"

run "curl -SL -o /tmp/${VERSION}.tar.gz ${DL_URL} --retry 999 --retry-max-time 0 -C -"
run "mkdir /tmp/${VERSION}"
run "tar xfvz /tmp/${VERSION}.tar.gz --directory /tmp/"
run "cd /tmp/${VERSION} && \
	./configure \
		--prefix=/usr/share/nginx \
		\
		--sbin-path=/sbin/nginx \
		--conf-path=/etc/nginx/nginx.conf \
		--pid-path=/var/run/nginx/nginx.pid \
		--lock-path=/run/lock/subsys/nginx \
		--error-log-path=/var/log/nginx/error.log \
		--http-log-path=/var/log/nginx/access.log \
		\
		--http-client-body-temp-path=/var/lib/nginx/tmp/client_body \
		--http-proxy-temp-path=/var/lib/nginx/tmp/proxy \
		--http-fastcgi-temp-path=/var/lib/nginx/tmp/fastcgi \
		--http-uwsgi-temp-path=/var/lib/nginx/tmp/uwsgi \
		--http-scgi-temp-path=/var/lib/nginx/tmp/scgi \
		\
		--user=${MY_USER} \
		--group=${MY_GROUP} \
		\
		--with-pcre \
		--with-pcre-jit \
		--with-google_perftools_module \
		--with-http_ssl_module \
		--with-http_v2_module \
		\
		--with-cc-opt='-O2 -g -pipe -Wall -Wp,-D_FORTIFY_SOURCE=2 -fexceptions -fstack-protector-strong --param=ssp-buffer-size=4 -grecord-gcc-switches -specs=/usr/lib/rpm/redhat/redhat-hardened-cc1 -m64 -mtune=generic' --with-ld-opt='-Wl,-z,relro -specs=/usr/lib/rpm/redhat/redhat-hardened-ld -Wl,-E' \
		--with-ld-opt='-Wl,-z,relro -specs=/usr/lib/rpm/redhat/redhat-hardened-ld -Wl,-E' \
		&& \
	make && \
	make install"

# Create directories
if [ ! -d "/var/lib/nginx/tmp/client_body" ]; then
	run "mkdir -p /var/lib/nginx/tmp/client_body"
fi
if [ ! -d "/var/lib/nginx/tmp/proxy" ]; then
	run "mkdir -p /var/lib/nginx/tmp/proxy"
fi
if [ ! -d "/var/lib/nginx/tmp/fastcgi" ]; then
	run "mkdir -p /var/lib/nginx/tmp/fastcgi"
fi
if [ ! -d "/var/lib/nginx/tmp/uwsgi" ]; then
	run "mkdir -p /var/lib/nginx/tmp/uwsgi"
fi
if [ ! -d "/var/lib/nginx/tmp/scgi" ]; then
	run "mkdir -p /var/lib/nginx/tmp/scgi"
fi
run "chown -R ${MY_USER}:${MY_GROUP} /var/lib/nginx"

if [ ! -d "/var/run/nginx" ]; then
	run "mkdir -p /var/run/nginx"
fi
run "chown -R ${MY_USER}:${MY_GROUP} /var/run/nginx"



# Cleanup
run "rm -rf /tmp/${VERSION}*"
run "yum -y remove \
	gcc \
	make \
	openssl-devel \
	pcre-devel \
	zlib-devel \
	redhat-rpm-config \
	\
	cpp \
	glibc-devel \
	glibc-headers \
	kernel-headers \
	keyutils-libs-devel \
	krb5-devel \
	libcom_err-devel \
	libgomp \
	libmpc \
	libselinux-devel  \
	libsepol-devel \
	libverto-devel \
	mpfr \
	\
	dwz \
	groff-base \
	perl \
	perl-Carp.noarch\
	perl-Encode \
	perl-Exporter.noarch\
	perl-File-Path.noarch\
	perl-File-Temp.noarch\
	perl-Filter \
	perl-Getopt-Long.noarch\
	perl-HTTP-Tiny.noarch\
	perl-PathTools \
	perl-Pod-Escapes.noarch\
	perl-Pod-Perldoc.noarch\
	perl-Pod-Simple.noarch\
	perl-Pod-Usage.noarch\
	perl-Scalar-List-Utils \
	perl-Socket \
	perl-Storable \
	perl-Text-ParseWords.noarch\
	perl-Time-HiRes \
	perl-Time-Local.noarch\
	perl-constant.noarch\
	perl-libs \
	perl-macros \
	perl-parent.noarch\
	perl-podlators.noarch\
	perl-srpm-macros.noarch\
	perl-threads \
	perl-threads-shared \
	zip \
	\
	gperftools-devel \
	"







###
### Configure Apache
###
### (Remove all custom config)
###
print_headline "5. Configure Nginx"

# Clean all configs
if [ ! -d "/etc/nginx/conf.d/" ]; then
	run "mkdir -p /etc/nginx/conf.d/"
else
	run "rm -rf /etc/nginx/conf.d/*"
fi

if [ ! -d "/etc/nginx/server.d/" ]; then
	run "mkdir -p /etc/nginx/server.d/"
else
	run "rm -rf /etc/nginx/server.d/*"
fi

# Add Base Configuration
{
	echo "# User/Group";
	echo "user ${MY_USER} ${MY_GROUP};";
	echo;

	echo "# Set to the number of processors";
	echo "# grep processor /proc/cpuinfo | wc -l";
	echo "worker_processes 1;";
	echo;

	echo "# [debug | info | notice | warn | error | crit | alert | emerg];";
	echo "error_log /var/log/nginx/error.log warn;";
	echo;

	echo "events {";
	echo "    # Sets the maximum number of simultaneous connections that can be opened by a worker process.";
	echo "    worker_connections  1024;";
	echo "}";
	echo;

	echo "http {";
	echo "    include       mime.types;";
	echo "    default_type  application/octet-stream;";
	echo;
	echo "    log_format    main '\$remote_addr - \$remote_user [\$time_local] \"\$request\" '";
	echo "                       '\$status \$body_bytes_sent \"\$http_referer\" '";
	echo "                       '\"\$http_user_agent\" \"\$http_x_forwarded_for\"';";
	echo;
	echo "    access_log    /var/log/nginx/access.log  main;";
	echo;
	echo;
	echo "    # Custom http overwrite includes";
	echo "    include       /etc/nginx/conf.d/*.conf;";
	echo;
	echo "    # Custom server overwrite includes";
	echo "    include       /etc/nginx/server.d/*.conf;";
	echo "}";
	echo;
} > "${HTTPD_CONF}"

# Add Custom http Configuration
{
	echo "# [performance] Nginx 3 most famous options!!!11";
	echo "sendfile      on;";
	echo;

	echo "# tcp_nopush option will make nginx to send all header files";
	echo "# in a single packet rather than seperate packets.";
	echo "tcp_nopush    on;";
	echo;

	echo "# don't buffer data-sends (disable Nagle algorithm).";
	echo "# Good for sending frequent small bursts of data in real time.";
	echo "tcp_nodelay   on;";
	echo;
} > "/etc/nginx/conf.d/http.conf"

# Add Default vhost Configuration
{
	echo "server {";
	echo "    listen      80 default_server;";
	echo "    server_name _;";
	echo;

	echo "    access_log  /var/log/nginx/localhost.access.log  main;";
	echo;

	echo "    location / {";
	echo "        root  html;";
	echo "        index index.html index.htm;";
	echo "    }";
	echo;

	echo "    # deny access to .htaccess files, if Apache's document root";
	echo "    # concurs with nginx's one";
	echo "    location ~ /\.ht {";
	echo "            deny  all;";
	echo "    }";
	echo;

	echo "}";
	echo;

} > "/etc/nginx/server.d/localhost.conf"



###
### Installing Gosu
###
print_headline "6. Installing Gosu"
run "gpg --keyserver pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4"
run "curl -SL -o /usr/local/bin/gosu https://github.com/tianon/gosu/releases/download/${VERSION_GOSU}/gosu-amd64 --retry 999 --retry-max-time 0 -C -"
run "curl -SL -o /usr/local/bin/gosu.asc https://github.com/tianon/gosu/releases/download/${VERSION_GOSU}/gosu-amd64.asc --retry 999 --retry-max-time 0 -C -"
run "gpg --verify /usr/local/bin/gosu.asc"
run "rm /usr/local/bin/gosu.asc"
run "rm -rf /root/.gnupg/"
run "chown root /usr/local/bin/gosu"
run "chmod +x /usr/local/bin/gosu"
run "chmod +s /usr/local/bin/gosu"



###
### Creating Mass VirtualHost dirs
###
print_headline "7. Creating Mass VirtualHost dirs"
run "mkdir -p /shared/httpd"
run "chmod 775 /shared/httpd"
run "chown ${MY_USER}:${MY_GROUP} /shared/httpd"



###
### Cleanup unecessary packages
###
print_headline "8. Cleanup unecessary packages"
run "yum -y autoremove"


###
### Reinstall mess by autoremove
###
run "yum -y install \
	gperftools-libs \
	"