# Example: PHP_FPM

Docker Compose example with a remote PHP-FPM server.

This example uses mass virtual hosting, i.e.: it creates **as many virtual hosts automatically as directories exist**.
This happens either during startup (initial setup) and also during run-time, whenever directories are created, renamed or removed.
It will also provide **SSL capable vhosts** that you can view in your browser **without SSL certificate warnings.**


Try it out yourself and add a directory into the [projects](projects/) directory. As soon as you create one, a new virtual host will be created. Keep in mind that files are being served from the `htdocs` directory within your newly created project. (The `htdocs` directory can also be a symlink).

The `MASS_VHOST_TLD_SUFFIX` is set to `.loc`, so the project vhost name (its domain) will be: `<directory-name>.loc`

## Example 1: During Startup

The [projects](projects/) directory already contains two projects:
  * `sample`
  * `test`

That means that during startup, two vhosts will be created:
  * `sample.loc`
  * `test.loc`

The files for each vhost are being served from:
  * `projects/sample/htdocs` (where `htdocs` symlinks to `src/`)
  * `projects/test/htdocs`

You can reach those two projects via:
```bash
# Ensure docker-compose is running
docker-compose up

# Now verify
curl http://localhost:8000 -H 'host: sample.loc'
curl http://localhost:8000 -H 'host: test.loc'
```

## Example 2: During Run-time

In this example we add more projects during run-time
```bash
# Ensure docker-compose is running
docker-compose up
```

Now as the HTTP and PHP container are up and running, we can add more projects:
```
# Create project directory
# This will auto-create a new vhost 'it-works.tld'
mkdir projects/it-works/

# Add some code
mkdir projects/it-works/htdocs
echo '<?php echo "Yes";?>' > projects/it-works/htdocs/index.php
```
Now you can access it via:
```bash
curl http://localhost:8000 -H 'host: it-works.loc'
```

**Note:** The other two vhosts from Example 1 are still available.


## Example 3: SSL and Browser access

You migth have noticed the `ca/` directory. The HTTPD container also creates SSL certificates for all of the above described vhosts (and any you will create during startup- or run-time).
This is done via a certificate authority, so that each vhost certificate was signed by a CA.

**What is the benefit?**

1. You can import the CA files in the `ca/` directory into your browser
2. Add `/etc/hosts` entries:
    ```bash
    127.0.0.1 sample.loc
    127.0.0.1 test.loc
    127.0.0.1 it-works.loc
    ```
3. Access them through your browser via valid https
  * `https://sample.loc:8443
  * `https://test.loc:8443
  * `https://it-works.loc:8443
