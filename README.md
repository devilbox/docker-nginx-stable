# Nginx stable Docker

[![](https://images.microbadger.com/badges/version/cytopia/nginx-stable.svg)](https://microbadger.com/images/cytopia/nginx-stable "nginx-stable") [![](https://images.microbadger.com/badges/image/cytopia/nginx-stable.svg)](https://microbadger.com/images/cytopia/nginx-stable "nginx-stable") [![](https://images.microbadger.com/badges/license/cytopia/nginx-stable.svg)](https://microbadger.com/images/cytopia/nginx-stable "nginx-stable")

[![cytopia/nginx-stable](http://dockeri.co/image/cytopia/nginx-stable)](https://hub.docker.com/r/cytopia/nginx-stable/)

**[Apache 2.2](https://github.com/cytopia/docker-apache-2.2) | [Apache 2.4](https://github.com/cytopia/docker-apache-2.4) | Nginx stable | [Nginx mainline](https://github.com/cytopia/docker-nginx-mainline)**

----

Nginx stable Docker on CentOS 7

This docker image is part of the **[devilbox](https://github.com/cytopia/devilbox)**

----

## Usage

**Serve static files**

Mount your local directort `~/my-host-www` into the docker and server those files.
```bash
$ docker run -i -p 80:80 -v ~/my-host-www:/var/www/html -t cytopia/nginx-stable
```

**Start with PHP-FPM**

Note, for this to work, the `~/my-host-www` dir must be mounted into the nginx docker as well as into the php-fpm docker.
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

**Fully functional LEMP stack**

Same as above, but also add a MySQL docker and link it into Nginx.
```bash
# Start the MySQL docker
# Make sure to
#   1. Set the socket dir, which will be needed by the PHP-FPM docker.
#   2. Mount the socket dir to the host, as it needs to be mounted by PHP-FPM
$ docker run -i \
    -p 3306 \
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
    -p 9000 \
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

**Feature-rich pre-configured docker-compose setup**

Have a look at the **[devilbox](https://github.com/cytopia/devilbox) for a fully-customizable docker-compose variant.


## Options


### Environmental variables

#### Required environmental variables

- None

#### Optional environmental variables

| Variable | Type | Description |
|----------|------|-------------|
| DEBUG_COMPOSE_ENTRYPOINT | bool | Show shell commands executed during start.<br/>Value: `0` or `1` |
| TIMEZONE | string | Set docker OS timezone.<br/>(Example: `Europe/Berlin`) |
| PHP_FPM_ENABLE | bool | Enable PHP-FPM support.<br/>Value: `0` or `1` |
| PHP_FPM_SERVER_ADDR | string | IP address of remote PHP-FPM server |
| PHP_FPM_SERVER_PORT | int | Port  of remote PHP-FPM server |
| CUSTOM_HTTPD_CONF_DIR | string | Specify a directory inside the docker where Nginx should look for additional config files (`*.conf`).<br/><br/>This will overwrite the default virtual host.<br/><br/>Make sure to mount this directory from your host into the docker. |

### Default mount points

| Docker | Description |
|--------|-------------|
| /var/log/nginx | Nginx log dir |


### Default ports

| Docker | Description |
|--------|-------------|
| 80     | Nginx listening Port |
