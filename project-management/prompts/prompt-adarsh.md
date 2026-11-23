# Team Nova — Claude Code brief for Adarsh (Mac 4, Backend B, standby edge)

You are helping Adarsh Vashistha, owner of **Mac 4** in Team Nova's Computer Networks project (Private Network Service Platform, domain `app.nova.test`). Work only on Mac 4. Never change another member's Mac. Keep Backend B available the whole time you prepare the standby edge.

## 1. Identity and role
- Member: Adarsh Vashistha (2401010026). Machine: Mac 4.
- Role: Backend B (Node.js, TCP 3002), pf firewall on Mac 4, the standby nginx edge (Extension E), generating its private key and certificate request (CSR) locally, installing and checking the signed certificate, the standby HTTPS preflight, reachability of both backends through the standby, DNS-cutover and rollback evidence. Mac 4 was the Phase 1 test client and stays the client for the Phase 1 failure demos.
- Coordinator: Kanishk (Mac 3). Primary edge and CA: Deepanshu (Mac 2). Primary DNS: Hrishabh (Mac 1).

## 2. Ground rules
1. Read-only first. IPs only from `project-management/IP_INVENTORY.md` after S0; until then NOT VERIFIED (Phase 1 recorded Mac 4 as 10.7.20.75).
2. Placeholders `<MAC1_IP>`…`<MAC4_IP>`, `<WIFI_SERVICE>`, `<BREW>` (from `brew --prefix`), `<REPO>` (your repository folder, from `git rev-parse --show-toplevel`).
3. Your shell runs Anaconda `(base)`: plain `curl` and `openssl` may be Anaconda's builds. Use **`/usr/bin/curl`** for Keychain-trust tests and **`/usr/bin/openssl`** for certificate work, unless told otherwise.
4. pf safety: only `sudo pfctl -a com.apple/nova …` for loading and flushing; roll back with `-F rules` (never `-F all`); never `pfctl -d`, `-e`, `-z`, `-F states`, `-k`, unscoped `-f` or `-F`, or `-f /etc/pf.conf`. Enable with `sudo pfctl -E` and keep the token; lost token → `sudo pfctl -s References`; release with `sudo pfctl -X <token>`.
5. Private key rules: the standby key is generated on Mac 4 and never leaves it. Only the CSR (public) goes to Deepanshu and only the signed certificate (public) comes back. `chmod 600` on the key. Never commit `*.pem`, `*.csr`, keys or anything from `~/nova-backups`.
6. nginx: run as your normal user (no sudo), like Mac 2. Backup before every change; `nginx -t` before every start or reload.
7. Changes only after the checkpoint is recorded as approved. Record real results with timestamps; anything unexpected → stop and report.
8. No `git push`, `--force`, `commit --amend`, `rebase`, `reset`, `merge` without a recorded approval.

## 3. Files to inspect first
- Repo: `MAC_4/Backend_B/server.js` (binds `0.0.0.0:3002`, `X-Backend: B`, `/` cacheable with ETag, `/api/status` no-store), `MAC_4/evidence/`, `nginx/nova.conf`, `MAC_2/certs/mkcert-rootCA.crt`.
- After CP0: `project-management/IP_INVENTORY.md`, `PROJECT_STATUS.md`, `project-management/status/adarsh.json`, `MAC_4/firewall/mac4-backend-b.pf`, `nginx/nova.phase2.conf` (Deepanshu, S2).

## 4. Repository and status workflow
- Repo `https://github.com/deepanshu-sharma425/CN_Project`, branch `phase2`: `git fetch origin && git switch phase2 && git pull --ff-only origin phase2`.
- Evidence: `MAC_4/evidence/phase2/S<stage>-<NN>-<slug>.<ext>`; Phase 1 completion `MAC_4/evidence/phase1-completion/S1-<NN>-<slug>.<ext>`.
- Status: only `project-management/status/adarsh.json`.
- Commit after approval: `git pull --ff-only origin phase2` → `git status` → `git diff` → `git add <exact paths>` → `git commit -m "<planned message>"` → `git log -1 --format='%h %s'` → report the hash. Push only with Kanishk's recorded approval.

## 5. Tasks in order

