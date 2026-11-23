# Team Nova — Private Network Service Platform

Computer Networks course project. Four MacBooks on one Wi-Fi LAN run a small web service that
can be reached only by its private name, `https://app.nova.test`:

- a private DNS server, plus a backup DNS server,
- an nginx edge that terminates TLS and load-balances, plus a standby edge,
- two simple Node.js backends that can be reached only through an edge.

- **Phase 1 (October 2026):** build the network and observe it.
- **Phase 2 (23 November 2026):** harden it, recover from failures and troubleshoot.

| Document | File |
|---|---|
| Phase 1 report | [`report/Team_Nova_Phase1_Report.pdf`](report/Team_Nova_Phase1_Report.pdf) |
| Phase 1 demo report | [`report/Team_Nova_Demo_Report.pdf`](report/Team_Nova_Demo_Report.pdf) |
| Phase 2 report | [`report/Team_Nova_Phase2_Report.pdf`](report/Team_Nova_Phase2_Report.pdf) |
| Evidence index (every requirement → its proof) | [`project-management/EVIDENCE_INDEX.md`](project-management/EVIDENCE_INDEX.md) |

## Team members

| Roll number | Name               | Machine | Role (Phase 2)                                        |
|-------------|--------------------|---------|-------------------------------------------------------|
| 2401020027  | Hrishabh Prajapati | Mac 1   | Primary DNS (dnsmasq), test client                    |
| 2401010144  | Deepanshu          | Mac 2   | Active edge: nginx, TLS, load balancer; team CA       |
| 2401010207  | Kanishk Sharma     | Mac 3   | Backend A, backup DNS, coordination                   |
| 2401010026  | Adarsh Vashistha   | Mac 4   | Backend B, standby edge, test client                  |

## Architecture (Phase 2)

    client  (DNS list: 10.7.22.124, then 10.7.1.218)
      |  1. DNS query for app.nova.test (UDP 53), TTL 30 s
      v
    Mac 1  primary dnsmasq  10.7.22.124  --(if it does not answer)-->  Mac 3  backup dnsmasq  10.7.1.218
      |  answer: 10.7.5.201  (or 10.7.27.160 after a DNS cutover)
      |
      |  2. https://app.nova.test (TCP 443, TLS, HTTP/2)
      v
    Mac 2  nginx  10.7.5.201  (active edge, X-Edge: mac2)       Mac 4  nginx  10.7.27.160  (standby edge, X-Edge: mac4)
      |                    |
      |  3. plain HTTP, round robin; pf allows only the edges
      v                    v
    Mac 3  Backend A       Mac 4  Backend B
    10.7.1.218:3001        10.7.27.160:3002
    X-Backend: A           X-Backend: B

| Machine | IP (23 Nov 2026) | Ports            | Services                                                  |
|---------|------------------|------------------|-----------------------------------------------------------|
| Mac 1   | 10.7.22.124      | UDP 53           | dnsmasq (primary)                                         |
| Mac 2   | 10.7.5.201       | TCP 443, 8080    | nginx 1.31.6, mkcert certificate, load balancer           |
| Mac 3   | 10.7.1.218       | TCP 3001, UDP 53 | Backend A (Node.js); dnsmasq (backup); pf rules           |
| Mac 4   | 10.7.27.160      | TCP 3002, 443    | Backend B (Node.js); standby nginx; pf rules              |

The IPs are assigned by DHCP and changed between Phase 1 and Phase 2. For example, Mac 2 was
`10.7.7.58` in Phase 1. Before running anything on a new network, re-check every Mac's IP
(`ipconfig getifaddr en0`) and update the configs listed below. The full history is in
[`project-management/IP_INVENTORY.md`](project-management/IP_INVENTORY.md).

Each backend serves `/` and `/api/status`, and labels every response with an `X-Backend`
header. The edges add an `X-Edge` header, so every reply shows which edge and which backend
answered it.

## What Phase 2 added

| Extension | What it does | Result |
|---|---|---|
| A · Backup DNS | Mac 3 runs dnsmasq with the same records; clients list both servers | Mac 1 stopped: clients still resolve through Mac 3 and get 200 |
| B · TTL 30 s | `host-record=…,30` on both servers | Cached client switched in about 40 s; a flushed client switched at once |
| C · Isolation | pf anchor `com.apple/nova` on Macs 3 and 4: only the edges may reach 3001/3002 | Other Macs time out; rollback tested |
| D · HA failover | nginx `max_fails=1`, `proxy_connect_timeout 2s`, `proxy_read_timeout 5s`, `proxy_next_upstream error timeout` | Backend A stopped: all requests go to B. Request waiting on a broken backend: 60 s → 5 s (frozen) and 60 s → 2 s (packets dropped) |
| E · Edge migration | Standby nginx on Mac 4 with its own key; DNS record moved to Mac 4 and back | No failed requests during either switch |
| F · Troubleshooting | Diagnosis order DNS → TCP → TLS → HTTP → backend, with a `diag` script | Four practice faults, each found at the right layer |

Details and numbers are in [`project-management/results/`](project-management/results/) and
[`project-management/TROUBLESHOOTING.md`](project-management/TROUBLESHOOTING.md).

## Repository layout

