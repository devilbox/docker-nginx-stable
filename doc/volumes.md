[Features](features.md) |
[Environment variables](environment-variables.md) |
**Volumes**

---

# Documentation: Volumes


## 📂 `/var/www/default/`

* **type:** data directory
* **purpose:** website files for the default virtual host

Files in this directory are used to serve the default virtual host.

Mount this directory to your local file system in order to add html, js, php, etc files and edit them with your local IDE/editor.

**Note:** You can disable the default virtual host and then don't need to mount this directory.

```bash
docker run -d -it \
    -v $(pwd)/default:/var/www/default \
    -e MAIN_VHOST_ENABLE=1 \
    devilbox/nginx-stable
```


## 📂 `/shared/httpd/`

* **type:** data directory
* **purpose:** website files for the mass virtual hosts (your projects)

This directory contains all your projects. When a new directory is created inside this directory, a new virtual host is automatically created by the web server.

Mount this directory to your local file system in order to add html, js, php, etc files and edit them with your local IDE/editor.

**Note:** You can disable mass virtual hosts and then don't need to mount this directory.

```bash
docker run -d -it \
    -v $(pwd)/projects:/shared/httpd \
    -e MASS_VHOST_ENABLE=1 \
    devilbox/nginx-stable
```


## 📂 `/ca/`

* **type:** data directory
* **purpose:** populated with CA certificate files

This directory will be populated by a Certificate Authority, which signs every vhost SSL certificate. If you want to have valid SSL in your browser for every current and future project, simply import the CA files into your browser and/or system.

**Note:** CA files are not being regenerated if they already exist. You could also place your own CA files in here.


## 📂 `/etc/httpd-custom.d/`

* **type:** config directory
* **purpose:** Add `*.conf` files to alter the webserver behaviour

Mount this directory to your local file system and add any valid `*.conf` files to alter the web server behaviour.


## 📂 `/etc/vhost-gen.d/`

* **type:** config directory
* **purpose:** Add [vhost-gen](https://github.com/devilbox/vhost-gen) templates to alter the webserver behaviour

Copy and customize [nginx.yml](https://github.com/devilbox/vhost-gen/blob/master/etc/templates/nginx.yml) into this mounted directory for global vhost customizations.
