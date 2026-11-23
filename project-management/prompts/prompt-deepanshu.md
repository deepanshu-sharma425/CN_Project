# Team Nova — Claude Code brief for Deepanshu (Mac 2, primary edge)

You are helping Deepanshu, owner of **Mac 2** in Team Nova's Computer Networks project (Private Network Service Platform, domain `app.nova.test`). Work only on Mac 2. Never change another member's Mac. Phase 1 already works; preserve it and always keep a rollback copy.

## 1. Identity and role
- Member: Deepanshu (2401010144). Machine: Mac 2.
- Role: primary nginx edge (TLS termination, round-robin load balancing, backend failover), the Phase 1 and Phase 2 nginx configs, the T2/T3 timing experiments on the nginx side, the team's mkcert certificate authority (CA), signing Mac 4's certificate request (CSR), HTTPS verification, primary-edge evidence. Mac 2 is also the main test client for the DNS failover (S3) and TTL (S7) experiments.
- Coordinator: Kanishk (Mac 3). Primary DNS: Hrishabh (Mac 1). Standby edge: Adarsh (Mac 4).

## 2. Ground rules
1. Read-only inspection first in every session. IPs come only from `project-management/IP_INVENTORY.md` (filled in S0). Until then every IP is NOT VERIFIED.
2. Placeholders: `<MAC1_IP>`…`<MAC4_IP>`, `<WIFI_SERVICE>` (from `networksetup -listallnetworkservices`), `<BREW>` (from `brew --prefix`; Phase 1 used `/opt/homebrew`, re-check). nginx configs cannot run shell commands, so write `<BREW>` as the literal path.
3. Before every nginx change: `mkdir -p ~/nova-backups && cp "$(brew --prefix)/etc/nginx/servers/nova.conf" ~/nova-backups/nova.conf.$(date +%Y%m%d-%H%M%S)`.
4. Every change: edit → `nginx -t` (expected `syntax is ok` and `test is successful`) → `nginx -s reload`. Run nginx as the same non-root user that started it (Phase 1 ran as `deepanshu.`); do not add sudo.
5. Rollback for any nginx change: copy the newest backup back, `nginx -t`, `nginx -s reload`.
6. mkcert: never with sudo. The CA lives in your home folder (`mkcert -CAROOT`). Never copy, share or commit `rootCA-key.pem` or any `*-key.pem`.
7. Changes only after the checkpoint is recorded as approved. Record actual results with timestamps. A result that differs from the expected one: stop and report.
8. No `git push`, `--force`, `commit --amend`, `rebase`, `reset`, `merge` without a recorded approval.

## 3. Files to inspect first
- Repo: `README.md`, `nginx/nova.conf` (Phase 1), `MAC_2/tls/README.md`, `MAC_2/certs/mkcert-rootCA.crt`, `MAC_2/*.png`.
- Installed: `"$(brew --prefix)/etc/nginx/nginx.conf"`, `"$(brew --prefix)/etc/nginx/servers/nova.conf"`, `"$(brew --prefix)/etc/nginx/certs/"`, logs `"$(brew --prefix)/var/log/nginx/error.log"` and `access.log`.
- Shared: `project-management/IP_INVENTORY.md`, `PROJECT_STATUS.md`, your status file `project-management/status/deepanshu.json`.

## 4. Repository and status workflow
- Repo `https://github.com/deepanshu-sharma425/CN_Project` (your account), branch `phase2`. `git fetch origin && git switch phase2 && git pull --ff-only origin phase2`.
- Evidence: `MAC_2/evidence/phase2/S<stage>-<NN>-<slug>.<ext>`; Phase 1 completion `MAC_2/evidence/phase1-completion/S1-<NN>-<slug>.<ext>`. Save outputs with `| tee`.
- Status: edit only `project-management/status/deepanshu.json` (fields `member, mac, stage, task, status, latestTest, evidence[], commit, blockers[], next, updated`).
- Commit after approval: `git pull --ff-only origin phase2` → `git status` → `git diff` → `git add <exact paths>` (never `-A`; never `*.pem`, `*.csr`, `rootCA*`, `~/nova-backups`) → `git commit -m "<planned message>"` → `git log -1 --format='%h %s'` → report hash. Push only with Kanishk's recorded approval.

## 5. Tasks in order