| Path | Contents |
|---|---|
| `MAC_1/dnsmasq.conf` | Phase 1 dnsmasq config (Mac 1) |
| `MAC_1/dnsmasq.phase2-additions.conf` | Phase 2 dnsmasq block for Mac 1 (TTL 30, forwarding, query log) |
| `MAC_2/tls/`, `MAC_2/certs/` | TLS setup notes and the public mkcert root certificate |
| `MAC_3/Backend_A/`, `MAC_4/Backend_B/` | Backend servers |
| `MAC_3/backup_dns/` | Backup dnsmasq config for Mac 3 |
| `MAC_3/firewall/`, `MAC_4/firewall/` | pf rule files and `ROLLBACK.md` for each backend |
| `MAC_4/standby_edge/` | Notes on the standby edge |
| `nginx/nova.conf` | Phase 1 nginx virtual host (original Phase 1 IPs) |
| `nginx/nova.phase1-baseline.conf` | Phase 1 config with the current IPs (used for the timing comparison) |
| `nginx/nova.phase2.conf` | Phase 2 config, active on Mac 2 |
| `nginx/nova.standby-mac4.conf` | Phase 2 config for the standby edge on Mac 4 |
| `MAC_*/evidence/` | Phase 1 screenshots and packet captures |
| `MAC_*/evidence/phase1-completion/`, `MAC_*/evidence/phase2/` | Evidence recorded on 23 Nov 2026, named `S<stage>-<NN>-<what>` |
| `project-management/` | Status, IP inventory, approvals, results, troubleshooting, evidence index |
| `report/` | Report sources (HTML), images and PDFs; `bash report/build.sh` rebuilds the PDFs |

TLS private keys, certificate requests and local backup copies are never committed.
`.gitignore` excludes `*.pem`, `*.key`, `*.csr` and `nova-backups/`.

## How to run

Start in this order: backends, then DNS, then the edge. Replace the IPs if your network gave
different ones.

### 1. Backends (Mac 3 and Mac 4)

Only Node.js built-ins are used, so there is nothing to install.

    cd MAC_3/Backend_A && node server.js     # Mac 3, port 3001
    cd MAC_4/Backend_B && node server.js     # Mac 4, port 3002

### 2. DNS (Mac 1 primary, Mac 3 backup)

Install dnsmasq, put the project block into `/opt/homebrew/etc/dnsmasq.conf`, check it, and start it.

    brew install dnsmasq
    # Mac 1: contents of MAC_1/dnsmasq.phase2-additions.conf
    # Mac 3: contents of MAC_3/backup_dns/dnsmasq-nova-backup.conf
    dnsmasq --test
    sudo brew services restart dnsmasq

Each server's `listen-address` must contain its own current IP, or dnsmasq will not start.
Set every client's DNS to both servers, primary first. Remove any public DNS servers, because
they answer "no such name" for `.test`:

    sudo networksetup -setdnsservers Wi-Fi 10.7.22.124 10.7.1.218
    sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder

### 3. Edge (Mac 2)

    brew install nginx mkcert
    mkcert -install
    mkdir -p /opt/homebrew/etc/nginx/certs
    cd /opt/homebrew/etc/nginx/certs && mkcert app.nova.test
    cp nginx/nova.phase2.conf /opt/homebrew/etc/nginx/servers/nova.conf
    nginx -t && brew services start nginx

Reload after a config change with `nginx -s reload`.

Every client must trust the team CA. Copy only `rootCA.pem` from `mkcert -CAROOT`, never
`rootCA-key.pem`, and add it to the System keychain:

    sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain rootCA.pem

### 4. Standby edge (Mac 4, optional)

1. Mac 4 creates its own key and CSR with `openssl req -new`, and sends only the `.csr` file.
2. Mac 2 signs it with `mkcert -csr app.nova.test.csr`.
3. Mac 4 installs the certificate and `nginx/nova.standby-mac4.conf`.

The steps and checks are in
[`project-management/results/S6a-standby-edge.md`](project-management/results/S6a-standby-edge.md).

### 5. Backend firewall (Mac 3 and Mac 4, optional)

    sudo pfctl -a com.apple/nova -f MAC_3/firewall/mac3-backend-a.edgetier.pf    # Mac 3
    sudo pfctl -a com.apple/nova -f MAC_4/firewall/mac4-backend-b.pf             # Mac 4

These commands only touch the `com.apple/nova` anchor. Undo them with the steps in each
folder's `ROLLBACK.md`. Never flush or disable pf as a whole. On Mac 4, pf was already
enabled by another program, so do not turn it on or off there.

## How to verify

Use `/usr/bin/curl`, which trusts the macOS keychain. Some other curl builds (for example
Anaconda's) do not.

    dig app.nova.test                          # → 10.7.5.201, TTL 30
    /usr/bin/curl -sI https://app.nova.test/   # HTTP/2 200, Cache-Control, ETag, X-Edge, X-Backend
    for i in 1 2 3 4 5 6; do
      /usr/bin/curl -s -o /dev/null -w '%{http_code} %header{x-edge} %header{x-backend}\n' https://app.nova.test/api/status
    done                                       # 200 mac2 A / B alternating

- `/` sends `Cache-Control: public, max-age=60` and an `ETag`. A request with
  `If-None-Match` returns `304`.
- `/api/status` sends `Cache-Control: no-store`.
- Use curl rather than a browser to see the alternation, because the browser caches `/`.

To test the standby edge without changing DNS:

    /usr/bin/curl -sI --resolve app.nova.test:443:10.7.27.160 https://app.nova.test/   # X-Edge: mac4

### Quick fault diagnosis

Check the layers in order, and fix the first one that fails:

1. **DNS:** `dig @10.7.22.124 app.nova.test` and `dig @10.7.1.218 app.nova.test`
2. **TCP:** `nc -z -G 3 <ip> 443`
3. **TLS:** `openssl s_client -connect <ip>:443 -servername app.nova.test`
4. **HTTP:** `curl` status and headers, and the nginx error log on the edge
   (`/opt/homebrew/var/log/nginx/error.log`)

See [`project-management/TROUBLESHOOTING.md`](project-management/TROUBLESHOOTING.md).
