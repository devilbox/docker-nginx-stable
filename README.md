# Nginx stable

[![release](https://img.shields.io/github/release/devilbox/docker-nginx-stable.svg)](https://github.com/devilbox/docker-nginx-stable/releases)
[![Github](https://img.shields.io/badge/github-docker--nginx--stable-red.svg)](https://github.com/devilbox/docker-nginx-stable)
[![lint](https://github.com/devilbox/docker-nginx-stable/workflows/lint/badge.svg)](https://github.com/devilbox/docker-nginx-stable/actions?query=workflow%3Alint)
[![build](https://github.com/devilbox/docker-nginx-stable/workflows/build/badge.svg)](https://github.com/devilbox/docker-nginx-stable/actions?query=workflow%3Abuild)
[![nightly](https://github.com/devilbox/docker-nginx-stable/workflows/nightly/badge.svg)](https://github.com/devilbox/docker-nginx-stable/actions?query=workflow%3Anightly)
[![License](https://img.shields.io/badge/license-MIT-%233DA639.svg)](https://opensource.org/licenses/MIT)

[![Discord](https://img.shields.io/discord/1051541389256704091?color=8c9eff&label=Discord&logo=discord)](https://discord.gg/2wP3V6kBj4)
[![Discourse](https://img.shields.io/discourse/https/devilbox.discourse.group/status.svg?colorB=%234CB697&label=Discourse&logo=discourse)](https://devilbox.discourse.group)


**Available Architectures:**  `amd64`, `arm64`, `386`, `arm/v7`, `arm/v6`

[![](https://img.shields.io/docker/pulls/devilbox/nginx-stable.svg)](https://hub.docker.com/r/devilbox/nginx-stable)

This image is based on the official **[Nginx](https://hub.docker.com/_/nginx)** Docker image and extends it with the ability to have **virtual hosts created automatically**, as well as **adding SSL certificates** when creating new directories. For that to work, it integrates two tools that will take care about the whole process: **[watcherd](https://github.com/devilbox/watcherd)** and **[vhost-gen](https://github.com/devilbox/vhost-gen)**.

From a users perspective, you mount your local project directory into the container under `/shared/httpd`. Any directory then created in your local project directory wil spawn a new virtual host by the same name. Additional settings such as custom server names, PHP-FPM or even different Apache templates per project are supported as well.

**HTTP/2 is enabled by default for all SSL connections.**


> ##### 🐱 GitHub: [devilbox/docker-nginx-stable](https://github.com/devilbox/docker-nginx-stable)

| Current Project  | Reference Implementation |
|:----------------:|:------------------------:|
| <a title="Docker Nginx" href="https://github.com/devilbox/docker-nginx-stable" ><img height="82px" src="https://raw.githubusercontent.com/devilbox/artwork/master/submissions_banner/cytopia/05/png/banner_256_trans.png" /></a> | <a title="Devilbox" href="https://github.com/cytopia/devilbox" ><img height="82px" src="https://raw.githubusercontent.com/devilbox/artwork/master/submissions_banner/cytopia/01/png/banner_256_trans.png" /></a> |
| Streamlined Webserver images | The [Devilbox](https://github.com/cytopia/devilbox) |

**[Apache 2.2](https://github.com/devilbox/docker-apache-2.2) | [Apache 2.4](https://github.com/devilbox/docker-apache-2.4) | Nginx stable | [Nginx mainline](https://github.com/devilbox/docker-nginx-mainline)**

----


## 🐋 Available Docker tags

[![](https://img.shields.io/docker/pulls/devilbox/nginx-stable.svg)](https://hub.docker.com/r/devilbox/nginx-stable)

[`latest`][tag_latest] [`debian`][tag_debian] [`alpine`][tag_alpine]
```bash
docker pull devilbox/nginx-stable
```

[tag_latest]: https://github.com/devilbox/docker-nginx-stable/blob/master/Dockerfiles/Dockerfile.latest
[tag_debian]: https://github.com/devilbox/docker-nginx-stable/blob/master/Dockerfiles/Dockerfile.debian
[tag_alpine]: https://github.com/devilbox/docker-nginx-stable/blob/master/Dockerfiles/Dockerfile.alpine


#### Rolling releases

The following Docker image tags are rolling releases and are built and updated every night.

[![nightly](https://github.com/devilbox/docker-nginx-stable/workflows/nightly/badge.svg)](https://github.com/devilbox/docker-nginx-stable/actions?query=workflow%3Anightly)

| Docker Tag                       | Git Ref      |  Available Architectures                      |
|----------------------------------|--------------|-----------------------------------------------|
| **[`latest`][tag_latest]**       | master       |  `amd64`, `i386`, `arm64`, `arm/v7`, `arm/v6` |
| **[`debian`][tag_debian]**       | master       |  `amd64`, `i386`, `arm64`, `arm/v7`, `arm/v6` |
| **[`alpine`][tag_alpine]**       | master       |  `amd64`, `i386`, `arm64`, `arm/v7`, `arm/v6` |


#### Point in time releases

The following Docker image tags are built once and can be used for reproducible builds. Its version never changes so you will have to update tags in your pipelines from time to time in order to stay up-to-date.

[![build](https://github.com/devilbox/docker-nginx-stable/workflows/build/badge.svg)](https://github.com/devilbox/docker-nginx-stable/actions?query=workflow%3Abuild)

| Docker Tag                       | Git Ref      |  Available Architectures                      |
|----------------------------------|--------------|-----------------------------------------------|
| **[`<tag>`][tag_latest]**        | git: `<tag>` |  `amd64`, `i386`, `arm64`, `arm/v7`, `arm/v6` |
| **[`<tag>-debian`][tag_debian]** | git: `<tag>` |  `amd64`, `i386`, `arm64`, `arm/v7`, `arm/v6` |
| **[`<tag>-alpine`][tag_alpine]** | git: `<tag>` |  `amd64`, `i386`, `arm64`, `arm/v7`, `arm/v6` |

> 🛈 Where `<tag>` refers to the chosen git tag from this repository.


## ✰ Features

### Automated virtual hosts

1. Automated virtual hosts can be enabled by providing `-e MASS_VHOST_ENABLE=1`.
2. You should mount a local project directory into the Docker under `/shared/httpd` (`-v /local/path:/shared/httpd`).
3. You can optionally specify a global server name suffix via e.g.: `-e MASS_VHOST_TLD=.loc`
4. You can optionally specify a global subdirectory from which the virtual host will servve the documents via e.g.: `-e MASS_VHOST_DOCROOT=www`
5. Allow the Docker to expose its port via `-p 80:80`.
6. Have DNS names point to the IP address the container runs on (e.g. via `/etc/hosts`)

With the above described settings, whenever you create a local directory under your projects dir
such as `/local/path/mydir`, there will be a new virtual host created by the same name
`http://mydir`. You can also specify a global suffix for the vhost names via
`-e MASS_VHOST_TLD=.loc`, afterwards your above created vhost would be reachable via
`http://mydir.loc`.

Just to give you a few examples:

**Assumption:** `/local/path` is mounted to `/shared/httpd`

| Directory | `MASS_VHOST_DOCROOT` | `MASS_VHOST_TLD` | Serving from <sup>(*)</sup> | Via                  |
|-----------|----------------------|------------------|--------------------------|----------------------|
| work1/    | htdocs/              |                  | /local/path/work1/htdocs | http://work1         |
| work1/    | www/                 |                  | /local/path/work1/www    | http://work1         |
| work1/    | htdocs/              | .loc             | /local/path/work1/htdocs | http://work1.loc     |
| work1/    | www/                 | .loc             | /local/path/work1/www    | http://work1.loc     |

<sub>(*) This refers to the directory on your host computer</sub>

**Assumption:** `/tmp` is mounted to `/shared/httpd`

| Directory | `MASS_VHOST_DOCROOT` | `MASS_VHOST_TLD` | Serving from <sup>(*)</sup> | Via                  |
|-----------|----------------------|------------------|--------------------------|----------------------|
| api/      | htdocs/              |                  | /tmp/api/htdocs          | http://api           |
| api/      | www/                 |                  | /tmp/api/www             | http://api           |
| api/      | htdocs/              | .test.com        | /tmp/api/htdocs          | http://api.test.com  |
| api/      | www/                 | .test.com        | /tmp/api/www             | http://api.test.com  |

<sub>(*) This refers to the directory on your host computer</sub>

You would start it as follows:

```shell
docker run -it \
    -p 80:80 \
    -e MASS_VHOST_ENABLE=1 \
    -e MASS_VHOST_DOCROOT=www \
    -e MASS_VHOST_TLD=.loc \
    -v /local/path:/shared/httpd \
    devilbox/nginx-stable
```

### Customization per virtual host

Each virtual host is generated from templates by **[vhost-gen](https://github.com/devilbox/vhost-gen/tree/master/etc/templates)**. As `vhost-gen` is really flexible and allows combining multiple templates, you can copy and alter an existing template and then place it in a subdirectory of your project folder. The subdirectory is specified by `MASS_VHOST_TPL`.

**Assumption:** `/local/path` is mounted to `/shared/httpd`

| Directory | `MASS_VHOST_TPL` | Templates are then read from <sup>(*)</sup> |
|-----------|------------------|------------------------------|
| work1/    | cfg/             | /local/path/work1/cfg/       |
| api/      | cfg/             | /local/path/api/cfg/         |
| work1/    | conf/            | /local/path/work1/conf/      |
| api/      | conf/            | /local/path/api/conf/        |

<sub>(*) This refers to the directory on your host computer</sub>

### Customizing the default virtual host

The default virtual host can also be overwritten with a custom template. Use `MAIN_VHOST_TPL` variable in order to set the subdirectory to look for template files.

### PHP-FPM setup automation

PHP-FPM is not included inside this Docker container, but can be enabled to contact a remote PHP-FPM server. To do so, you must enable it and at least specify the remote PHP-FPM server address (hostname or IP address). Additionally you must mount the data dir under the same path into the PHP-FPM docker container as it is mounted into the web server.

**Note:** When PHP-FPM is enabled, it is enabled for the default virtual host as well as for all other automatically created mass virtual hosts.

### Disabling the default virtual host

If you only want to server you custom projects and don't need the default virtual host, you can disable it by `-e MAIN_VHOST_ENABLE=0`.



## ∑ Environment Variables

This Docker container adds a lot of injectables in order to customize it to your needs. See the table below for a detailed description.

### Required environmental variables

`PHP_FPM_SERVER_ADDR` is required when enabling PHP FPM.

### Optional environmental variables (nginx)

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `WORKER_CONNECTIONS` | int    | `1024`    | [worker_connections](https://nginx.org/en/docs/ngx_core_module.html#worker_connections) |
| `WORKER_PROCESSES`   | int or `auto` | `auto`  | [worker_processes](https://nginx.org/en/docs/ngx_core_module.html#worker_processes) |

### Optional environmental variables (general)

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `DEBUG_ENTRYPOINT`    | int    | `0`     | Show settings and shell commands executed during startup.<br/>Values:<br/>`0`: Off<br/>`1`: Show settings<br/>`2`: Show settings and commands |
| `DEBUG_RUNTIME`       | bool   | `0`     | Be verbose during runtime.<br/>Value: `0` or `1` |
| `DOCKER_LOGS`         | bool   | `0`     | When set to `1` will redirect error and access logs to Docker logs (`stderr` and `stdout`) instead of file inside container.<br/>Value: `0` or `1` |
| `TIMEZONE`            | string | `UTC`   | Set docker OS timezone.<br/>(Example: `Europe/Berlin`) |
| `NEW_UID`             | int    | `101`   | Assign the default Nginx user a new UID. This is useful if you you mount your document root and want to match the file permissions to the one of your local user. Set it to your host users uid (see `id` for your uid). |
| `NEW_GID`             | int    | `101`   | This is useful if you you mount your document root and want to match the file permissions to the one of your local user group. Set it to your host user groups gid (see `id` for your gid). |
| `PHP_FPM_ENABLE`      | bool   | `0`     | Enable PHP-FPM for the default vhost and the mass virtual hosts. |
| `PHP_FPM_SERVER_ADDR` | string | ``      | IP address or hostname of remote PHP-FPM server.<br/><strong>Required when enabling PHP.</strong> |
| `PHP_FPM_SERVER_PORT` | int    | `9000`  | Port of remote PHP-FPM server |
| `PHP_FPM_TIMEOUT`     | int    | `180`   | Timeout in seconds to upstream PHP-FPM server |
| `HTTP2_ENABLE`        | int    | `1`     | Enabled or disabled HTTP2 support.<br/>Values:<br/>`0`: Disabled<br/>`1`: Enabled<br/>Defaults to Enabled |

### Optional environmental variables (default vhost)

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `MAIN_VHOST_ENABLE`  | bool   | `1`     | By default there is a standard (catch-all) vhost configured to accept requests served from `/var/www/default/htdocs`. If you want to disable it, set the value to `0`.<br/><strong>Note:</strong>The `htdocs` dir name can be changed with `MAIN_VHOST_DOCROOT`. See below. |
| `MAIN_VHOST_SSL_TYPE` | string | `plain` | <ul><li><code>plain</code> - only serve via http</li><li><code>ssl</code> - only serve via https</li><li><code>both</code> - serve via http and https</li><li><code>redir</code> - serve via https and redirect http to https</li></ul> |
| `MAIN_VHOST_SSL_GEN` | bool | `0` | `0`: Do not generate an ssl certificate<br/> `1`: Generate self-signed certificate automatically |
| `MAIN_VHOST_SSL_CN`  | string | `localhost` | Comma separated list of CN names for SSL certificate generation (The domain names by which you want to reach the default server) |
| `MAIN_VHOST_DOCROOT`  | string | `htdocs`| This is the directory name appended to `/var/www/default/` from which the default virtual host will serve its files.<br/><strong>Default:</strong><br/>`/var/www/default/htdocs`<br/><strong>Example:</strong><br/>`MAIN_VHOST_DOCROOT=www`<br/>Doc root: `/var/www/default/www` |
| `MAIN_VHOST_TPL`      | string | `cfg`   | Directory within th default vhost base path (`/var/www/default`) to look for templates to overwrite virtual host settings. See [vhost-gen](https://github.com/devilbox/vhost-gen/tree/master/etc/templates) for available template files.<br/><strong>Resulting default path:</strong><br/>`/var/www/default/cfg` |
| `MAIN_VHOST_STATUS_ENABLE` | bool | `0`  | Enable httpd status page. |
| `MAIN_VHOST_STATUS_ALIAS`  | string | `/httpd-status` | Set the alias under which the httpd server should serve its status page. |

### Optional environmental variables (mass vhosts)

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `MASS_VHOST_ENABLE`   | bool   | `0`     | You can enable mass virtual hosts by setting this value to `1`. Mass virtual hosts will be created for each directory present in `/shared/httpd` by the same name including a top-level domain suffix (which could also be a domain+tld). See `MASS_VHOST_TLD` for how to set it. |
| `MASS_VHOST_SSL_TYPE` | string | `plain` | <ul><li><code>plain</code> - only serve via http</li><li><code>ssl</code> - only serve via https</li><li><code>both</code> - serve via http and https</li><li><code>redir</code> - serve via https and redirect http to https</li></ul> |
| `MASS_VHOST_SSL_GEN` | bool | `0` | `0`: Do not generate an ssl certificate<br/> `1`: Generate self-signed certificate automatically |
| `MASS_VHOST_TLD`      | string | `.loc`| This string will be appended to the server name (which is built by its directory name) for mass virtual hosts and together build the final domain.<br/><strong>Default:</strong>`<project>.loc`<br/><strong>Example:</strong><br/>Path: `/shared/httpd/temp`<br/>`MASS_VHOST_TLD=.lan`<br/>Server name: `temp.lan`<br/><strong>Example:</strong><br/>Path:`/shared/httpd/api`<br/>`MASS_VHOST_TLD=.example.com`<br/>Server name: `api.example.com` |
| `MASS_VHOST_DOCROOT`  | string | `htdocs`| This is a subdirectory within your project dir under each project from which the web server will serve its files.<br/>`/shared/httpd/<project>/$MASS_VHOST_DOCROOT/`<br/><strong>Default:</strong><br/>`/shared/httpd/<project>/htdocs/` |
| `MASS_VHOST_TPL`      | string | `cfg`   | Directory within your new virtual host to look for templates to overwrite virtual host settings. See [vhost-gen](https://github.com/devilbox/vhost-gen/tree/master/etc/templates) for available template files.<br/>`/shared/httpd/<project>/$MASS_VHOST_TPL/`<br/><strong>Resulting default path:</strong><br/>`/shared/httpd/<project>/cfg/` |


## 📂 Volumes

| Docker                | Description |
|-----------------------|-------------|
| `/etc/httpd-custom.d/` | Mount this directory to add outside configuration files (`*.conf`) to Nginx |
| `/var/www/default/`    | Nginx default virtual host base path (contains by default `htdocs/` and `cfg/` |
| `/shared/httpd/`       | Nginx mass virtual host root directory |
| `/etc/vhost-gen.d/`    | [vhost-gen](https://github.com/devilbox/vhost-gen) directory for custom templates. Copy and customize [nginx.yml](https://github.com/devilbox/vhost-gen/blob/master/etc/templates/nginx.yml) into this mounted directory for global vhost customizations |


## 🖧 Exposed Ports

| Docker | Description |
|--------|-------------|
| 80     | HTTP listening Port |
| 443    | HTTPS listening Port |


## 💡 Examples

### 1. Serve static files

Mount your local directort `~/my-host-www` into the docker and server those files.

**Note:** Files will be server from `~/my-host-www/htdocs`.
```bash
$ docker run -d -p 80:80 -v ~/my-host-www:/var/www/default -t devilbox/nginx-stable
```

### 2. Serve PHP files with PHP-FPM

Note, for this to work, the `~/my-host-www` dir must be mounted into the Nginx Docker as well as into the php-fpm docker.

You can also attach other PHP-FPM version: [PHP-FPM 5.4](https://github.com/cytopia/docker-php-fpm-5.4), [PHP-FPM 5.5](https://github.com/cytopia/docker-php-fpm-5.5), [PHP-FPM 5.6](https://github.com/cytopia/docker-php-fpm-5.6), [PHP-FPM 7.0](https://github.com/cytopia/docker-php-fpm-7.0), [PHP-FPM 7.1](https://github.com/cytopia/docker-php-fpm-7.1), [PHP-FPM 7.2](https://github.com/cytopia/docker-php-fpm-7.2) or [HHVM](https://github.com/cytopia/docker-hhvm-latest).

Each PHP-FPM docker also has the option to enable Xdebug and more, see their respective Readme files for futher settings.

```bash
# Start the PHP-FPM docker, mounting the same diectory
$ docker run -d -p 9000 -v ~/my-host-www:/var/www/default --name php cytopia/php-fpm-5.6

# Start the Nginx Docker, linking it to the PHP-FPM docker
$ docker run -d \
    -p 80:80 \
    -v ~/my-host-www:/var/www/default \
    -e PHP_FPM_ENABLE=1 \
    -e PHP_FPM_SERVER_ADDR=php \
    -e PHP_FPM_SERVER_PORT=9000 \
    --link php \
    -t devilbox/nginx-stable
```

### 3. Fully functional LEMP stack

Same as above, but also add a MySQL docker and link it into Nginx.
```bash
# Start the MySQL docker
$ docker run -d \
    -p 3306:3306 \
    -e MYSQL_ROOT_PASSWORD=my-secret-pw \
    --name mysql \
    -t cytopia/mysql-5.5

# Start the PHP-FPM docker, mounting the same diectory.
# Also make sure to
#   forward the remote MySQL port 3306 to 127.0.0.1:3306 within the
#   PHP-FPM docker in order to be able to use `127.0.0.1` for mysql
#   connections from within the php docker.
$ docker run -d \
    -p 9000:9000 \
    -v ~/my-host-www:/var/www/default \
    -e FORWARD_PORTS_TO_LOCALHOST=3306:mysql:3306 \
    --name php \
    cytopia/php-fpm-5.6

# Start the Nginx Docker, linking it to the PHP-FPM docker
$ docker run -d \
    -p 80:80 \
    -v ~/my-host-www:/var/www/default \
    -e PHP_FPM_ENABLE=1 \
    -e PHP_FPM_SERVER_ADDR=php \
    -e PHP_FPM_SERVER_PORT=9000 \
    --link php \
    --link mysql \
    -t devilbox/nginx-stable
```

### 4. Docker Compose reference implementation

If you want a fully functional Docker Compose setup, which allows to switch PHP versions easily, comes with web servers, database servers and much more, then head over to the **[Devilbox](https://github.com/cytopia/devilbox)** rerefence implementation :

| Reference Implementation |
|--------------------------|
| <a title="Devilbox" href="https://github.com/cytopia/devilbox" ><img title="Devilbox" height="82px" src="https://raw.githubusercontent.com/devilbox/artwork/master/submissions_banner/cytopia/01/png/banner_256_trans.png" /></a> |


## 🖤 Sister Projects

Show some love for the following sister projects.

<table>
 <tr>
  <th>🖤 Project</th>
  <th>🐱 GitHub</th>
  <th>🐋 DockerHub</th>
 </tr>
 <tr>
  <td><a title="Devilbox" href="https://github.com/cytopia/devilbox" ><img width="256px" src="https://raw.githubusercontent.com/devilbox/artwork/master/submissions_banner/cytopia/01/png/banner_256_trans.png" /></a></td>
  <td><a href="https://github.com/cytopia/devilbox"><code>Devilbox</code></a></td>
  <td></td>
 </tr>
 <tr>
  <td><a title="Docker PHP-FMP" href="https://github.com/devilbox/docker-php-fpm" ><img width="256px" src="https://raw.githubusercontent.com/devilbox/artwork/master/submissions_banner/cytopia/02/png/banner_256_trans.png" /></a></td>
  <td><a href="https://github.com/devilbox/docker-php-fpm"><code>docker-php-fpm</code></a></td>
  <td><a href="https://hub.docker.com/r/devilbox/php-fpm"><code>devilbox/php-fpm</code></a></td>
 </tr>
 <tr>
  <td><a title="Docker PHP-FMP-Community" href="https://github.com/devilbox/docker-php-fpm-community" ><img width="256px" src="https://raw.githubusercontent.com/devilbox/artwork/master/submissions_banner/cytopia/03/png/banner_256_trans.png" /></a></td>
  <td><a href="https://github.com/devilbox/docker-php-fpm-community"><code>docker-php-fpm-community</code></a></td>
  <td><a href="https://hub.docker.com/r/devilbox/php-fpm-community"><code>devilbox/php-fpm-community</code></a></td>
 </tr>
 <tr>
  <td><a title="Docker MySQL" href="https://github.com/devilbox/docker-mysql" ><img width="256px" src="https://raw.githubusercontent.com/devilbox/artwork/master/submissions_banner/cytopia/04/png/banner_256_trans.png" /></a></td>
  <td><a href="https://github.com/devilbox/docker-mysql"><code>docker-mysql</code></a></td>
  <td><a href="https://hub.docker.com/r/devilbox/mysql"><code>devilbox/mysql</code></a></td>
 </tr>
 <tr>
  <td><img width="256px" src="https://raw.githubusercontent.com/devilbox/artwork/master/submissions_banner/cytopia/05/png/banner_256_trans.png" /></td>
  <td>
   <a href="https://github.com/devilbox/docker-apache-2.2"><code>docker-apache-2.2</code></a><br/>
   <a href="https://github.com/devilbox/docker-apache-2.4"><code>docker-apache-2.4</code></a><br/>
   <a href="https://github.com/devilbox/docker-nginx-stable"><code>docker-nginx-stable</code></a><br/>
   <a href="https://github.com/devilbox/docker-nginx-mainline"><code>docker-nginx-mainline</code></a>
  </td>
  <td>
   <a href="https://hub.docker.com/r/devilbox/apache-2.2"><code>devilbox/apache-2.2</code></a><br/>
   <a href="https://hub.docker.com/r/devilbox/apache-2.4"><code>devilbox/apache-2.4</code></a><br/>
   <a href="https://hub.docker.com/r/devilbox/nginx-stable"><code>devilbox/nginx-stable</code></a><br/>
   <a href="https://hub.docker.com/r/devilbox/nginx-mainline"><code>devilbox/nginx-mainline</code></a>
  </td>
 </tr>
</table>


## 👫 Community

In case you seek help, go and visit the community pages.

<table width="100%" style="width:100%; display:table;">
 <thead>
  <tr>
   <th width="33%" style="width:33%;"><h3><a target="_blank" href="https://devilbox.readthedocs.io">📘	Documentation</a></h3></th>
   <th width="33%" style="width:33%;"><h3><a target="_blank" href="https://discord.gg/2wP3V6kBj4">🎮 Discord</a></h3></th>
   <th width="33%" style="width:33%;"><h3><a target="_blank" href="https://devilbox.discourse.group">🗪 Forum</a></h3></th>
  </tr>
 </thead>
 <tbody style="vertical-align: middle; text-align: center;">
  <tr>
   <td>
    <a target="_blank" href="https://devilbox.readthedocs.io">
     <img title="Documentation" name="Documentation" src="https://raw.githubusercontent.com/cytopia/icons/master/400x400/readthedocs.png" />
    </a>
   </td>
   <td>
    <a target="_blank" href="https://discord.gg/2wP3V6kBj4">
     <img title="Chat on Discord" name="Chat on Discord" src="https://raw.githubusercontent.com/cytopia/icons/master/400x400/discord.png" />
    </a>
   </td>
   <td>
    <a target="_blank" href="https://devilbox.discourse.group">
     <img title="Devilbox Forums" name="Forum" src="https://raw.githubusercontent.com/cytopia/icons/master/400x400/discourse.png" />
    </a>
   </td>
  </tr>
  <tr>
  <td><a target="_blank" href="https://devilbox.readthedocs.io">devilbox.readthedocs.io</a></td>
  <td><a target="_blank" href="https://discord.gg/2wP3V6kBj4">discord/devilbox</a></td>
  <td><a target="_blank" href="https://devilbox.discourse.group">devilbox.discourse.group</a></td>
  </tr>
 </tbody>
</table>


## 🧘 Maintainer

**[@cytopia](https://github.com/cytopia)**

I try to keep up with literally **over 100 projects** besides a full-time job.
If my work is making your life easier, consider contributing. 🖤

* [GitHub Sponsorship](https://github.com/sponsors/cytopia)
* [Patreon](https://www.patreon.com/devilbox)
* [Open Collective](https://opencollective.com/devilbox)

**Findme:**
**🐱** [cytopia](https://github.com/cytopia) / [devilbox](https://github.com/devilbox) |
**🐋** [cytopia](https://hub.docker.com/r/cytopia/) / [devilbox](https://hub.docker.com/r/devilbox/) |
**🐦** [everythingcli](https://twitter.com/everythingcli) / [devilbox](https://twitter.com/devilbox) |
**📖** [everythingcli.org](http://www.everythingcli.org/)

**Contrib:** PyPI: [cytopia](https://pypi.org/user/cytopia/) **·**
Terraform: [cytopia](https://registry.terraform.io/namespaces/cytopia) **·**
Ansible: [cytopia](https://galaxy.ansible.com/cytopia)


## 🗎 License

**[MIT License](LICENSE)**

Copyright (c) 2016 [cytopia](https://github.com/cytopia)
