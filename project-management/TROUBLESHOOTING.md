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
