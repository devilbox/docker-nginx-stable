[Features](features.md) |
**Environment variables** |
[Volumes](volumes.md)

---

# Documentation: Environment Variables


This Docker container adds a lot of injectables in order to customize it to your needs. See the table below for a detailed description.

## Required environmental variables

`PHP_FPM_SERVER_ADDR` is required when enabling PHP FPM.


## Optional environmental variables (nginx)

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `WORKER_CONNECTIONS` | int    | `1024`    | [worker_connections](https://nginx.org/en/docs/ngx_core_module.html#worker_connections) |
| `WORKER_PROCESSES`   | int or `auto` | `auto`  | [worker_processes](https://nginx.org/en/docs/ngx_core_module.html#worker_processes) |


## Optional environmental variables (general)

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


## Optional environmental variables (default vhost)

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


## Optional environmental variables (mass vhosts)

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `MASS_VHOST_ENABLE`   | bool   | `0`     | You can enable mass virtual hosts by setting this value to `1`. Mass virtual hosts will be created for each directory present in `/shared/httpd` by the same name including a top-level domain suffix (which could also be a domain+tld). See `MASS_VHOST_TLD` for how to set it. |
| `MASS_VHOST_SSL_TYPE` | string | `plain` | <ul><li><code>plain</code> - only serve via http</li><li><code>ssl</code> - only serve via https</li><li><code>both</code> - serve via http and https</li><li><code>redir</code> - serve via https and redirect http to https</li></ul> |
| `MASS_VHOST_SSL_GEN` | bool | `0` | `0`: Do not generate an ssl certificate<br/> `1`: Generate self-signed certificate automatically |
| `MASS_VHOST_TLD`      | string | `.loc`| This string will be appended to the server name (which is built by its directory name) for mass virtual hosts and together build the final domain.<br/><strong>Default:</strong>`<project>.loc`<br/><strong>Example:</strong><br/>Path: `/shared/httpd/temp`<br/>`MASS_VHOST_TLD=.lan`<br/>Server name: `temp.lan`<br/><strong>Example:</strong><br/>Path:`/shared/httpd/api`<br/>`MASS_VHOST_TLD=.example.com`<br/>Server name: `api.example.com` |
| `MASS_VHOST_DOCROOT`  | string | `htdocs`| This is a subdirectory within your project dir under each project from which the web server will serve its files.<br/>`/shared/httpd/<project>/$MASS_VHOST_DOCROOT/`<br/><strong>Default:</strong><br/>`/shared/httpd/<project>/htdocs/` |
| `MASS_VHOST_TPL`      | string | `cfg`   | Directory within your new virtual host to look for templates to overwrite virtual host settings. See [vhost-gen](https://github.com/devilbox/vhost-gen/tree/master/etc/templates) for available template files.<br/>`/shared/httpd/<project>/$MASS_VHOST_TPL/`<br/><strong>Resulting default path:</strong><br/>`/shared/httpd/<project>/cfg/` |
