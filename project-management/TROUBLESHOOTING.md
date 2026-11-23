# Fault diagnosis runbook (Extension F)

Always go top to bottom and say each result out loud, even when the cause looks obvious. The method earns marks.

| # | Layer | Question | Commands | Typical faults |
|---|---|---|---|---|
| 1 | DNS | Does the name resolve to the edge, through our servers? | `scutil --dns \| sed -n '1,12p'` · `grep -i nova /etc/hosts` · `dig @<MAC1_IP> app.nova.test` · `dig @<MAC3_IP> app.nova.test` · `dscacheutil -q host -a name app.nova.test` | dnsmasq stopped; wrong record; client DNS reset to DHCP/public (NXDOMAIN); `/etc/hosts` override (dig right, curl wrong) |
| 2 | IP / TCP | Is the host up and the port open? | `ping -c 3 <EDGE_IP>` · `nc -vz -G 3 app.nova.test 443` · on the edge: `lsof -nP -iTCP:443 -sTCP:LISTEN` | nginx stopped (refused); wrong port; pf drop (timeout); new DHCP address or other Wi-Fi |
| 3 | TLS | Does the certificate verify without `-k`? | `openssl s_client -connect app.nova.test:443 -servername app.nova.test </dev/null` · `/usr/bin/curl -sS -o /dev/null -w '%{http_code} %{ssl_verify_result}\n' https://app.nova.test/` | CA not trusted (curl error 60); name not in SAN; wrong cert/key path; expired cert |
| 4 | HTTP / nginx | Does the edge answer and reach an upstream? | `/usr/bin/curl -si https://app.nova.test/api/status \| head -8` · `nginx -t` · `tail -n 30 <BREW>/var/log/nginx/error.log` | 502 (no live upstreams, wrong upstream port); `proxy_pass https://` typo; syntax error (old config stays live); `server_name` changed |
| 5 | Application | Is the backend listening on the LAN? | `lsof -nP -iTCP:3001 -sTCP:LISTEN` · from Mac 2: `curl -si http://<MAC3_IP>:3001/api/status` · `tail server.log` | Backend stopped; bound to 127.0.0.1; frozen process; pf blocking the edge |

## Drill log (S9)

| Date | Fault injected (by) | Diagnosed by | Layer found | Root cause | Fix | Verification | Evidence file |
|---|---|---|---|---|---|---|---|
| | | | | | | | |

## S9 fault drills (23 Nov 2026, 22:30–22:38)

Diagnosis order: DNS → TCP → TLS → HTTP → edge-to-backend. Same `diag` function on every Mac (flush cache, ask both DNS servers, `nc` 443, certificate subject, four `curl` probes with X-Edge / X-Backend).

| # | Layer | Injected by | Fault | Diagnosed by | What `diag` showed | Rollback |
|---|---|---|---|---|---|---|
| 1 | DNS | Hrishabh (Mac 1) | primary record → 192.0.2.10 | Adarsh (Mac 4) | @Mac 1 → 192.0.2.10, @Mac 3 → 10.7.5.201; client used the wrong one (primary answered, so the backup is never asked); curl timeout 10 s | record restored, `dig` → 10.7.5.201 |
| 2 | TCP / edge | Deepanshu (Mac 2) | nginx stopped | Hrishabh (Mac 1) | DNS correct; TCP 443 FAILED; curl (7) Couldn't connect after ~1 s | nginx started; 200 mac2 |
| 3 | TLS | Deepanshu (Mac 2) | certificate for `wrong.nova.test` | Kanishk (Mac 3) | DNS, TCP ok; curl (60) no subject name matches `app.nova.test` | config restored; 200, verify 0 |
| 4 | Firewall edge → backend | Kanishk (Mac 3) | t3-fault pf rules (Mac 2 blocked from A:3001) | Deepanshu (Mac 2) | users still get 200, but only X-Backend B, one request 2.08 s; `nc` edge→A FAILED; nginx error log "upstream timed out … connecting to upstream 10.7.1.218:3001" | edge-tier rules reloaded |

Note: in drill 1, `nc -z` reported 443 "open" for the unreachable 192.0.2.10 from Mac 4 while curl timed out; treat the curl result as authoritative (the campus network may answer SYNs it cannot deliver).

Final state 22:38: both DNS servers → 10.7.5.201 (TTL 30); Mac 2 edge and Mac 4 edge each return 200 with both A and B.
