# Example: PHP_FPM

Docker Compose example with a remote PHP-FPM server and serving HTTPS

## Run
```bash
docker-compose up
```

## View
```bash
# HTTP
curl http://localhost:8000

# HTTPS
curl -k https://localhost:8443
```
