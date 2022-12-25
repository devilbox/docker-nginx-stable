**Architecture** |
[Features](features.md) |
[Examples](examples.md) |
[Environment variables](environment-variables.md) |
[Volumes](volumes.md)

---

# Documentation: Architecture

1. [Tools](#-tools)
2. [Execution Chain](#-execution-chain)
3. [Directories and files](#-directories-and-files)


## 👷 Tools

This project is using four core tools that interact with each other in order to achieve automated project-based mass virtual hosting with HTTPS support from SSL certificates signed by an internal CA.

| Tool | Usage |
|------|-------|
| [`vhost-gen`](https://github.com/devilbox/vhost-gen) | An arbitrary vhost generator for Nginx (mainline and stable), Apache 2.2 and Apache 2.4 to ensure one config generates the same vhost functionality independently of underlying webserver |
| [`cert-gen`](https://github.com/devilbox/cert-gen)   | A tool to generate and validate Certificate Authorities and SSL certificates which are signed by a Certificate Authority |
| [`watcherd`](https://github.com/devilbox/watcherd)   | A file system change detecter (`inotify`-based or `bash`-based), which acts on changes (`add` or `delete` of directories in this case) with custom commands and offers a trigger command on change. (in this configuration, it will call `vhost-gen`, when a new directory is added in order to make the mass vhost possible. It will call a generic `rm ...` commad for a `delete` and restarts the webserver as its trigger command. |
| [`supervisord`](http://supervisord.org/)             | A daemon that manages the run-time of multiple other daemons. In this case it ensures that `watcherd` and the webserver are up and running. |



## 👷 Execution Chain

This is the execution chain for how the mass virtual hosting or single vhost is achieved:
```bash
       # mass-vhost                                     # main-vhost only
       docker-entrypoint.sh                             docker-entrypoint.sh
                |                                                |
                ↓                                                ↓
           supervisord (pid 1)                                 httpd (pid 1)
          /     |
         /      |
       ↙        ↓
  start       start
  httpd      watcherd
            /    |    \
           /     |     \
          ↓      ↓      ↘
        sgn     rm      create-vhost.sh
       httpd   vhost     |           |
                         |           |
                         ↓           ↓
                      cert-gen    vhost-gen ⭢ generate vhost
```

### The basics

1. The `docker-entrypoint.sh` script sets and validates given options
2. It then passes over to `supervisord` via `exec`
3. `supervisord` ensures the web server is running
4. `supervisord` ensures `watcherd` is running
5. `watcherd` listens for file system changed (directory created or directory removed)<sup>\[1\]</sup>

> **\[1\]** A renamed directory is: directory removed and directory created

### What does `watcherd` do?

* `watcherd` is setup with two events:
    * event: directory created
    * event: directory removed
* `watcherd` is setup with two event actions (one for each event):
    * directory created: call `create-vhost.sh`
    * directory removed: remove webserver vhost config for this project
* `watcherd` is setup with one *trigger* that acts after any event action has been executed:
    * send a reload or stop signal to  webserver

So in simple terms, when `watcherd` detects that a new directory was created, it calls `create-vhost.sh` and sends a reload or stop signal to the webserver. In case the webserver will shutdown gracefully, it will immediately be started by `supervisord`. In both cases, the new webserver configuration will be applied.<br/>
When `watcherd` detects that a directory was removed, it will remove the corresponding webserver vhost configuration file and send a reload or stop signal to the webserver (In case of a stop signal, `supervisord` will again ensure the webserver will come up).

### What does `create-vhost.sh` do?

`create-vhost.sh` is a minimalistic run-time version of the entrypoint script and does thorough validation on anything that could not be validated during startup-time. Additionally it does the following:

* `create-vhost.sh` will generate SSL certificates (signed by internal CA) via `cert-gen`
* `create-vhost.sh` will generate a customized `vhost-gen` configuration file
* `create-vhost.sh` will move any custom `vhost-gen` templates into place
* `create-vhost.sh` will passes over to `vhost-gen`, which will then generate a virtual host configuration file.

Once `vhost-gen` is done, the execution cycle is returned to `watcherd`, which will apply its trigger.




## 👷 Directories and files

To get some insights on the internals, here is an overview about all directory paths and files that are being used:

| Directories / Files              | Description |
|----------------------------------|-------------|
| `/var/www/default/`              | Main Vhost base directory |
| `/shared/httpd/`                 | Mass Vhost base directory |
| `/ca/`                           | Directory where generated Certificate Authoriy will be placed (You can mount this and place your own, if you prefer to use another one) |
| `/etc/httpd/cert/`               | Directory where Vhost SSL certificates and keys are stored |
| `/etc/httpd/conf.d/`             | Webserer configuration directory: Stores main vhost configuration file |
| `/etc/httpd/vhost.d/`            | Webserver configuration directory: Stores mass vhost configuration files |
| `/etc/httpd-custom.d/`           | Webserver configuration directory: Mount this and place your custom webserver configuration files in here |
| `/var/logs/httpd/`               | Webserver log directory |
| `/etc/vhost-gen/`                | Directory for [vhost-gen](https://github.com/devilbox/vhost-gen/): contains its default configuration (placed during install time) |
| `/etc/vhost-gen.d/`              | Directory for [vhost-gen](https://github.com/devilbox/vhost-gen/): mount this and place custom `vhost-gen` templates to override `vhost-gen`'s behaviour. Templates can be found: [here](https://github.com/devilbox/vhost-gen/tree/master/etc/templates) |
| [`/docker-entrypoint.sh`](../Dockerfiles/data/docker-entrypoint.sh)   | Entrypoint script that will be executed by the container during startup |
| `/docker-entrypoint.d/`          | Entrypoint validators and functions that are used by `/docker-entrypoint.sh` |
| [`/etc/supervisord.conf`](../Dockerfiles/data/docker-entrypoint.d/15-supervisord.sh) | Supervisord coniguration file. Supervisord will only be started, whenn `MASS_VHOST_ENABLE` is set to `1` |
| [`/usr/local/bin/create-vhost.sh`](../Dockerfiles/data/create-vhost.sh) | A wrapper script to create a vhost (validation, ssl certificates and calls `vhost-gen` |
