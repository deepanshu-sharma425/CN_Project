# Team Nova — Claude Code brief for Hrishabh (Mac 1, primary DNS)

You are helping Hrishabh Prajapati, owner of **Mac 1** in Team Nova's Computer Networks project (Private Network Service Platform, domain `app.nova.test`). Work only on Mac 1. Never change another member's Mac. Phase 1 already exists; do not rebuild it.

## 1. Identity and role
- Member: Hrishabh Prajapati (2401020027). Machine: Mac 1.
- Role: primary DNS server (dnsmasq), DNS records, the 30-second TTL, the DNS changes for the standby-edge cutover, DNS failure demonstrations, DNS logs and evidence. Mac 1 is also a test client (blocked client in the firewall tests, cached client "X" in the cutover test).
- Coordinator: Kanishk (Mac 3). Approvals come from Kanishk as recorded checkpoints (CP). Primary edge: Deepanshu (Mac 2). Standby edge: Adarsh (Mac 4). Backup DNS: Kanishk (Mac 3).

## 2. Ground rules (apply to every step)
1. Start every session with read-only inspection. Never assume an IP is current: use only the values in `project-management/IP_INVENTORY.md` once S0 is approved. Until then every IP is NOT VERIFIED.
2. Placeholders: `<MAC1_IP>`, `<MAC2_IP>`, `<MAC3_IP>`, `<MAC4_IP>` = verified IPs from the inventory. `<WIFI_SERVICE>` = the Wi-Fi service name printed by `networksetup -listallnetworkservices` (often `Wi-Fi`). `<BREW>` = output of `brew --prefix`.
3. A command that changes anything (files outside the repo, services, DNS settings, trust store) runs only after its checkpoint is recorded as approved. Read-only commands are always allowed.
4. Before editing `<BREW>/etc/dnsmasq.conf`, make a timestamped copy: `cp "$(brew --prefix)/etc/dnsmasq.conf" ~/nova-backups/dnsmasq.conf.$(date +%Y%m%d-%H%M%S)` (run `mkdir -p ~/nova-backups` once).
5. Check the file owner first: `ls -l "$(brew --prefix)/etc/dnsmasq.conf"`. If it belongs to you, edit it **without sudo** (sudo with `sed -i` can leave the file owned by root).
6. After any config edit run `"$(brew --prefix)/sbin/dnsmasq" --test -C "$(brew --prefix)/etc/dnsmasq.conf"` (expected: `dnsmasq: syntax check OK.`, exit 0). dnsmasq does not re-read its main config on SIGHUP, so restart: `sudo brew services restart dnsmasq`.
7. There must be exactly one `address=` line per name. Check with `grep -n '^address=' "$(brew --prefix)/etc/dnsmasq.conf"`. Two lines with different IPs make dnsmasq return both.
8. Record what actually happened, with timestamps. Never write "passed" without saved evidence. If a result differs from the expected one, stop and report.
9. Never commit secrets. Never run `git push`, `--force`, `commit --amend`, `rebase`, `reset` or `merge` unless Kanishk records that approval.

## 3. Files to inspect first (read-only)
- `README.md`, `MAC_1/dnsmasq.conf` (Phase 1 config: the default file plus 3 lines at the end), `MAC_1/evidence/` (Phase 1 screenshots, `wireshark_dns.pcapng`).
- `project-management/IP_INVENTORY.md`, `project-management/PROJECT_STATUS.md`, `project-management/status/hrishabh.json` (created at CP0).
- The installed config: `"$(brew --prefix)/etc/dnsmasq.conf"`.

## 4. Repository and status workflow
- Repo: `https://github.com/deepanshu-sharma425/CN_Project`, branch `phase2` (created by Kanishk at CP0). Get it with `git fetch origin && git switch phase2 && git pull --ff-only origin phase2`. If the branch is not on the remote yet, stop: the push of `phase2` needs its own approval.
- Evidence path convention: `MAC_1/evidence/phase2/S<stage>-<NN>-<slug>.<ext>` and, for Phase 1 completion, `MAC_1/evidence/phase1-completion/S1-<NN>-<slug>.<ext>`. Save terminal output with `| tee <file>.txt` as well as a screenshot.
- Status: edit only `project-management/status/hrishabh.json`. Fields: `member, mac, stage, task, status, latestTest, evidence[], commit, blockers[], next, updated` (ISO time with +05:30). Status words: Not started, Ready, In progress, Waiting for approval, Blocked, Testing, Failed, Passed, Committed, Verified.
- Commit procedure after a stage is approved as complete:
  1. `git pull --ff-only origin phase2`
  2. `git status` and `git diff` — check only your intended files changed.
  3. `git add <exact paths>` (never `git add -A`). Never add `*.pem`, `*-key.pem`, `*.csr`, `rootCA*`, `~/nova-backups/*`.
  4. `git commit -m "<message from the plan>"`
  5. `git log -1 --format='%h %s'` → put the hash in your status file and report it.
  6. Push only when Kanishk records the push approval for that commit.

## 5. Tasks in order

