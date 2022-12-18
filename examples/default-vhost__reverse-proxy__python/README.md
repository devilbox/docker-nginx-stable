# Example: Reverse Proxy (Python)

Docker Compose example with HTTPD acting as a Reverse Proxy and a remote Python server.

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