### S0 — Re-baseline (read-only, then CP1)
Save `MAC_4/evidence/phase2/S0-01-inventory.txt`:
```
date
sw_vers
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
which -a curl openssl node nginx
/usr/bin/openssl version
/usr/bin/openssl req -help 2>&1 | grep -E 'addext|verify'
brew --prefix
lsof -nP -iTCP -sTCP:LISTEN | grep -E ':(443|8080|3002) ' || echo "443/8080/3002 free"
security verify-cert -c MAC_2/certs/mkcert-rootCA.crt
```
CP1: DNS to Mac 1 only (`sudo networksetup -setdnsservers "<WIFI_SERVICE>" <MAC1_IP>`, keep the old list for rollback), flush `sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder`. Start Backend B:
```
cd MAC_4/Backend_B
lsof -ti tcp:3002 -sTCP:LISTEN | xargs kill; sleep 1
nohup node server.js >> server.log 2>&1 &
lsof -nP -iTCP:3002 -sTCP:LISTEN          # expected: TCP *:3002 (LISTEN)
/usr/bin/curl -si http://<MAC4_IP>:3002/api/status | head -5   # expected: 200, X-Backend: B
```
Client check: `for i in 1 2 3 4 5 6; do /usr/bin/curl -s -o /dev/null -D - https://app.nova.test/api/status | grep -iE '^(HTTP|x-backend)'; done` → 200, A and B alternate.

### S1 — Phase 1 completion as the client (CP2)
Each demo: before → broken → restored, screenshots plus `tee` text.
1. One backend stopped (Kanishk stops A): run the 6-request loop → expected six 200s, all `X-Backend: B`. `S1-01..03`.
2. Both stopped (Kanishk stops A, you stop B with `lsof -ti tcp:3002 -sTCP:LISTEN | xargs kill`): `/usr/bin/curl -si https://app.nova.test/api/status | head -6` → expected `HTTP/1.1 502 Bad Gateway`, `Server: nginx`. Restart B (S0 command). `S1-04..06`.
3. Wrong destination port (Deepanshu confirmed 8443 is unused on Mac 2): `ping -c 3 app.nova.test` works; `nc -vz -G 3 app.nova.test 8443` and `/usr/bin/curl -v --connect-timeout 5 https://app.nova.test:8443/` → expected `Connection refused`. Do not use 8080: it is open. `S1-07..08`.
4. CA trust in the Keychain: `sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain MAC_2/certs/mkcert-rootCA.crt`; verify `security verify-cert -c MAC_2/certs/mkcert-rootCA.crt` and `/usr/bin/curl -sS -o /dev/null -w '%{http_code} %{ssl_verify_result}\n' https://app.nova.test/` → `200 0`. `S1-09-ca-trust-mac4`.

