FROM nginx:stable
MAINTAINER "cytopia" <cytopia@everythingcli.org>


###
### Labels
###
LABEL \
	name="cytopia's Nginx Image" \
	image="nginx-stable" \
	vendor="cytopia" \
	license="MIT" \
	build-date="2017-09-26"


###
### Installation
###

# required packages
RUN set -x \
	&& apt-get update \
	&& apt-get install --no-install-recommends --no-install-suggests -y \
		supervisor \
		python-yaml \
		make \
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
	&& rm -rf vhost_gen*

# watcherd
RUN set -x \
	&& wget --no-check-certificate -O /usr/bin/watcherd https://raw.githubusercontent.com/devilbox/watcherd/master/watcherd \
	&& chmod +x /usr/bin/watcherd

# cleanup
RUN set -x \
	&& apt-get update \
	&& apt-get remove -y \
		wget \
		make \
	&& rm -rf /var/lib/apt/lists/* \
	&& apt-get purge -y --auto-remove

# Add custom config directive to httpd server
RUN set -x \
	&& sed -i'' 's|^\s*include.*conf\.d/.*|    include /etc/nginx-stable.d/*.conf;\n    include /etc/nginx/conf.d/*.conf;\n    include /etc/nginx/custom.d/*.conf;\n|g' /etc/nginx/nginx.conf

# create directories
RUN set -x \
	&& rm -rf /etc/nginx/conf.d/* \
	&& mkdir -p /etc/nginx-stable.d \
	&& mkdir -p /etc/nginx/custom.d \
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
