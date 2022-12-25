# Examples


A Quick overview about available examples

| Complexity | Virtual Host | Backend | Description | Link |
|------------|--------------|---------|-------------|------|
| simple     | Default      | None    | Serve static files | [default-vhost__static-files](default-vhost__static-files) |
| simple     | Default      | NodsJS  | Reverse Proxy to Node app | [default-vhost__reverse-proxy__node](default-vhost__reverse-proxy__node) |
| simple     | Default      | Python  | Reverse Proxy to Python app | [default-vhost__reverse-proxy__python](default-vhost__reverse-proxy__python) |
| simple     | Default      | PHP-FPM | Serve PHP files | [default-vhost__php-fpm](default-vhost__php-fpm) |
| medium     | Default      | PHP-FPM | Serve PHP files over HTTPS (SSL) | [default-vhost__php-fpm__ssl](default-vhost__php-fpm__ssl) |
| complex    | Mass vhost   | PHP-FPM | Mass vhosting with auto-generated SSL for each host | [mass-vhost__php-fpm__ssl](mass-vhost__php-fpm__ssl) |
| complex    | Mass vhost   | Multi   | Mass vhosting with auto-generated SSL for each host (PHP-FPM and NodeJS reverse Proxy) | [mass-vhost__reverse-proxy__ssl/](mass-vhost__reverse-proxy__ssl/) |
