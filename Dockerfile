##
## Nginx
##
FROM centos:latest
MAINTAINER "cytopia" <cytopia@everythingcli.org>


##
## Labels
##
LABEL \
	name="cytopia's Nginx Image" \
	image="nginx-stable" \
	vendor="cytopia" \
	license="MIT" \
	build-date="2016-11-03"


# Copy scripts
COPY ./scripts/docker-install.sh /
COPY ./scripts/docker-entrypoint.sh /


# Install
RUN /docker-install.sh


##
## Ports
##
EXPOSE 80


##
## Volumes
##
VOLUME /var/log/nginx


##
## Become apache in order to have mounted files
## with apache user rights
##
User apache


##
## Entrypoint
##
ENTRYPOINT ["/docker-entrypoint.sh"]