### S0 — Re-baseline (read-only, then CP1)
Save as `MAC_2/evidence/phase2/S0-01-inventory.txt`:
```
date
ipconfig getifaddr en0
ifconfig en0 | grep -E 'ether|inet '
route -n get default | grep -E 'gateway|interface'
networksetup -listallnetworkservices
networksetup -getdnsservers "<WIFI_SERVICE>"
scutil --dns | sed -n '1,20p'
grep -i nova /etc/hosts || echo "no nova entries"
/usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate
/usr/libexec/ApplicationFirewall/socketfilterfw --getstealthmode
sudo pfctl -s info | head -3
brew --prefix
nginx -v
nginx -V 2>&1 | tr ' ' '\n' | grep -E 'http_v2_module|http_ssl_module'
ps aux | grep '[n]ginx'
lsof -nP -iTCP:443 -sTCP:LISTEN
lsof -nP -iTCP:8080 -sTCP:LISTEN
lsof -nP -iTCP:8443 -sTCP:LISTEN || echo "8443 free"
grep -n worker_processes "$(brew --prefix)/etc/nginx/nginx.conf"
cat "$(brew --prefix)/etc/nginx/servers/nova.conf"
ls -l "$(brew --prefix)/etc/nginx/certs/"
mkcert -version
mkcert -CAROOT
openssl x509 -noout -fingerprint -sha256 -in "$(mkcert -CAROOT)/rootCA.pem"
openssl x509 -noout -fingerprint -sha256 -in MAC_2/certs/mkcert-rootCA.crt
openssl x509 -noout -subject -ext subjectAltName -dates -in "$(brew --prefix)/etc/nginx/certs/app.nova.test.pem"
```
The two CA fingerprints must be identical; if not, stop (the CA in use differs from the one clients trust).
Report: IP, MAC, gateway, DNS list, nginx version, http_v2 present?, worker count, listening ports, upstream lines, cert dates.
CP1 change: update the two `server` lines of `upstream nova_backends` to `<MAC3_IP>:3001` and `<MAC4_IP>:3002` (backup first), `nginx -t`, `nginx -s reload`. Set Mac 2's DNS to Mac 1 only for now: `sudo networksetup -setdnsservers "<WIFI_SERVICE>" <MAC1_IP>`, flush `sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder`. Verify `for i in 1 2 3 4 5 6; do /usr/bin/curl -s -o /dev/null -D - https://app.nova.test/api/status | grep -iE '^(HTTP|x-backend)'; done` alternates A and B with 200.

### S1 — Phase 1 completion (CP2)
1. Wrong-port precondition: `lsof -nP -iTCP:8443 -sTCP:LISTEN` must print nothing (Adarsh runs the client side).
2. During Kanishk's "Backend A stopped" and "both stopped" demos, capture `tail -n 20 "$(brew --prefix)/var/log/nginx/error.log"`. Expected lines: `connect() failed (61: Connection refused) while connecting to upstream`; with both down also `no live upstreams`. Evidence `S1-01-error-log-one-down.txt`, `S1-02-error-log-both-down.txt`.
3. HTTP/2 (only if S0 showed `http_v2_module`): add `http2 on;` under `listen 443 ssl;`, `nginx -t`, reload. Verify `/usr/bin/curl -sv --http2 https://app.nova.test/ 2>&1 | grep -i alpn` → `ALPN: server accepted h2`. Evidence `S1-03-http2-alpn.txt`. Rollback: remove the line, reload.
4. Save the result as the **Phase 1 baseline**: `cp "$(brew --prefix)/etc/nginx/servers/nova.conf" ~/nova-backups/nova.conf.phase1-baseline` and copy it to the repo as `nginx/nova.phase1-baseline.conf` (the original `nginx/nova.conf` stays as the historical Phase 1 file).

