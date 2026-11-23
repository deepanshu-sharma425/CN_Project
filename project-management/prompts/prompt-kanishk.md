# Team Nova — Claude Code brief for Kanishk (Mac 3, Backend A, backup DNS, coordinator)

You are helping Kanishk Sharma, owner of **Mac 3** and coordinator of Team Nova's Computer Networks project (Private Network Service Platform, domain `app.nova.test`). On Mac 3 you implement; for the team you coordinate, approve checkpoints, aggregate status and integrate evidence. Never change another member's Mac. Phase 1 exists; do not rebuild it.

## 1. Identity and role
- Member: Kanishk Sharma (2401010207). Machine: Mac 3.
- Mac 3 role: Backend A (Node.js, TCP 3001), backup DNS (dnsmasq, Extension A), pf firewall on Mac 3 (strict, edge-tier and T3 fault rulesets), freezing/stopping Backend A for the T2/T3/failover tests, DNS changes on the backup server, client "Y" in the cutover.
- Coordinator role: CP0 repository setup, recording approvals (CP0–CP12), the IP inventory, aggregating status, keeping the dashboard in sync, the evidence index, the final report.
- Do not trust the historical Mac 3 IP. Repo and reports say 10.7.19.171 (earlier 10.7.2.229). A read-only audit on 23 Nov 2026 saw **10.7.1.218**. Use only what S0 records.

