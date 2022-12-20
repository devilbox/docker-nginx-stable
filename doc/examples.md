[Features](features.md) |
**Examples]** |
[Environment variables](environment-variables.md) |
[Volumes](volumes.md)

---

# Documentation: Examples


1. [Serve static files](#-serve-staticfiles)
2. [Serve PHP files with PHP-FPM](#-serve-php-files-with-php-fpm)
3. [Serve PHP files with PHP-FPM and sync local permissions](#-serve-php-files-with-php-fpm-and-sync-local-permissions)
4. [Serve PHP files with PHP-FPM over HTTPS](#-serve-php-files-with-php-fpm-over-https)
5. [Act as a Reverse Proxy for NodeJS](#-act-as-a-reverse-proxy-for-nodejs)
6. [Fully functional LEMP stack with Mass vhosts](#-fully-functional-lemp-stack-with-mass-vhosts)
7. [Docker Compose](#-docker-compose)



## 💡 Serve static files

This example creates the main (default) vhost, which only serves static files.

* **Vhost:** main (default)
* **Backend:** none

> 🛈 With no further configuration, the webserver expects files to be served by the main vhost in: `/var/www/default/htdocs`.

1. Create a static page
   ```bash
   mkdir -p www/htdocs
   echo '<h1>It works</h1>' > www/htdocs/index.html
   ```
2. Start the webserver
   ```bash
   docker run -d -it \
       -p 9090:80 \
       -v $(pwd)/www:/var/www/default \
       devilbox/nginx-stable
   ```
3. Verify
   ```bash
   curl http://localhost:9090
   ```



## 💡 Serve PHP files with PHP-FPM

This example creates the main (default) vhost, which contacts a remote PHP-FPM host to serve PHP files.

* **Vhost:** main (default)
* **Backend:** PHP-FPM

| PHP-FPM Reference Images |
|--------------------------|
| <a title="PHP-FPM Reference Images" href="https://github.com/devilbox/docker-php-fpm" ><img title="Devilbox" height="82px" src="https://raw.githubusercontent.com/devilbox/artwork/master/submissions_banner/cytopia/02/png/banner_256_trans.png" /></a> |

> 🛈 For this to work, the `$(pwd)/www` directory must be mounted into the webserver container as well as into the php-fpm container.<br/>
> 🛈 With no further configuration, the webserver expects files to be served by the main vhost in: `/var/www/default/htdocs`.

1. Create a helo world page
   ```bash
   mkdir -p www/htdocs
   echo '<?php echo "hello from php";' > www/htdocs/index.php
   ````
2. Start the PHP-FPM container
   ```bash
   docker run -d -it \
       --name php \
       -v $(pwd)/www:/var/www/default \
       devilbox/php-fpm:8.2-base
   ```
3. Start the webserve, linking it to the PHP-FPM container
   ```bash
   docker run -d -it \
       -p 9090:80 \
       -v $(pwd)/www:/var/www/default \
       -e MAIN_VHOST_BACKEND='conf:phpfpm:tcp:php:9000' \
       --link php \
       devilbox/nginx-stable
   ```
4. Verify
   ```bash
   curl http://localhost:9090
   ```



## 💡 Serve PHP files with PHP-FPM and sync local permissions

The same as the previous example, but also ensures that you can edit files locally and have file ownerships synced with webserver and PHP-FPM container.

> See **[Syncronize File System Permissions](https://github.com/devilbox/docker-php-fpm/blob/master/doc/syncronize-file-permissions.md)** for details

* **Vhost:** main (default)
* **Backend:** PHP-FPM
* **Feature:** `uid` and `gid` are synced

> 🛈 For this to work, the `$(pwd)/www` directory must be mounted into the webserver container as well as into the php-fpm container.<br/>
> 🛈 With no further configuration, the webserver expects files to be served by the main vhost in: `/var/www/default/htdocs`.<br/>
> 🛈 `NEW_UID` and `NEW_GID` are set to your local users' value

1. Create a helo world page
   ```bash
   mkdir -p www/htdocs
   echo '<?php echo "hello from php";' > www/htdocs/index.php
   ````
2. Start the PHP-FPM container
   ```bash
   docker run -d -it \
       --name php \
       -v $(pwd)/www:/var/www/default \
       -e NEW_UID=$(id -u) \
       -e NEW_GID=$(id -g) \
       devilbox/php-fpm:8.2-base
   ```
3. Start the webserve, linking it to the PHP-FPM container
   ```bash
   docker run -d -it \
       -p 9090:80 \
       -v $(pwd)/www:/var/www/default \
       -e NEW_UID=$(id -u) \
       -e NEW_GID=$(id -g) \
       -e MAIN_VHOST_BACKEND='conf:phpfpm:tcp:php:9000' \
       --link php \
       devilbox/nginx-stable
   ```
4. Verify
   ```bash
   curl http://localhost:9090
   ```
5. **Explanation:** Whenever a file is created by the webserver (e.g.: file uploads) or the PHP-FPM process (e.g.: php creates a file on the filesystem), it is done with the same permissions as your local operating system user. This means you can easily edit files in your IDE/editor and do not come accross permission issues.




## 💡 Serve PHP files with PHP-FPM over HTTPS

The same as the previous example, just with the addition of enabling SSL (HTTPS).

This example shows the SSL type `redir`, which makes the webserver redirect any HTTP requests to HTTPS.

Additionally we are mounting the `./ca` directory into the container under `/ca`. After startup you will find generated Certificate Authority files in there, which you could import into your browser.

* **Vhost:** main (default)
* **Backend:** Reverse Proxy
* **Features:** `uid` and `gid` are synced and SSL (redirect)

> 🛈 For this to work, the `$(pwd)/www` directory must be mounted into the webserver container as well as into the php-fpm container.<br/>
> 🛈 With no further configuration, the webserver expects files to be served by the main vhost in: `/var/www/default/htdocs`.

1. Create a helo world page
   ```bash
   mkdir -p www/htdocs
   echo '<?php echo "hello from php";' > www/htdocs/index.php
   ````
2. Start the PHP-FPM container
   ```bash
   docker run -d -it \
       --name php \
       -e NEW_UID=$(id -u) \
       -e NEW_GID=$(id -g) \
       -v $(pwd)/www:/var/www/default \
       devilbox/php-fpm:8.2-base
   ```
3. Start the webserve, linking it to the PHP-FPM container
   ```bash
   docker run -d -it \
       -p 80:80 \
       -p 443:443 \
       -v $(pwd)/www:/var/www/default \
       -v $(pwd)/ca:/ca \
       -e NEW_UID=$(id -u) \
       -e NEW_GID=$(id -g) \
       -e MAIN_VHOST_BACKEND='conf:phpfpm:tcp:php:9000' \
       -e MAIN_VHOST_SSL_TYPE='redir' \
       --link php \
       devilbox/nginx-stable
   ```
4. Verify redirect
   ```bash
   curl -I http://localhost
   ```
5. Verify HTTPS
   ```bash
   curl -k https://localhost
   ```



## 💡 Act as a Reverse Proxy for NodeJS

The following example proxies all HTTP requests to a NodeJS remote backend. You could also enable SSL on the webserver in order to access NodeJS via HTTPS.

* **Vhost:** main (default)
* **Backend:** Reverse Proxy

> 🛈 No files need to be mounted into the webserver, as content is coming from the NodeJS server.

1. Create a NodeJS application
   ```bash
   mkdir -p src
   cat << EOF > src/app.js
   const http = require('http');
   const server = http.createServer((req, res) => {
           res.statusCode = 200;
           res.setHeader('Content-Type', 'text/plain');
           res.write('[OK]\n');
           res.write('NodeJS is running\n');
           res.end();
   });
   server.listen(3000, '0.0.0.0');
   EOF
   ```
2. Start the NodeJS container
   ```bash
   docker run -d -it \
       --name nodejs \
       -v $(pwd)/src:/app \
       node:19-alpine node /app/app.js
   ```
3. Start Reverse Proxy
   ```bash
   docker run -d -it \
       -p 80:80 \
       -e MAIN_VHOST_BACKEND='conf:rproxy:http:nodejs:3000' \
       --link nodejs \
       devilbox/nginx-stable
   ```
4. Verify
   ```bash
   curl http://localhost
   ```



## 💡 Fully functional LEMP stack with Mass vhosts

The following example creates a dynamic setup. Each time you create a new project directory below `www/`, a new virtual host is being created.
Additionally all projects will have the `.com` suffix added to their domain name, which results in `<project>.com` as the final domain.

* **Vhost:** mass (unlimited vhosts)
* **Backend:** PHP-FPM

> 🛈 For this to work, the `$(pwd)/www` directory must be mounted into the webserver container as well as into the php-fpm container.<br/>
> 🛈 With no further configuration, the webserver expects files to be served by the **mass** vhost in: **`/shared/httpd/<project>/htdocs`**, where `<project>` is a placeholder for any directory.

1. Create the project base directory
   ```bash
   mkdir -p www
   ```
2. Start the MySQL container _(only for demonstration purposes)_
   ```bash
   docker run -d -it \
       --name mysql \
       -e MYSQL_ROOT_PASSWORD=my-secret-pw \
       devilbox/mysql:mariadb-10.10
   ```
3. Start the PHP-FPM container
   ```bash
   docker run -d -it \
       --name php \
       -v $(pwd)/www:/shared/httpd \
       devilbox/php-fpm:8.2-base
   ```
4. Start the webserver container, linking it to the two above
   ```bash
   docker run -d -it \
       -p 8080:80 \
       -v $(pwd)/www:/shared/httpd \
       -e MAIN_VHOST_ENABLE=0 \
       -e MASS_VHOST_ENABLE=1 \
       -e MASS_VHOST_TLD_SUFFIX=.com \
       -e MASS_VHOST_BACKEND='conf:phpfpm:tcp:php:9000' \
       --link php \
       --link mysql \
       devilbox/nginx-stable
   ```
5. Create `project-1`
   ```bash
   mkdir -p www/project-1/htdocs
   echo '<?php echo "hello from project-1";' > www/project-1/htdocs/index.php
   ```
6. Verify `project-1`
   ```bash
   curl -H 'Host: project-1.com' http://localhost:8080
   ```
7. Create `another`
   ```bash
   mkdir -p www/another/htdocs
   echo '<?php echo "hello from another";' > www/another/htdocs/index.php
   ```
8. Verify `another`
   ```bash
   curl -H 'Host: another.com' http://localhost:8080
   ```
9. Add more projects as you wish...




## 💡 Docker Compose

Have a look at the **[examples](../examples/)** directory. It is packed with all kinds of `Docker Compose` examples:

* SSL
* PHP-FPM remote server
* Python and NodeJS Reverse Proxy
* Mass virtual hosts
* Mass virtual hosts with PHP-FPM, Python and NodeJS as backends