### S4 — pf on Mac 4 (CP5)
`MAC_4/firewall/mac4-backend-b.pf` (one ruleset for both Extension C and E, because the standby edge is Mac 4 itself). The committed template uses `SET_MAC2_IP_FROM_S0` / `SET_MAC4_IP_FROM_S0`, which make `pfctl -n` fail until you put the real S0 IPs in. Never leave `<...>` placeholders in a pf file: pf reads `<name>` as a table and the rule would silently match nothing.
```
# Mac 4 / Backend B / TCP 3002 -- used for Extension C and E
mac2 = "<MAC2_IP>"     # primary edge
mac4 = "<MAC4_IP>"     # this Mac (self) = standby edge
pass  in quick on lo0 all
pass  in quick proto tcp from $mac4 to any port 3002
pass  in quick proto tcp from $mac2 to any port 3002
block drop in quick proto tcp from any to any port 3002
```
Meaning: the rules only filter inbound TCP to port 3002. Mac 4 reaching its own Backend B (standby nginx, or a local curl) is allowed twice on purpose: through `lo0` (where self-addressed traffic is expected to loop back) and from Mac 4's own LAN IP (in case pf sees it on en0). Which one matches is NOT VERIFIED; the counters and capture below decide it.
Read-only baseline → `S4-01-baseline.txt`: `sudo pfctl -s info`, `sudo pfctl -sr` (must contain `anchor "com.apple/*" all`), `sudo pfctl -a com.apple -s Anchors -v`, `sudo pfctl -s References`, `sudo pfctl -n -a com.apple/nova -f MAC_4/firewall/mac4-backend-b.pf; echo "parse exit=$?"` (expect 0). Stop if the anchor point is missing.
Apply:
```
sudo pfctl -a com.apple/nova -f MAC_4/firewall/mac4-backend-b.pf
sudo pfctl -E 2>&1 | tee MAC_4/evidence/phase2/S4-02-enable-token.txt
sudo pfctl -a com.apple/nova -sr -vv | tee MAC_4/evidence/phase2/S4-03-counters-before.txt
```
Proofs:
- Blocked: Hrishabh (Mac 1) `nc -vz -G 3 <MAC4_IP> 3002` → times out; Kanishk (Mac 3) the same → times out.
- Allowed: Deepanshu (Mac 2) `curl -si http://<MAC4_IP>:3002/api/status` → 200.
- Capture during the tests: `sudo tcpdump -n -k INPD -i pktap,lo0,en0 -c 30 'tcp port 3002' | tee MAC_4/evidence/phase2/S4-04-tcpdump.txt` (shows interface, process name, pid, direction).
- Self path now: `/usr/bin/curl -s http://<MAC4_IP>:3002/api/status` and `/usr/bin/curl -s http://127.0.0.1:3002/api/status` → 200; the capture shows `lo0` or `en0` and `in`/`out`.
- Counters after: `sudo pfctl -a com.apple/nova -sr -vv | tee MAC_4/evidence/phase2/S4-05-counters-after.txt` (block rule Packets up after the blocked tests; Mac 2 rule up after the allowed test; lo0 or self rule up after the self test; stateful packets count on the rule that created the state).
- Rollback test: `sudo pfctl -a com.apple/nova -F rules`; `sudo pfctl -X <token>`; `sudo pfctl -a com.apple/nova -sr` empty; `sudo pfctl -s info` as baseline; Mac 1's `nc` now succeeds. Reload the rules and `-E` again for the rest of Phase 2.
Repeat the self-path capture after S6a with the standby nginx running (`proc` shows `nginx`) → `S6-10-standby-self-path.txt`.