## 2. Known facts from the 23 Nov read-only audit (re-check them in S0)
- This Mac's DNS list was `10.7.8.113, 1.1.1.1, 8.8.8.8` (set manually). The public servers answer NXDOMAIN for `.test`; mDNSResponder held a cached "No Such Record" for `app.nova.test` with TTL 108002 s. It must be flushed after the DNS list is fixed.
- `security verify-cert -c MAC_2/certs/mkcert-rootCA.crt` returned `CSSMERR_TP_NOT_TRUSTED`: Mac 3 does not trust the team CA yet.
- Application Firewall off, stealth mode off. No listener on UDP 53. Backend A not running. dnsmasq and nginx not installed. `uname -m` = arm64, Homebrew at `/opt/homebrew`.
- `/etc/pf.conf` is Apple's default with `anchor "com.apple/*"`; `/etc/pf.anchors/com.apple` holds `anchor "200.AirDrop/*"` and `anchor "250.ApplicationFirewall/*"`. pf enabled/disabled state: NOT VERIFIED (needs sudo).
- Git: branch `main` = `origin/main` = `0e73d8a`; untracked: `report/` sources, PDFs, scripts, `img/`. Remote `https://github.com/deepanshu-sharma425/CN_Project` (Deepanshu's account). Whether every member can push: NOT VERIFIED.

## 3. Ground rules
1. Read-only first. Changes only after the checkpoint is recorded as approved (the dashboard's Approval center records decisions; it never runs anything).
2. Placeholders `<MAC1_IP>`…`<MAC4_IP>`, `<WIFI_SERVICE>`, `<BREW>` come from S0.
3. pf safety (never break these):
   - Never `pfctl -f <file>` without `-a com.apple/nova`. Never `pfctl -a com.apple -f`. Never `pfctl -F …` without `-a`.
   - Roll back with `sudo pfctl -a com.apple/nova -F rules` (not `-F all`: that also flushes the system-wide state table and statistics).
   - Never `pfctl -d`, `pfctl -e`, `pfctl -z`, `pfctl -F states`, `pfctl -k`, or `pfctl -f /etc/pf.conf`.
   - Enable with `sudo pfctl -E` and keep the token; recover a lost token with `sudo pfctl -s References`; release with `sudo pfctl -X <token>`.
   - Compare counters before and after; never reset them.
4. Backups before editing any installed config: `mkdir -p ~/nova-backups && cp <file> ~/nova-backups/<name>.$(date +%Y%m%d-%H%M%S)`.
5. Record actual behaviour with timestamps; a failed or unexpected result stops every dependent stage.
6. No `git push`, `--force`, `commit --amend`, `rebase`, `reset`, `merge`, branch deletion without a recorded approval. Never commit keys, CSRs or `~/nova-backups`.

## 4. Coordinator tasks

### CP0 — Repository setup (needs approval; local only)
```
git status
git switch -c phase2
mkdir -p project-management/status MAC_3/firewall MAC_3/backup_dns MAC_4/firewall MAC_4/standby_edge
```
Create:
- `project-management/PROJECT_STATUS.md` (human summary, generated from the JSON).
- `project-management/project-status.json` (aggregate; same schema the dashboard reads: `schema, asOf, source, currentStage, nextMilestone, inventory, members, tasks, requirements, commits`).
- `project-management/status/{hrishabh,deepanshu,kanishk,adarsh}.json` (each member edits only their own file; this avoids merge conflicts).
- `project-management/IP_INVENTORY.md` (all values `NOT VERIFIED` until S0).
- `project-management/EVIDENCE_INDEX.md`, `project-management/APPROVALS.md`, `project-management/TROUBLESHOOTING.md`.
- `MAC_3/firewall/mac3-backend-a.strict.pf`, `mac3-backend-a.edgetier.pf`, `mac3-backend-a.t3-fault.pf`, `MAC_4/firewall/mac4-backend-b.pf`, `MAC_3/firewall/ROLLBACK.md` (contents in S4/S5 below, placeholders kept until S0).
- Add the untracked `report/` sources (not machine secrets) as their own commit.
Commits: `chore: add phase 2 project management scaffold`, then `docs: add phase 1 report sources`. Do not push. The push of `phase2` (so others can pull) is a separate approval (CP0-push), and so is every later push.

### Status aggregation and the dashboard
After each member's commit: `git pull --ff-only origin phase2`, merge their `status/<member>.json` values into `project-status.json`, regenerate `PROJECT_STATUS.md`, commit `chore: update project status (<stage>)`. Then either paste `project-status.json` into the dashboard's "Load status" box, or ask Claude in this session to write it to the dashboard's shared store. The dashboard shows only what was loaded and when (`asOf`); it never monitors Macs.

### Approvals
Record each checkpoint in the dashboard (approved / declined, with a note) and in `APPROVALS.md` (date, who, scope). Never approve a stage whose preconditions are not met (see the roadmap).

## 5. Mac 3 tasks in order

### S0 — Re-baseline (read-only, then CP1)
Save `MAC_3/evidence/phase2/S0-01-inventory.txt`:
```
date
ipconfig getifaddr en0
ifconfig en0 | grep -E 'ether|inet '
route -n get default | grep -E 'gateway|interface'
networksetup -listallnetworkservices
networksetup -getdnsservers "<WIFI_SERVICE>"
scutil --dns | sed -n '1,20p'
grep -i nova /etc/hosts || echo "no nova entries"
dns-sd -G v4 app.nova.test    # stop with Ctrl-C after 3 s; shows cached answer or "No Such Record"
/usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate
/usr/libexec/ApplicationFirewall/socketfilterfw --getstealthmode
sudo pfctl -s info | head -3
sudo lsof -nP -iUDP:53
sudo lsof -nP -iTCP:53 -sTCP:LISTEN
lsof -nP -iTCP:3001 -sTCP:LISTEN
security verify-cert -c MAC_2/certs/mkcert-rootCA.crt
node -v
```
Collect the other three inventories; write `IP_INVENTORY.md`; commit `docs: add verified network inventory` after all four are in.
CP1 changes on Mac 3: `sudo networksetup -setdnsservers "<WIFI_SERVICE>" <MAC1_IP>` (old list saved above for rollback), flush `sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder`, re-run `dns-sd -G v4 app.nova.test` (expect `<MAC2_IP>`, not "No Such Record"). Start Backend A:
```
cd MAC_3/Backend_A
lsof -ti tcp:3001 -sTCP:LISTEN | xargs kill; sleep 1
nohup node server.js >> server.log 2>&1 &
lsof -nP -iTCP:3001 -sTCP:LISTEN     # expected: TCP *:3001 (LISTEN)
curl -si http://<MAC3_IP>:3001/api/status | head -5   # expected: 200, X-Backend: A
```

### S1 — Phase 1 completion (CP2)
1. CA trust: `sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain MAC_2/certs/mkcert-rootCA.crt`; verify `security verify-cert -c MAC_2/certs/mkcert-rootCA.crt` succeeds and `/usr/bin/curl -sS -o /dev/null -w '%{http_code} %{ssl_verify_result}\n' https://app.nova.test/` → `200 0`. Evidence `S1-01-ca-trust-mac3`.
2. One backend stopped: on signal `lsof -ti tcp:3001 -sTCP:LISTEN | xargs kill`; Adarsh's client loop shows only B; restart with the S0 command. Both stopped: same, together with Adarsh stopping B → 502. Evidence: before / broken / restored on the client side; Mac 3 side `S1-02-backend-a-stopped.txt`.

### S2 — T2 frozen backend (CP3)
On Deepanshu's signal: `PID=$(lsof -ti tcp:3001 -sTCP:LISTEN); echo $PID; kill -STOP $PID` → he runs the timing loop → `kill -CONT $PID`. Verify after: `curl -si http://<MAC3_IP>:3001/api/status | head -3`. The frozen process keeps its listening socket, so the kernel still completes TCP handshakes (assumption to confirm from nginx's error line). Evidence `S2-01-freeze-resume.txt` with timestamps. Also stop/restart A for the Doc demo.

### S3 — Backup DNS (CP4)
1. Preconditions: UDP and TCP 53 free (`sudo lsof -nP -iUDP:53`, `sudo lsof -nP -iTCP:53 -sTCP:LISTEN` print nothing).
2. `brew install dnsmasq`. Backup `<BREW>/etc/dnsmasq.conf`. Append:
   ```
   # --- Project Nova Phase 2 (Mac 3 backup DNS) ---
   address=/app.nova.test/<MAC2_IP>
   address=/api.nova.test/<MAC2_IP>
   listen-address=127.0.0.1,<MAC3_IP>
   no-resolv
   server=8.8.8.8
   local=/nova.test/
   log-queries=extra
   log-facility=<BREW>/var/log/dnsmasq-nova.log
   ```
   `"$(brew --prefix)/sbin/dnsmasq" --test -C "$(brew --prefix)/etc/dnsmasq.conf"` → `syntax check OK.`; `sudo brew services start dnsmasq`.
3. Verify: `sudo lsof -nP -iUDP:53` shows `<MAC3_IP>:53`; `dig @<MAC3_IP> app.nova.test` → NOERROR, `aa`, `<MAC2_IP>`; `dig @<MAC3_IP> example.com` → NOERROR. If the log stays empty, use `log show --last 5m --predicate 'process == "dnsmasq"'`.
4. Mac 3 resolver: `sudo networksetup -setdnsservers "<WIFI_SERVICE>" <MAC1_IP> <MAC3_IP>`; flush.
5. During Deepanshu's failover test, save the backup's log lines showing Mac 2's queries → `S3-01-backup-log.txt`. The pass/fail rule belongs to the client capture: the answer must come from `<MAC3_IP>`. Never write "automatic failover" unless that capture shows it.
Rollback: `sudo brew services stop dnsmasq`; restore the config backup; clients back to Mac 1 only; flush.

### S4 — pf on Mac 3 (CP5, then CP5b)
Files (real IPs in place of placeholders before loading). Warning: in pf, `<name>` means a table, so a leftover `"<MAC2_IP>"` would parse as an empty table and silently block Mac 2. The committed templates therefore use `SET_MAC2_IP_FROM_S0`-style placeholders, which make `pfctl -n` fail until real IPs are filled in:
`MAC_3/firewall/mac3-backend-a.strict.pf`
```
# Mac 3 / Backend A / TCP 3001 -- STRICT (Extension C demo)
mac2 = "<MAC2_IP>"     # primary edge
mac3 = "<MAC3_IP>"     # this Mac (self)
pass  in quick on lo0 all
pass  in quick proto tcp from $mac3 to any port 3001
pass  in quick proto tcp from $mac2 to any port 3001
block drop in quick proto tcp from any to any port 3001
```
`MAC_3/firewall/mac3-backend-a.edgetier.pf`
```
# Mac 3 / Backend A / TCP 3001 -- EDGE-TIER (Extension E)
mac2 = "<MAC2_IP>"     # primary edge
mac3 = "<MAC3_IP>"     # this Mac (self)
mac4 = "<MAC4_IP>"     # standby edge
pass  in quick on lo0 all
pass  in quick proto tcp from $mac3 to any port 3001
pass  in quick proto tcp from { $mac2, $mac4 } to any port 3001
block drop in quick proto tcp from any to any port 3001
```
Read-only baseline first (save each to `MAC_3/evidence/phase2/S4-01-baseline.txt`):
```
sudo pfctl -s info                       # B1 enabled or disabled
sudo pfctl -sr                           # B2 must contain: anchor "com.apple/*" all
sudo pfctl -a com.apple -s Anchors       # B3
sudo pfctl -a com.apple -s Anchors -v    # B4 then: sudo pfctl -a <each> -sr
sudo pfctl -s References                 # B5
sudo pfctl -n -a com.apple/nova -f MAC_3/firewall/mac3-backend-a.strict.pf ; echo "parse exit=$?"   # B7 expect 0
```
Stop if B2 lacks the anchor point, or if B4 shows Apple rules that look like they would block traffic once pf is enabled.
CP5 apply:
```
sudo pfctl -a com.apple/nova -f MAC_3/firewall/mac3-backend-a.strict.pf
sudo pfctl -E 2>&1 | tee MAC_3/evidence/phase2/S4-02-enable-token.txt     # note the Token
sudo pfctl -s info | head -3                   # P4: Status: Enabled
sudo pfctl -a com.apple -s Anchors             # P2: nova listed
sudo pfctl -a com.apple/nova -sr -vv | tee MAC_3/evidence/phase2/S4-03-counters-before.txt
```
Wait at least 10 s (or ask Deepanshu to `nginx -s reload`), then the proofs:
- P6 Hrishabh (Mac 1): `nc -vz -G 3 <MAC3_IP> 3001` times out, `ping` works.
- P7 Deepanshu (Mac 2): `curl -si http://<MAC3_IP>:3001/api/status` → 200.
- P8 on Mac 3 during P6/P7: `sudo tcpdump -n -k IPD -i pktap,en0 -c 20 'tcp port 3001' | tee MAC_3/evidence/phase2/S4-04-tcpdump.txt` (Mac 1 SYNs arrive with no SYN-ACK; Mac 2 gets SYN-ACK).
- P5: `sudo pfctl -a com.apple/nova -sr -vv | tee MAC_3/evidence/phase2/S4-05-counters-after.txt` (block rule Packets up after P6; Mac 2 rule Packets/States up after P7. Packets passed statefully count on the rule that created the state).
- Self path: on Mac 3 `curl -s http://<MAC3_IP>:3001/api/status` and `curl -s http://127.0.0.1:3001/api/status` both 200; counters show whether the lo0 rule or the self-IP rule matched (`-k IPD` capture on `pktap,lo0,en0` shows the interface and direction).
- P9: `https://app.nova.test` still works from a client.
- P10 rollback test: `sudo pfctl -a com.apple/nova -F rules`, `sudo pfctl -X <token>`, `sudo pfctl -a com.apple/nova -sr` (empty), `sudo pfctl -s info` (matches baseline); Hrishabh's `nc` now succeeds. Then reload strict and `-E` again for the demo.
CP5b: `sudo pfctl -a com.apple/nova -f MAC_3/firewall/mac3-backend-a.edgetier.pf` (replaces the anchor's rules), check `-sr -vv`, and confirm from Mac 4 (Adarsh) `curl -si http://<MAC3_IP>:3001/api/status` → 200.
`MAC_3/firewall/ROLLBACK.md` must list: the token, the exact rollback lines above, and "a reboot also clears the anchor (assumption)".

### S5 — T3 silent drop (CP6) — after S4 proofs passed
`MAC_3/firewall/mac3-backend-a.t3-fault.pf`
```
# Mac 3 / Backend A -- T3 FAULT: nobody but Mac 3 itself reaches 3001; drops are silent
mac3 = "<MAC3_IP>"
pass  in quick on lo0 all
pass  in quick proto tcp from $mac3 to any port 3001
block drop in quick proto tcp from any to any port 3001
```
On Deepanshu's signal: `sudo pfctl -a com.apple/nova -f MAC_3/firewall/mac3-backend-a.t3-fault.pf` → he times Phase 1 baseline and Phase 2 configs → restore at once with `sudo pfctl -a com.apple/nova -f MAC_3/firewall/mac3-backend-a.edgetier.pf` → verify Mac 2 gets 200 from `http://<MAC3_IP>:3001/api/status`. Evidence `S5-01-t3-fault-load.txt`, `S5-02-t3-restored.txt`.

### S7 — TTL on the backup (CP8)
Backup, add `local-ttl=30`, `--test`, `sudo brew services restart dnsmasq` (a few seconds after Hrishabh, never together), `dig @<MAC3_IP> app.nova.test +noall +answer` → TTL 30. Record changes with the same escaped `sed` as Mac 1 (no sudo if the file is yours), always right after Hrishabh, then `dig`. Restore afterwards. Evidence `S7-01..03`.

### S8 — Cutover (CP9) — only after the S6a preflight passed
Change the record on Mac 3 right after Hrishabh. Then as client Y: flush, `/usr/bin/curl -s -D - https://app.nova.test/api/status | grep -iE '^x-(edge|backend)'` → expected `X-Edge: mac4` at once. Evidence `S8-01-client-y.txt`. Rollback: reverse `sed`, restart, flush.

### S9 — Drills, S10 — Report
Run the fault drills (DNS → TCP → TLS → HTTP/nginx → application) and write `TROUBLESHOOTING.md`. Build the Phase 2 report with the existing method (`report/*.html` + `bash report/build.sh`): what changed from Phase 1, resilience tests and results, troubleshooting findings, one learning paragraph per extension. Fill `EVIDENCE_INDEX.md` so any proof is found within 30 s. Final commits `docs: complete phase 2 report and evidence index`; the merge to `main` and the push are CP12.

## 6. Stop and ask (or record a block) when
- Any member's result contradicts the expected one, a preflight check fails, or an IP changed.
- pf baseline B2/B4 looks wrong, a pf command is not anchor-scoped, or a token is unknown.
- A request would touch another member's Mac, push, or rewrite git history.

## 7. Member report format you collect
`Member / Mac / Stage / Task / Result / Time / Evidence files / Commands / Unexpected output / Commit hash / Next / Blockers`.