### S0 — Network re-baseline (read-only first; changes need CP1)
Read-only (save as `MAC_1/evidence/phase2/S0-01-inventory.txt`):
```
date
ipconfig getifaddr en0
ifconfig en0 | grep -E 'ether|inet '
route -n get default | grep -E 'gateway|interface'
networksetup -listallnetworkservices
networksetup -getdnsservers "<WIFI_SERVICE>"
scutil --dns | sed -n '1,20p'
grep -i nova /etc/hosts || echo "no nova entries in /etc/hosts"
/usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate
/usr/libexec/ApplicationFirewall/socketfilterfw --getstealthmode
sudo pfctl -s info | head -3
sudo lsof -nP -iUDP:53
sudo lsof -nP -iTCP:53 -sTCP:LISTEN
brew --prefix
"$(brew --prefix)/sbin/dnsmasq" --version | head -1
ls -l "$(brew --prefix)/etc/dnsmasq.conf"
grep -nE '^(address|listen-address|local-ttl|no-resolv|server|local|log-)' "$(brew --prefix)/etc/dnsmasq.conf"
dig @127.0.0.1 app.nova.test +noall +answer +comments
```
Then ping each other Mac at the address its owner reports: `ping -c 3 <IP>`.
Report to Kanishk: IP, MAC address, gateway, Wi-Fi service name, DNS list, stealth mode, pf status, dnsmasq version, listening sockets, current `address=`/`listen-address=` lines.
**Stop** until all four inventories are in `IP_INVENTORY.md`.

CP1 changes (only if Mac 1's IP or Mac 2's IP differ from the config):
1. Backup (rule 4).
2. Edit the project block so it reads `address=/app.nova.test/<MAC2_IP>`, `address=/api.nova.test/<MAC2_IP>`, `listen-address=127.0.0.1,<MAC1_IP>`.
3. `--test`, then `sudo brew services restart dnsmasq`.
4. Verify: `sudo lsof -nP -iUDP:53` shows `<MAC1_IP>:53` and `127.0.0.1:53`; `dig @<MAC1_IP> app.nova.test +noall +answer` returns `<MAC2_IP>`.
Rollback: copy the backup back, `--test`, restart.

### S1 — Phase 1 completion (CP2)
1. CA trust on Mac 1 (Mac 1 is a client): from the repo root, `sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain MAC_2/certs/mkcert-rootCA.crt`. Verify `security verify-cert -c MAC_2/certs/mkcert-rootCA.crt` (expected: success, not `CSSMERR_TP_NOT_TRUSTED`) and `/usr/bin/curl -sS -o /dev/null -w '%{http_code} %{ssl_verify_result}\n' https://app.nova.test/` (expected `200 0`). Evidence `S1-01-ca-trust-mac1`. Rollback (only if told): `sudo security remove-trusted-cert -d MAC_2/certs/mkcert-rootCA.crt`.
   Note: for this test Mac 1's own resolver must reach a DNS server that knows the name. Check `scutil --dns`.
2. Confirm the two Phase 1 DNS failure demos still match today's network (wrong DNS server, wrong record). Re-run them only if Kanishk asks (CP2). Same before / broken / restored procedure as `MAC_1/evidence/MAC1_SS08*`.

### S3 — Extension A support (CP4)
Official requirement: a second resolver on another Mac (Mac 3), clients list both, stop dnsmasq on Mac 1 and show clients still resolve, explain DNS failure vs application failure.
1. Add to Mac 1's project block (backup first; `--test`; restart):
   ```
   no-resolv
   server=8.8.8.8
   local=/nova.test/
   log-queries=extra
   log-facility=<BREW>/var/log/dnsmasq-nova.log
   ```
   Why: once Mac 1 lists itself as a DNS server, forwarding to `/etc/resolv.conf` could loop back to itself. `local=/nova.test/` keeps project names local. 8.8.8.8 answered from this network on 23 Nov (NOT VERIFIED today: check `dig @8.8.8.8 example.com`).
   Verify: `dig @<MAC1_IP> app.nova.test` still returns `<MAC2_IP>`; `dig @<MAC1_IP> example.com` returns NOERROR. If the log file stays empty, use `log show --last 5m --predicate 'process == "dnsmasq"'` instead and report it.
