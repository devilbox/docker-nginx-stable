# Nginx stable Docker

[![](https://images.microbadger.com/badges/version/cytopia/nginx-stable.svg)](https://microbadger.com/images/cytopia/nginx-stable "nginx-stable") [![](https://images.microbadger.com/badges/image/cytopia/nginx-stable.svg)](https://microbadger.com/images/cytopia/nginx-stable "nginx-stable") [![](https://images.microbadger.com/badges/license/cytopia/nginx-stable.svg)](https://microbadger.com/images/cytopia/nginx-stable "nginx-stable")

[![cytopia/nginx-stable](http://dockeri.co/image/cytopia/nginx-stable)](https://hub.docker.com/r/cytopia/nginx-stable/)

**[Apache 2.2](https://github.com/cytopia/docker-apache-2.2) | [Apache 2.4](https://github.com/cytopia/docker-apache-2.4) | Nginx stable | [Nginx mainline](https://github.com/cytopia/docker-nginx-mainline)**

----

Nginx stable Docker on CentOS 7

This docker image is part of the **[devilbox](https://github.com/cytopia/devilbox)**

----

## Usage

Start plain

```shell
$ docker run -i -t cytopia/nginx-stable
```


## Options


### Environmental variables

#### Required environmental variables

- None

#### Optional environmental variables

| Variable | Type | Description |
|----------|------|-------------|
| DEBUG_COMPOSE_ENTRYPOINT | bool | Show shell commands executed during start.<br/>Value: `0` or `1` |
| TIMEZONE | string | Set docker OS timezone.<br/>(Example: `Europe/Berlin`) |
| CUSTOM_HTTPD_CONF_DIR | string | Specify a directory inside the docker where Nginx should look for additional config files (`*.conf`).<br/><br/>This will overwrite the default virtual host.<br/><br/>Make sure to mount this directory from your host into the docker. |

### Default mount points

| Docker | Description |
|--------|-------------|
| /var/log/nginx | Nginx log dir |


### Default ports

| Docker | Description |
|--------|-------------|
| 80     | Nginx listening Port |