### S2 — Extension D, part 1 (CP3)
Official requirement: nginx detects an unavailable backend and routes only to the healthy one; stop A → all served by B; restart A → balancing resumes; name the remaining single point of failure (this Mac's nginx) and how to remove it.
What is already in Phase 1 (nginx defaults, keep saying so in the viva): round robin, `max_fails=1`, `fail_timeout=10s`, `proxy_next_upstream error timeout`, so a stopped backend process (connection refused) already fails over instantly. Writing `max_fails`/`fail_timeout` explicitly documents the policy and changes no behaviour. Active health checks (`health_check`) are commercial nginx only.
Phase 2 additions: `proxy_connect_timeout 2s` (default 60 s), `proxy_read_timeout 5s` (default 60 s), `X-Edge` header.
Create `nginx/nova.phase2.conf` in the repo (literal paths, real IPs from the inventory):
```
upstream nova_backends {
    server <MAC3_IP>:3001 max_fails=1 fail_timeout=10s;
    server <MAC4_IP>:3002 max_fails=1 fail_timeout=10s;
}

server {
    listen 8080;
    server_name app.nova.test;
    add_header X-Edge "mac2" always;

    location / {
        proxy_pass http://nova_backends;
        proxy_connect_timeout 2s;
        proxy_read_timeout 5s;
        proxy_next_upstream error timeout;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}

server {
    listen 443 ssl;
    http2 on;    # only if S1 confirmed http_v2_module
    server_name app.nova.test;

    ssl_certificate     <BREW>/etc/nginx/certs/app.nova.test.pem;
    ssl_certificate_key <BREW>/etc/nginx/certs/app.nova.test-key.pem;
    add_header X-Edge "mac2" always;

    location / {
        proxy_pass http://nova_backends;
        proxy_connect_timeout 2s;
        proxy_read_timeout 5s;
        proxy_next_upstream error timeout;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```
Keep `add_header` at server level only (nginx inherits it into `location /` only while that location has no `add_header` of its own).
Install: backup, `cp nginx/nova.phase2.conf "$(brew --prefix)/etc/nginx/servers/nova.conf"`, `nginx -t`, `nginx -s reload`. Evidence `S2-01-config-diff.txt` from `diff ~/nova-backups/nova.conf.phase1-baseline nginx/nova.phase2.conf`.
Tests (Mac 2 is the client; each on Kanishk's signal):
- Doc steps: Kanishk stops Backend A → run the 6-request loop → all `X-Backend: B`, 200. Kanishk restarts A → within about 10 s A appears again. Both stopped → `curl -si https://app.nova.test/api/status | head -8` shows `502`, `Server: nginx`, `X-Edge: mac2`. Evidence `S2-02..S2-04`, plus `error.log` excerpts.
- **T2 (frozen backend, read timeout).** Timing command: `for i in 1 2 3 4; do /usr/bin/curl -s -o /dev/null --max-time 120 -w "%{http_code} %{time_total}s\n" https://app.nova.test/api/status; done`.
  1. Install the Phase 1 baseline, `nginx -t`, `nginx -s reload`. Kanishk runs `kill -STOP` on Backend A. Run the timing command → `S2-05-T2-phase1.txt`. Kanishk runs `kill -CONT`. Wait 15 s.
  2. Install `nova.phase2.conf`, `nginx -t`, `nginx -s reload`. Kanishk freezes A again. Run → `S2-06-T2-phase2.txt`. Kanishk resumes A.
  3. Save `error.log` lines (`upstream timed out (60: Operation timed out) while reading response header from upstream`) → `S2-07-T2-error-log.txt`.
  Expected (NOT VERIFIED): one request near 60 s under Phase 1, near 5 s under Phase 2. Record the real numbers.
- The reload before each run resets the failure state (one worker; per-worker state without `zone` is an assumption).

### S3 — Extension A client test (CP4)
You run the client side on Mac 2.
1. Set DNS to both servers: `sudo networksetup -setdnsservers "<WIFI_SERVICE>" <MAC1_IP> <MAC3_IP>`; flush. Check `scutil --dns | sed -n '1,12p'` (exactly two nameservers, no public ones).
2. Direct server tests (prove each server works; they do **not** prove client failover): `dig @<MAC1_IP> app.nova.test` and `dig @<MAC3_IP> app.nova.test` → NOERROR, `aa`, `SERVER:` line naming that server.
3. Wireshark on en0, capture filter `udp port 53 or icmp`, display filter `dns.qry.name == "app.nova.test" || icmp.type == 3`. Note which server answers while both are up.
4. Hrishabh stops dnsmasq on Mac 1. `dig +time=2 +tries=1 @<MAC1_IP> app.nova.test` → fails.
5. Flush the cache, then the system-resolver test: `time dscacheutil -q host -a name app.nova.test` and `/usr/bin/curl -sS -o /dev/null -w '%{http_code}\n' https://app.nova.test/api/status`.
6. Pass only if the lookup succeeds **and** the capture shows the answer from `ip.src == <MAC3_IP>`. Record lookup time and any queries to Mac 1 (ICMP port unreachable). Save `S3-01-failover.pcapng`, `S3-02-resolver-results.txt`.
7. DNS failure vs application failure: with both DNS servers stopped, `curl https://app.nova.test/` fails to resolve but `curl -sS --resolve app.nova.test:443:<MAC2_IP> https://app.nova.test/api/status` returns 200 → `S3-03-dns-vs-app.txt`.
Do not claim automatic or ordered failover unless this capture shows it.

### S4 — Extension C allowed-client tests (Kanishk's CP5)
From Mac 2 while the strict rules are loaded: `curl -si http://<MAC3_IP>:3001/api/status` and `curl -si http://<MAC4_IP>:3002/api/status` → 200 with `X-Backend`. After the rules load, run `nginx -s reload` (clears any reused upstream connections), then the 6-request loop through the edge. Evidence `S4-01-allowed-from-mac2.txt`.

### S5 — Extension D T3 (CP6), after pf is proven
Same method as T2 with Kanishk's pf fault ruleset (silent drop of Mac 2 to port 3001) instead of `kill -STOP`. Expected error line `upstream timed out (60: Operation timed out) while connecting to upstream`; expected (NOT VERIFIED) near 60 s Phase 1, near 2 s Phase 2. Evidence `S5-01-T3-phase1.txt`, `S5-02-T3-phase2.txt`, `S5-03-T3-error-log.txt`, then the 2×2 timing table `S5-04-timing-table.md`. Leave `nova.phase2.conf` installed at the end.

### S6a — Sign Mac 4's certificate (CP7)
1. Receive only `app.nova.test.csr` from Adarsh (public file). Never receive or send a private key.
2. Work in an empty folder, never in `<BREW>/etc/nginx/certs/` (a signed cert written there could overwrite your live `app.nova.test.pem`):
   ```
   mkdir -p ~/nova-csr && cd ~/nova-csr
   mkcert -CAROOT
   openssl req -in app.nova.test.csr -noout -verify -text | grep -A1 "Subject Alternative Name"
   mkcert -cert-file mac4-app.nova.test.pem -csr app.nova.test.csr
   openssl x509 -in mac4-app.nova.test.pem -noout -subject -issuer -dates -ext subjectAltName
   ```
   Expected: CSR `verify OK` with `DNS:app.nova.test`; cert issuer = the team CA (same `OU=deepanshu.@Deepanshus-MacBook-Pro-3.local` as `MAC_2/certs/mkcert-rootCA.crt`); SAN `DNS:app.nova.test`. If the SAN is missing, stop (mkcert copying the SAN from the CSR is NOT VERIFIED).
3. Send `mac4-app.nova.test.pem` (public) to Adarsh. Evidence `S6-01-signing.txt` (no key material).
4. Help Adarsh compare: both edges must show the same issuer but different SHA-256 fingerprints.

### S7 — Extension B client test (CP8)
Mac 2 is the TTL client. Preconditions: `grep nova /etc/hosts` empty; cache flushed.
1. Wireshark display filter `dns.qry.name == "app.nova.test"`. Do one lookup; note t0 from the response packet and `dns.resp.ttl` (expected 30).
2. Start: `for i in $(seq 1 25); do printf "%s " "$(date +%T)"; dscacheutil -q host -a name app.nova.test | awk '/ip_address/{print $2}'; sleep 2; done | tee MAC_2/evidence/phase2/S7-01-ttl-loop.txt`
3. Hrishabh then Kanishk change the record to `<MAC4_IP>`.
4. Expected (NOT VERIFIED): old IP until about t0 + 30 s and no DNS packets in that window, then a new query and the new IP. Record the actual switch time.
5. Flush run: lookup, record change, flush, lookup again → new IP at once with a new query. `S7-02-flush.txt`, `S7-03-ttl.pcapng`.
Weak spots to avoid: using `dig` as cache proof; timing from the change instead of t0; only one server changed; both servers restarting together; a browser.

### S8 — Extension E (CP9)
Keep Mac 2 nginx running during the cutover (connection draining). `tail -f "$(brew --prefix)/var/log/nginx/access.log" | tee MAC_2/evidence/phase2/S8-01-mac2-access.txt` — expected: client X's IP keeps arriving until its cache expires, then stops. Rollback on signal.

### S9 — Extension F drills
Faults to practise on Mac 2: nginx stopped (TCP refused on 443), wrong upstream port (502), `proxy_pass https://` instead of `http://`, config syntax error (reload refused, old config stays live), wrong `server_name`, wrong certificate path, CA not trusted on a client (curl error 60). Use `nginx -t`, `error.log`, `curl -v`, `openssl s_client -connect app.nova.test:443 -servername app.nova.test </dev/null`. Evidence `S9-NN-drill-<fault>.txt`.

### S10 — Documentation
Learning paragraphs for Extension D (passive checks, timeouts, single point of failure) and the TLS part of Extension E. Supply the nginx configs and TLS notes for the configuration bundle.

## 6. Stop and ask Kanishk when
- The CA fingerprints differ, a certificate fails verification, or `nginx -t` fails.
- An IP differs from the inventory.
- A timing or log result differs from the expected one.
- You are asked to sign anything other than Adarsh's CSR, to share a key, to change another Mac, or to run git history commands or a push.

## 7. Report after each task
`Member / Mac / Stage / Task / Result / Time / Evidence files / Commands / Unexpected output / Commit hash / Next / Blockers`.
