# Mockoon API demo

This repository contains a Mockoon API definition and a containerized traffic
generator for testing the API through Cloudflare.

## 1. Mockoon API

[`api-demo.json`](api-demo.json) is a Mockoon environment definition. It runs on
port `3000` and provides the following routes:

| Method | Route | Expected status | Description |
| --- | --- | ---: | --- |
| `GET` | `/health` | 200 | Health check |
| `GET` | `/users` | 200 | Sample user collection |
| `GET` | `/users/:id` | 200 | Sample user using a path parameter |
| `POST` | `/users` | 201 | Simulated user creation |
| `GET` | `/errors/500` | 500 | Intentional error response |
| `GET` | `/slow` | 200 | Response delayed by two seconds |

### Run the API

From the repository directory, start Mockoon with the JSON file mounted
read-only into the container:

```bash
docker run -d --name mockoon --restart unless-stopped -p 3000:3000 --mount type=bind,source="$(pwd)/api-demo.json",target=/data/api-demo.json,readonly mockoon/cli:latest -d /data/api-demo.json -p 3000
```

Test the local API:

```bash
curl -i http://localhost:3000/health
```

If Cloudflare Tunnel publishes this service at `api.example.com`, test the
public route with:

```bash
curl -i https://api.example.com/health
```

After updating `api-demo.json`, restart Mockoon to load the changes:

```bash
docker restart mockoon
```

## 2. Traffic generator

The [`traffic-generator`](traffic-generator) directory contains a small
container that continuously cycles through every API route. It records each
HTTP status code and response time in its container logs.

Each request uses the `mockoon-traffic-generator/1.0` user agent and includes a
unique `X-Traffic-Generator-ID` header so the traffic can be identified in
Cloudflare logs.

### Build the image

```bash
docker build -t mockoon-traffic-generator ./traffic-generator
```

### Run the generator

```bash
docker run -d --name mockoon-traffic --restart unless-stopped -e BASE_URL=https://api.example.com -e INTERVAL_SECONDS=5 mockoon-traffic-generator
```

`BASE_URL` selects the API to test. `INTERVAL_SECONDS` controls the delay
between requests.

View request results:

```bash
docker logs -f mockoon-traffic
```

Stop and remove the generator:

```bash
docker rm -f mockoon-traffic
```

### Deploy updates

After pushing repository changes, update the server and rebuild the generator:

```bash
git pull
docker build -t mockoon-traffic-generator ./traffic-generator
docker rm -f mockoon-traffic
docker run -d --name mockoon-traffic --restart unless-stopped -e BASE_URL=https://api.example.com -e INTERVAL_SECONDS=5 mockoon-traffic-generator
```