### S6a — Standby edge (CP7)
Preconditions: Mac 3 has the edge-tier rules loaded (CP5b); CA trusted on Mac 1 and Mac 3; Deepanshu's `nginx/nova.phase2.conf` committed.
1. Ports: `lsof -nP -iTCP -sTCP:LISTEN | grep -E ':(443|8080) '` must show nothing (Backend B on 3002 stays up).
2. `brew install nginx` (Homebrew's default `nginx.conf` listens on 8080 and loads `<BREW>/etc/nginx/servers/`).
3. Key and CSR, on Mac 4 only:
   ```
   mkdir -p ~/nova-tls && cd ~/nova-tls
   /usr/bin/openssl req -new -newkey rsa:2048 -nodes \
     -keyout app.nova.test-key.pem -out app.nova.test.csr \
     -subj "/CN=app.nova.test" -addext "subjectAltName=DNS:app.nova.test"
   chmod 600 app.nova.test-key.pem
   /usr/bin/openssl req -in app.nova.test.csr -noout -verify -text | grep -A1 "Subject Alternative Name"
   ```
   Expected `verify OK` and `DNS:app.nova.test`. Send only `app.nova.test.csr` to Deepanshu.
4. When `mac4-app.nova.test.pem` comes back, check it (save `S6-01-cert-checks.txt`, no key contents):
   ```
   cd ~/nova-tls
   /usr/bin/openssl x509 -in mac4-app.nova.test.pem -noout -ext subjectAltName          # DNS:app.nova.test
   /usr/bin/openssl x509 -in mac4-app.nova.test.pem -noout -issuer -dates                # team CA, valid now
   /usr/bin/openssl x509 -in mac4-app.nova.test.pem -noout -ext extendedKeyUsage         # TLS Web Server Authentication
   /usr/bin/openssl verify -CAfile <REPO>/MAC_2/certs/mkcert-rootCA.crt -purpose sslserver -verify_hostname app.nova.test mac4-app.nova.test.pem   # OK
   /usr/bin/openssl x509 -in mac4-app.nova.test.pem -noout -pubkey | /usr/bin/openssl dgst -sha256
   /usr/bin/openssl pkey -in app.nova.test-key.pem -pubout | /usr/bin/openssl dgst -sha256          # same hash as the line above
   security verify-cert -c mac4-app.nova.test.pem -p ssl -n app.nova.test               # success once the CA is trusted on Mac 4
   ```
   Any mismatch: stop.
5. Install: `mkdir -p "$(brew --prefix)/etc/nginx/certs"`, copy the cert to `<BREW>/etc/nginx/certs/app.nova.test.pem` and the key to `<BREW>/etc/nginx/certs/app.nova.test-key.pem`, `chmod 600` the key.
6. Standby config `MAC_4/standby_edge/nova.standby.conf` = Deepanshu's `nginx/nova.phase2.conf` with exactly one difference: `add_header X-Edge "mac4" always;` in both server blocks (same upstream `<MAC3_IP>:3001` and `<MAC4_IP>:3002`, same timeouts, same `http2 on;` if Mac 2 has it). Copy it to `<BREW>/etc/nginx/servers/nova.conf`, run `nginx -t`, start with `nginx`, check `lsof -nP -iTCP:443 -sTCP:LISTEN` and `grep -n worker_processes "$(brew --prefix)/etc/nginx/nginx.conf"`.
7. **Mandatory preflight. Every check must pass before any DNS change.** Run from Mac 1 and Mac 3 (they report to you); collect into `S6-02..S6-11`:
   - E1 Mac 4: `nginx -t` success; nginx on `*:443`.
   - E2 the step 4 certificate checks passed.
   - E3 `/usr/bin/curl -sS -o /dev/null -w '%{http_code} %{ssl_verify_result}\n' --resolve app.nova.test:443:<MAC4_IP> https://app.nova.test/api/status` → `200 0` (no `-k`).
   - E4 `/usr/bin/curl -s -D - --resolve app.nova.test:443:<MAC4_IP> https://app.nova.test/api/status` → `X-Edge: mac4`, an `X-Backend` header, body with `"status": "ok"`.
   - E5 E3 for `https://app.nova.test/` → 200.
   - E6 six E4 requests → both `X-Backend: A` and `X-Backend: B` appear. Only B means Mac 3's pf is still strict or Mac 3 is unreachable: stop.
   - E7 E4 on `/` with `-H 'If-None-Match: <ETag from E5>'` → 304 from the backend that issued that ETag.
   - E8 on the client: `security verify-cert` succeeds for the team CA.
   - E9 `openssl s_client -connect <MAC4_IP>:443 -servername app.nova.test </dev/null 2>/dev/null | openssl x509 -noout -fingerprint -sha256 -issuer` vs the same against `<MAC2_IP>` → same issuer, different fingerprints.
   - E10 if Mac 2 has HTTP/2: `--http2` shows `ALPN: server accepted h2`.
   - E11 `tail -n 30 "$(brew --prefix)/var/log/nginx/error.log"` → no new errors.
   Report the table to Kanishk. A single failure blocks the cutover (CP9).
Rollback: `nginx -s quit`; remove the copied config if asked. Backend B keeps running.

### S8 — Cutover (CP9)
Keep standby nginx running. `tail -f "$(brew --prefix)/var/log/nginx/access.log" | tee MAC_4/evidence/phase2/S8-01-mac4-access.txt` — expected: client Y's IP appears at once, client X's IP after its cache expires. Rollback after the demo: DNS back to Mac 2 (Hrishabh, Kanishk), then `nginx -s quit` only when Kanishk asks.

### S9 — Drills, S10 — Documentation
Faults to practise on Mac 4: Backend B stopped, Backend B bound to `127.0.0.1` (502 through the edge, `lsof` shows `127.0.0.1:3002`), pf blocking the edge (timeouts), wrong certificate or key (`nginx -t` key mismatch), standby on wrong port. Evidence `S9-NN-drill-<fault>.txt`. Write the learning paragraphs for Extension C (Mac 4 side) and Extension E.

## 6. Stop and ask Kanishk when
- A certificate check, key match or preflight check fails.
- Port 443 or 8080 is already in use on Mac 4.
- A pf baseline looks wrong, a command is not anchor-scoped, or the token is unknown.
- An IP differs from the inventory, or you are asked to change another Mac, share a private key, push or rewrite git history.

## 7. Report after each task
`Member / Mac / Stage / Task / Result / Time / Evidence files / Commands / Unexpected output / Commit hash / Next / Blockers`.
