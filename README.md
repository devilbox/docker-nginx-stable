# Nginx stable Docker

<small>**Latest build:** 2017-05-16</small>

[![Build Status](https://travis-ci.org/cytopia/docker-nginx-stable.svg?branch=master)](https://travis-ci.org/cytopia/docker-nginx-stable) [![](https://images.microbadger.com/badges/version/cytopia/nginx-stable.svg)](https://microbadger.com/images/cytopia/nginx-stable "nginx-stable") [![](https://images.microbadger.com/badges/image/cytopia/nginx-stable.svg)](https://microbadger.com/images/cytopia/nginx-stable "nginx-stable") [![](https://images.microbadger.com/badges/license/cytopia/nginx-stable.svg)](https://microbadger.com/images/cytopia/nginx-stable "nginx-stable")

[![cytopia/nginx-stable](http://dockeri.co/image/cytopia/nginx-stable)](https://hub.docker.com/r/cytopia/nginx-stable/)

**[Apache 2.2](https://github.com/cytopia/docker-apache-2.2) | [Apache 2.4](https://github.com/cytopia/docker-apache-2.4) | Nginx stable | [Nginx mainline](https://github.com/cytopia/docker-nginx-mainline)**

----

**Nginx stable Docker on CentOS 7**

[![Devilbox](https://raw.githubusercontent.com/cytopia/devilbox/master/.devilbox/www/htdocs/assets/img/devilbox_80.png)](https://github.com/cytopia/devilbox)

<sub>This docker image is part of the **[devilbox](https://github.com/cytopia/devilbox)**</sub>

----

## Options

### Environmental variables

#### Required environmental variables

- None

#### Optional environmental variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| DEBUG_COMPOSE_ENTRYPOINT | bool | `0` | Show shell commands executed during start.<br/>Value: `0` or `1` |
| TIMEZONE | string | `UTC` | Set docker OS timezone.<br/>(Example: `Europe/Berlin`) |
| PHP_FPM_ENABLE | bool | `0` | Enable PHP-FPM support.<br/>Value: `0` or `1` |
| PHP_FPM_SERVER_ADDR | string | `` | IP address or hostname of remote PHP-FPM server |
| PHP_FPM_SERVER_PORT | int | `9000` | Port of remote PHP-FPM server |
| CUSTOM_HTTPD_CONF_DIR | string | `` | Specify a directory inside the docker where Nginx should look for additional config files (`*.conf`).<br/><br/>This will overwrite the default virtual host including the PHP FPM settings.<br/><br/>Make sure to mount this directory from your host into the docker. |

### Default mount points

| Docker | Description |
|--------|-------------|
| /var/log/nginx | Nginx log dir |


### Default ports

| Docker | Description |
|--------|-------------|
| 80     | Nginx listening Port |


## Usage

**1. Serve static files**

Mount your local directort `~/my-host-www` into the docker and server those files.
```bash
$ docker run -i -p 80:80 -v ~/my-host-www:/var/www/html -t cytopia/nginx-stable
```

**2. Serve PHP files with PHP-FPM**

Note, for this to work, the `~/my-host-www` dir must be mounted into the nginx docker as well as into the php-fpm docker.

You can also attach other PHP-FPM version: [PHP-FPM 5.4](https://github.com/cytopia/docker-php-fpm-5.4), [PHP-FPM 5.5](https://github.com/cytopia/docker-php-fpm-5.5), [PHP-FPM 5.6](https://github.com/cytopia/docker-php-fpm-5.6), [PHP-FPM 7.0](https://github.com/cytopia/docker-php-fpm-7.0) or [PHP-FPM 7.1](https://github.com/cytopia/docker-php-fpm-7.1)

Each PHP-FPM docker also has the option to enable Xdebug and more, see their respective Readme files for futher settings.

```bash
# Start the PHP-FPM docker, mounting the same diectory
$ docker run -d -p 9000 -v ~/my-host-www:/var/www/html --name php cytopia/php-fpm-5.6

# Start the Nginx docker, linking it to the PHP-FPM docker
$ docker run -i \
    -p 80:80 \
    -v ~/my-host-www:/var/www/html \
    -e PHP_FPM_ENABLE=1 \
    -e PHP_FPM_SERVER_ADDR=php \
    -e PHP_FPM_SERVER_PORT=9000 \
    --link php \
    -t cytopia/nginx-stable
```


**3. Fully functional LEMP stack**

Same as above, but also add a MySQL docker and link it into Nginx.
```bash
# Start the MySQL docker
# Make sure to
#   1. Set the socket dir, which will be needed by the PHP-FPM docker.
#   2. Mount the socket dir to the host, as it needs to be mounted by PHP-FPM
$ docker run -d \
    -p 3306:3306 \
    -v ~/tmp/host-mysql-sock:/tmp/docker-mysql-sock \
    -e MYSQL_SOCKET_DIR=/tmp/docker-mysql-sock \
    -e MYSQL_ROOT_PASSWORD=my-secret-pw \
    --name mysql \
    -t cytopia/mysql-5.5

# Start the PHP-FPM docker, mounting the same diectory.
# Also make sure to
#   1. mount the MySQL socket to local disk within the PHP-FPM docker
#      in order to be able to use `localhost` for mysql connections from
#      withing the php docker.
#   2. forward the remote MySQL port 3306 to 127.0.0.1:3306 within the
#      PHP-FPM docker in order to be able to use `127.0.0.1` for mysq
#      connections from within the php docker.
$ docker run -d \
    -p 9000:9000 \
    -v ~/my-host-www:/var/www/html \
    -v ~/tmp/host-mysql-sock:/tmp/docker-mysql-sock \
    -e FORWARD_MYSQL_PORT_TO_LOCALHOST=1 \
    -e MYSQL_REMOTE_ADDR=mysql \
    -e MYSQL_REMOTE_PORT=3306 \
    -e MYSQL_LOCAL_PORT=3306 \
    -e MOUNT_MYSQL_SOCKET_TO_LOCALDISK=1 \
    -e MYSQL_SOCKET_PATH=/tmp/docker-mysql-sock/mysqld.sock \
    --name php \
    cytopia/php-fpm-5.6

# Start the Nginx docker, linking it to the PHP-FPM docker
$ docker run -i \
    -p 80:80 \
    -v ~/my-host-www:/var/www/html \
    -e PHP_FPM_ENABLE=1 \
    -e PHP_FPM_SERVER_ADDR=php \
    -e PHP_FPM_SERVER_PORT=9000 \
    --link php \
    --link mysql \
    -t cytopia/nginx-stable
```

**4. Ultimate pre-configured docker-compose setup**

Have a look at the **[devilbox](https://github.com/cytopia/devilbox)** for a fully-customizable docker-compose variant.

It offers pre-configured mass virtual hosts and an intranet.

It allows any of the following combinations:

* PHP 5.4, PHP 5.5, PHP 5.6, PHP 7.0 and PHP 7.1
* MySQL 5.5, MySQL 5.6, MySQL 5.7, MariaDB 5 and MariaDB 10
* Apache 2.2, Apache 2.4, Nginx stable and Nginx mainline
* And more to come...

## Version

```
nginx version: nginx/1.12.0
built by gcc 4.8.5 20150623 (Red Hat 4.8.5-11) (GCC)
built with OpenSSL 1.0.1e-fips 11 Feb 2013
TLS SNI support enabled
```
