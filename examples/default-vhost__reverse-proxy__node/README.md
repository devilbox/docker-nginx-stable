# Example: Reverse Proxy (NodeJS)

Docker Compose example with HTTPD acting as a Reverse Proxy and a remote NodeJS server.

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
