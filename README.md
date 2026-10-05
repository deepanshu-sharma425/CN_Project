# Team Nova — Computer Networks Project, Phase 1

A small four-machine web stack on one LAN: a private DNS name, an HTTPS edge server,
and two backends behind a round-robin load balancer.

## Team members

| Roll number | Name               | Machine | Role                            |
|-------------|--------------------|---------|---------------------------------|
| 2401010144  | Deepanshu          | Mac 2   | nginx edge (TLS, load balancer) |
| 2401010207  | Kanishk Sharma     | Mac 3   | Backend A                       |
| 2401020027  | Hrishabh Prajapati | Mac 1   | DNS (dnsmasq)                   |
| 2401010026  | Adarsh             | Mac 4   | Backend B                       |

## Architecture

    client
      |  1. DNS query: app.nova.test
      v
    Mac 1  dnsmasq (10.7.8.113)  ->  answers 10.7.7.58
      |
      |  2. https://app.nova.test (port 443, TLS)
      v
    Mac 2  nginx (10.7.7.58)  -- terminates TLS, round-robin over plain HTTP
      |                    |
      v                    v
    Mac 3  Backend A       Mac 4  Backend B
    10.7.19.171:3001       10.7.20.75:3002
    X-Backend: A           X-Backend: B

| Machine | IP          | Port | Role                                                |
|---------|-------------|------|-----------------------------------------------------|
| Mac 1   | 10.7.8.113  | 53   | dnsmasq, resolves `app.nova.test` to `10.7.7.58`    |
| Mac 2   | 10.7.7.58   | 443  | nginx, TLS via mkcert, round-robin to both backends |
| Mac 3   | 10.7.19.171 | 3001 | Backend A (Node.js), sends `X-Backend: A`           |
| Mac 4   | 10.7.20.75  | 3002 | Backend B (Node.js), sends `X-Backend: B`           |

Each backend serves `/` and `/api/status` and labels every response with an
`X-Backend` header, so the backend that answered a request is visible to the client.

## Repository layout

| Path                        | Contents                                 |
|-----------------------------|------------------------------------------|
| `MAC_1/dnsmasq.conf`        | dnsmasq config used on Mac 1             |
| `MAC_1/screenshots/`        | Mac 1 evidence and DNS packet capture    |
| `nginx/nova.conf`           | nginx virtual host used on Mac 2         |
| `MAC_2/`                    | Screenshots taken on Mac 2               |
| `backend-a/`                | Backend A server (Mac 3) and its evidence |
| `MAC_4/Backend_B/`          | Backend B server (Mac 4)                 |
| `MAC_4/evidence/`           | Screenshots taken on Mac 4               |

TLS private keys are not in this repository; `.gitignore` excludes `*.pem`.

## How to run

Start the pieces in this order: backends, then DNS, then nginx.

### 1. Backends

The backends use only Node.js built-ins, so there is nothing to install.

Backend A, on Mac 3 (listens on port 3001):

    cd backend-a && node server.js

Backend B, on Mac 4 (listens on port 3002):

    cd MAC_4/Backend_B && node server.js

### 2. DNS (Mac 1)

Install dnsmasq, use `MAC_1/dnsmasq.conf` as its config, and start it:

    brew install dnsmasq
    cp MAC_1/dnsmasq.conf /opt/homebrew/etc/dnsmasq.conf
    sudo brew services start dnsmasq

Every machine that should resolve `app.nova.test` must use Mac 1 (`10.7.8.113`) as
its DNS server.

### 3. nginx (Mac 2)

Create a certificate for the name with mkcert, install the virtual host, and start nginx:

    brew install nginx mkcert
    mkcert -install
    mkdir -p /opt/homebrew/etc/nginx/certs
    cd /opt/homebrew/etc/nginx/certs && mkcert app.nova.test
    cp nginx/nova.conf /opt/homebrew/etc/nginx/servers/nova.conf
    nginx -t
    nginx

After a config change, reload with `nginx -s reload`. Stop with `nginx -s quit`.

A client only trusts the certificate if mkcert's root CA certificate (`rootCA.pem`
from `mkcert -CAROOT`, never `rootCA-key.pem`) is installed in its trust store.

## How to verify

DNS resolves the name to Mac 2:

    dig app.nova.test

The answer should be `10.7.7.58`.

HTTPS works and the certificate validates:

    curl -v https://app.nova.test

Load balancing alternates between the two backends:

    for i in {1..6}; do curl -si https://app.nova.test/api/status | grep -iE '^(HTTP|x-backend)'; done

The `X-Backend` header should alternate between `A` and `B`. Use curl for this, not a
browser, because a browser caches `/` and hides the alternation.

Caching headers on the root endpoint:

    curl -sI https://app.nova.test/

`/` carries `Cache-Control: public, max-age=60` and an `ETag`. `/api/status` is live
data and is deliberately `Cache-Control: no-store`.
