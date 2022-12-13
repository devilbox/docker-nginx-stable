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

| Web Server Project  | Reference Implementation |
|:-------------------:|:------------------------:|
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

> 🛈 Where `<tag>` refers to the chosen git tag from this repository.<br/>
> ⚠ **Warning:** The latest available git tag is also build every night and considered a rolling tag.


## ✰ Features

### Automated virtual hosts

> 🛈 For details see **[Features: Automated virtual hosts](doc/features.md#automated-virtual-hosts)**


### Automated SSL certificate generation

> 🛈 For details see **[Features: Automated SSL certificate generation](doc/features.md#automated-ssl-certificate-generation)

### Automatically trusted HTTPS

> 🛈 For details see **[Features: Automatically trusted HTTPS](doc/features.md#automatically-trusted-https)**

### Customization per virtual host

> 🛈 For details see **[Features: Customization per virtual host](doc/features.md#customization-per-virtual-host)**

### Customization for the default virtual host

> 🛈 For details see **[Features: Customization for the default virtual host](doc/features.md#customization-for-the-default-virtual-host)**

### Automated PHP-FPM setup

> 🛈 For details see **[Features: Automated PHP-FPM setup](doc/features.md#automated-php-fpm-setup)**

### Local file system permission sync

> 🛈 For details see **[Features: Local file system permission sync](doc/features.md#local-file-system-permission-sync)**



## ∑ Environment Variables

The provided Docker images add a lot of injectables in order to customize it to your needs. See the table below for a brief overview.

> 🛈 For details see **[Documentation: Environment variables](doc/environment-variables.md)**

<table>
 <tr>
  <th>Nginx</th>
  <th>Logging</th>
  <th>Features</th>
 </tr>
 <tr style="vertical-align:top">
  <td>
   <code>WORKER_CONNECTIONS</code><br/>
   <code>WORKER_PROCESSES</code><br/>
   <code>HTTP2_ENABLE</code><br/>
  </td>
  <td>
   <code>DEBUG_ENTRYPOINT</code><br/>
   <code>DEBUG_RUNTIME</code><br/>
   <code>DOCKER_LOGS</code><br/>
  </td>
  <td>
   <code>TIMEZONE</code><br/>
   <code>NEW_UID</code><br/>
   <code>NEW_GID</code><br/>
  </td>
 </tr>
 <tr>
  <th>Main vHost</th>
  <th>Mass vHost</th>
  <th>PHP</th>
 </tr>
 <tr style="vertical-align:top">
  <td>
   <code>MAIN_VHOST_ENABLE</code><br/>
   <code>MAIN_VHOST_SSL_TYPE</code><br/>
   <code>MAIN_VHOST_SSL_GEN</code><br/>
   <code>MAIN_VHOST_SSL_CN</code><br/>
   <code>MAIN_VHOST_DOCROOT</code><br/>
   <code>MAIN_VHOST_TPL</code><br/>
   <code>MAIN_VHOST_STATUS_ENABLE</code><br/>
   <code>MAIN_VHOST_STATUS_ALIAS</code><br/>
  </td>
  <td>
   <code>MASS_VHOST_ENABLE</code><br/>
   <code>MASS_VHOST_SSL_TYPE</code><br/>
   <code>MASS_VHOST_SSL_GEN</code><br/>
   <code>MASS_VHOST_TLD</code><br/>
   <code>MASS_VHOST_DOCROOT</code><br/>
   <code>MASS_VHOST_TPL</code><br/>
  </td>
  <td>
   <code>PHP_FPM_ENABLE</code><br/>
   <code>PHP_FPM_SERVER_ADDR</code><br/>
   <code>PHP_FPM_SERVER_PORT</code><br/>
   <code>PHP_FPM_TIMEOUT</code><br/>
  </td>
 </tr>
</table>


## 📂 Volumes

> 🛈 For details see **[Documentation: Volumes](doc/volumes.md)**

| Docker                 | Short description |
|------------------------|-------------------|
| `/etc/httpd-custom.d/` | Nginx `*.conf` configs |
| `/var/www/default/`    | Default virtual host base path |
| `/shared/httpd/`       | Mass virtual host root directory |
| `/etc/vhost-gen.d/`    | [vhost-gen](https://github.com/devilbox/vhost-gen) directory |


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

| PHP-FPM Reference Images |
|--------------------------|
| <a title="PHP-FPM Reference Images" href="https://github.com/devilbox/docker-php-fpm" ><img title="Devilbox" height="82px" src="https://raw.githubusercontent.com/devilbox/artwork/master/submissions_banner/cytopia/02/png/banner_256_trans.png" /></a> |

Each PHP-FPM container also has the option to enable Xdebug and more, see their respective Readme files for futher settings.

```bash
# Start the PHP-FPM docker, mounting the same diectory
$ docker run -d -p 9000 -v ~/my-host-www:/var/www/default --name php devilbox/php-fpm:5.6-prod

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
    -t devilbox/mysql:mysql-5.5

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
    devilbox/php-fpm:5.6-prod

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
