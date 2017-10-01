FROM nginx:stable
MAINTAINER "cytopia" <cytopia@everythingcli.org>


###
### Labels
###
LABEL \
	name="cytopia's Nginx Image" \
	image="nginx-stable" \
	vendor="devilbox" \
	license="MIT" \
	build-date="2017-10-01"


###
### Installation
###

# required packages
RUN set -x \
	&& apt-get update \
	&& apt-get upgrade -y \
	&& apt-get install --no-install-recommends --no-install-suggests -y \
		make \
		python-yaml \
		supervisor \
		wget \
	&& rm -rf /var/lib/apt/lists/* \
	&& apt-get purge -y --auto-remove

# vhost-gen
RUN set -x \
	&& wget --no-check-certificate -O vhost_gen.tar.gz https://github.com/devilbox/vhost-gen/archive/master.tar.gz \
	&& tar xfvz vhost_gen.tar.gz \
	&& cd vhost-gen-master \
	&& make install \
	&& cd .. \
	&& rm -rf vhost*gen*

# watcherd
RUN set -x \
	&& wget --no-check-certificate -O /usr/bin/watcherd https://raw.githubusercontent.com/devilbox/watcherd/master/watcherd \
	&& chmod +x /usr/bin/watcherd

# cleanup
RUN set -x \
	&& apt-get update \
	&& apt-get remove -y \
		make \
		wget \
	&& apt-get autoremove -y \
	&& rm -rf /var/lib/apt/lists/* \
	&& apt-get purge -y --auto-remove

# Add custom config directive to httpd server
RUN set -x \
	&& sed -i'' 's|^\s*include.*conf\.d/.*|    include /etc/httpd-custom.d/*.conf;\n    include /etc/httpd/conf.d/*.conf;\n    include /etc/httpd/vhost.d/*.conf;\n|g' /etc/nginx/nginx.conf

# create directories
RUN set -x \
	&& mkdir -p /etc/httpd-custom.d \
	&& mkdir -p /etc/httpd/conf.d \
	&& mkdir -p /etc/httpd/vhost.d \
	&& mkdir -p /var/www/default/htdocs \
	&& mkdir -p /shared/httpd \
	&& chmod 0775 /shared/httpd \
	&& chown nginx:nginx /shared/httpd


###
### Copy files
###
COPY ./data/vhost-gen/conf.yml /etc/vhost-gen/conf.yml
COPY ./data/vhost-gen/main.yml /etc/vhost-gen/main.yml
COPY ./data/supervisord.conf /etc/supervisord.conf
COPY ./data/docker-entrypoint.sh /docker-entrypoint.sh


###
### Ports
###
EXPOSE 80


###
### Volumes
###
VOLUME /shared/httpd


###
### Signals
###
STOPSIGNAL SIGTERM


###
### Entrypoint
###
ENTRYPOINT ["/docker-entrypoint.sh"]
