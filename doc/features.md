**Features** |
[Environment variables](environment-variables.md) |
[Volumes](volumes.md)

---

# Documentation: Features


## Automated virtual hosts

1. Automated virtual hosts can be enabled by providing `-e MASS_VHOST_ENABLE=1`.
2. You should mount a local project directory into the Docker under `/shared/httpd` (`-v /local/path:/shared/httpd`).
3. You can optionally specify a global server name suffix via e.g.: `-e MASS_VHOST_TLD_SUFFIX=.loc`
4. You can optionally specify a global subdirectory from which the virtual host will servve the documents via e.g.: `-e MASS_VHOST_DOCROOT_DIR=www`
5. Allow the Docker to expose its port via `-p 80:80`.
6. Have DNS names point to the IP address the container runs on (e.g. via `/etc/hosts`)

With the above described settings, whenever you create a local directory under your projects dir
such as `/local/path/mydir`, there will be a new virtual host created by the same name
`http://mydir`. You can also specify a global suffix for the vhost names via
`-e MASS_VHOST_TLD_SUFFIX=.loc`, afterwards your above created vhost would be reachable via
`http://mydir.loc`.

Just to give you a few examples:

**Assumption:** `/local/path` is mounted to `/shared/httpd`

| Directory | `MASS_VHOST_DOCROOT_DIR` | `MASS_VHOST_TLD_SUFFIX` | Serving from <sup>(*)</sup> | Via                  |
|-----------|--------------------------|-------------------------|--------------------------|----------------------|
| work1/    | htdocs/                  |                         | /local/path/work1/htdocs | http://work1         |
| work1/    | www/                     |                         | /local/path/work1/www    | http://work1         |
| work1/    | htdocs/                  | .loc                    | /local/path/work1/htdocs | http://work1.loc     |
| work1/    | www/                     | .loc                    | /local/path/work1/www    | http://work1.loc     |

<sub>(*) This refers to the directory on your host computer</sub>

**Assumption:** `/tmp` is mounted to `/shared/httpd`

| Directory | `MASS_VHOST_DOCROOT_DIR` | `MASS_VHOST_TLD_SUFFIX` | Serving from <sup>(*)</sup> | Via                  |
|-----------|--------------------------|-------------------------|--------------------------|----------------------|
| api/      | htdocs/                  |                         | /tmp/api/htdocs          | http://api           |
| api/      | www/                     |                         | /tmp/api/www             | http://api           |
| api/      | htdocs/                  | .test.com               | /tmp/api/htdocs          | http://api.test.com  |
| api/      | www/                     | .test.com               | /tmp/api/www             | http://api.test.com  |

<sub>(*) This refers to the directory on your host computer</sub>

You would start it as follows:

```shell
docker run -it \
    -p 80:80 \
    -e MASS_VHOST_ENABLE=1 \
    -e MASS_VHOST_DOCROOT_DIR=www \
    -e MASS_VHOST_TLD_SUFFIX=.loc \
    -v /local/path:/shared/httpd \
    devilbox/nginx-stable
```


## Automated PHP-FPM setup

PHP-FPM is not included inside this Docker container, but can be enabled to contact a remote PHP-FPM server. To do so, you must enable it and at least specify the remote PHP-FPM server address (hostname or IP address). Additionally you must mount the data dir under the same path into the PHP-FPM docker container as it is mounted into the web server.

**Note:** When PHP-FPM is enabled, it is enabled for the default virtual host as well as for all other automatically created mass virtual hosts.


## Customization per virtual host

Each virtual host is generated from templates by **[vhost-gen](https://github.com/devilbox/vhost-gen/tree/master/etc/templates)**. As `vhost-gen` is really flexible and allows combining multiple templates, you can copy and alter an existing template and then place it in a subdirectory of your project folder. The subdirectory is specified by `MASS_VHOST_TEMPLATE_DIR`.

**Assumption:** `/local/path` is mounted to `/shared/httpd`

| Directory | `MASS_VHOST_TEMPLATE_DIR` | Templates are then read from <sup>(*)</sup> |
|-----------|------------------|------------------------------|
| work1/    | cfg/             | /local/path/work1/cfg/       |
| api/      | cfg/             | /local/path/api/cfg/         |
| work1/    | conf/            | /local/path/work1/conf/      |
| api/      | conf/            | /local/path/api/conf/        |

<sub>(*) This refers to the directory on your host computer</sub>


## Customization for the default virtual host

The default virtual host can also be overwritten with a custom template. Use `MAIN_VHOST_TEMPLATE_DIR` variable in order to set the subdirectory to look for template files.


## Disabling the default virtual host

If you only want to server you custom projects and don't need the default virtual host, you can disable it by `-e MAIN_VHOST_ENABLE=0`.