2. Set Mac 1's own resolver list to exactly the two project servers: `sudo networksetup -setdnsservers "<WIFI_SERVICE>" <MAC1_IP> <MAC3_IP>`, then flush `sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder`. Save the old list from S0 for rollback.
3. Failover test (Deepanshu runs the client capture on Mac 2; you only act on Mac 1, on Kanishk's signal):
   - `stealth mode` must be off for a fast ICMP refusal; report what S0 showed.
   - Stop: `sudo brew services stop dnsmasq`. Verify: `sudo lsof -nP -iUDP:53` prints nothing. Note the time (`date +%T`).
   - Wait for Deepanshu to finish. Restart: `sudo brew services start dnsmasq`. Verify with `dig @<MAC1_IP> app.nova.test`.
   - Evidence: `S3-01-primary-stopped.png`, `S3-02-primary-restored.png`, `S3-03-dnsmasq-log.txt`.
   Do not describe the failover as automatic or ordered. Report only what the client capture showed.

### S4 — Extension C blocked-client tests (Kanishk's CP5)
From Mac 1, while the strict rules are loaded on Mac 3 and Mac 4:
```
ping -c 3 <MAC3_IP>
nc -vz -G 3 <MAC3_IP> 3001     # expected: times out
nc -vz -G 3 <MAC4_IP> 3002     # expected: times out
/usr/bin/curl -sS -o /dev/null -w '%{http_code}\n' https://app.nova.test/   # expected: 200
```
After rollback (negative control P10) repeat the two `nc` lines: expected `succeeded`. Evidence `S4-01-blocked-from-mac1.txt`, `S4-02-after-rollback-mac1.txt`.

### S7 — Extension B TTL (CP8) — after S3 and S6a
Official requirement: short TTL (about 30 s), change the record, client keeps old answer until expiry, manual flush shows the change, explain migration and cutover.
1. Backup, add `local-ttl=30` to the project block, `--test`, restart. Restart Mac 1 and Mac 3 **one at a time**, a few seconds apart (coordinate with Kanishk).
2. Verify: `dig @<MAC1_IP> app.nova.test +noall +answer` → `app.nova.test. 30 IN A <MAC2_IP>`. Fallback if the TTL is still 0: replace the `address=/app.nova.test/` line with `host-record=app.nova.test,<MAC2_IP>,30` and report it.
3. Record change for the demo (only on Kanishk's signal, Mac 1 then Mac 3):
   ```
   sed -i '' -e 's#^address=/app\.nova\.test/<MAC2_IP_ESCAPED>$#address=/app.nova.test/<MAC4_IP>#' "$(brew --prefix)/etc/dnsmasq.conf"
   ```
   `<MAC2_IP_ESCAPED>` is Mac 2's IP with each dot written as `\.`. Then `grep -n '^address=' ...` (one line per name), `--test`, `sudo brew services restart dnsmasq`, `dig @<MAC1_IP> app.nova.test +noall +answer` → `<MAC4_IP>`.
4. Restore with the reverse `sed`, `--test`, restart, `dig`.
5. Evidence: `S7-01-ttl30-dig-mac1.png`, `S7-02-record-changed-mac1.png`, `S7-03-record-restored-mac1.png`.
Do not use `dig @server` as proof of client caching. dig skips the client cache. The caching proof is Deepanshu's resolver loop and capture.

### S8 — Extension E cutover (CP9) — only after the S6a preflight passed
1. On Kanishk's signal change `app.nova.test` to `<MAC4_IP>` on Mac 1 (same `sed` as S7), then Kanishk does Mac 3.
2. You are client X (cached). Before the change, resolve once so the old answer is cached, then start:
   ```
   while true; do printf "%s " "$(date +%T)"; /usr/bin/curl -s -o /dev/null -D - https://app.nova.test/api/status | grep -iE '^x-(edge|backend)' | tr -d '\r' | tr '\n' ' '; echo; sleep 3; done | tee MAC_1/evidence/phase2/S8-01-client-x-loop.txt
   ```
   Run Wireshark on en0 with display filter `dns.qry.name == "app.nova.test" || tcp.port == 443`; save `S8-02-client-x.pcapng`.
3. Expected: `X-Edge: mac2` until the cached entry expires (about 30 s after your last lookup), then `X-Edge: mac4`. Record the real switch time.
4. Rollback on signal: reverse `sed`, restart, flush clients.

### S9 — Extension F drills
Learn the diagnosis order: DNS → TCP → TLS → HTTP/nginx → application. Practise on faults another member injects on your Mac (always with an undo step agreed beforehand). Your likely faults: dnsmasq stopped, record pointing to a wrong IP, `listen-address` wrong, client DNS reset to DHCP (`Empty`) which brings back public servers that answer NXDOMAIN, an `/etc/hosts` override.
Key commands: `scutil --dns`, `grep nova /etc/hosts`, `dig @<MAC1_IP>`, `dig @<MAC3_IP>`, `dscacheutil -q host -a name app.nova.test`, `ping`, `nc -vz -G 3 app.nova.test 443`, `openssl s_client -connect app.nova.test:443 -servername app.nova.test </dev/null`, `curl -sv https://app.nova.test/api/status`.
Evidence: `S9-NN-drill-<fault>.txt` with symptom, command, output, layer, cause, fix, verification.

### S10 — Documentation
Write the learning paragraphs for Extensions A and B (DNS failure vs application failure; TTL and DNS-based migration), and list your evidence files for the evidence index.

## 6. Stop and ask Kanishk when
- Any IP differs from the inventory, or Wi-Fi changed.
- `dnsmasq --test` fails, dnsmasq will not start, or port 53 is taken by something else.
- A `dig` answer, TTL or log differs from the expected result.
- You are asked to change another Mac, push, or run any git history command.
- Any step would happen before its checkpoint is recorded as approved.

## 7. What to report after each task
`Member / Mac / Stage / Task / Result (Passed|Failed|Blocked) / Exact time / Evidence files / Commands run / Unexpected output / Commit hash (if any) / Next action / Blockers`.
