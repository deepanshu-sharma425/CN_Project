# IP inventory

Filled in during **S0**. Until every row below is VERIFIED, no command or configuration may use these addresses. Historical values are for reference only.

Network (Phase 1): 10.7.0.0/19, gateway 10.7.0.1. Re-check in S0.

| Mac | Owner | Current IPv4 (S0) | Interface | MAC address | Gateway | Wi-Fi service name | DNS list (before CP1) | Stealth mode | pf status | Verified at |
|---|---|---|---|---|---|---|---|---|---|---|
| Mac 1 | Hrishabh | **10.7.22.124** (/19) | en0 | 1e:8c:55:4b:35:a2 (private Wi-Fi address) | 10.7.0.1 | Wi-Fi (also has Turbo VPN, ProtonVPN services) | none set (DHCP) | off (Application Firewall off) | Disabled | 23 Nov 2026 19:30 |
| Mac 2 | Deepanshu | **10.7.5.201** (/19) | en0 | 92:a5:f5:2b:e4:92 (private Wi-Fi address) | 10.7.0.1 | Wi-Fi | 10.7.8.113, 1.1.1.1, 8.8.8.8 | off (Application Firewall **on**) | Disabled | 23 Nov 2026 19:31 |
| Mac 3 | Kanishk | **10.7.1.218** (/19) | en0 | 9a:b1:82:93:2e:f8 | 10.7.0.1 | Wi-Fi | 10.7.8.113, 1.1.1.1, 8.8.8.8 | off (Application Firewall off) | Disabled, no references | 23 Nov 2026 19:27 / 19:30 |
| Mac 4 | Adarsh | **10.7.27.160** (/19) | en0 | 42:86:29:f1:ec:e4 (private Wi-Fi address) | 10.7.0.1 | Wi-Fi | 10.7.8.113, 8.8.8.8, 1.1.1.1 | off (Application Firewall **on**) | **Enabled for 28 days** (by another component, to identify) | 23 Nov 2026 19:30 |

## Historical values (do not use in commands)

| Mac | Phase 1 (5 Oct 2026) | Other observations |
|---|---|---|
| Mac 1 | 10.7.8.113 | No ping reply from Mac 3 on 23 Nov |
| Mac 2 | 10.7.7.58 | No ping reply from Mac 3 on 23 Nov |
| Mac 3 | 10.7.19.171 (earlier 10.7.2.229) | 10.7.1.218 seen on 23 Nov |
| Mac 4 | 10.7.20.75 | No ping reply from Mac 3 on 23 Nov |

## Placeholders used in prompts and configs

`<MAC1_IP>` `<MAC2_IP>` `<MAC3_IP>` `<MAC4_IP>` = the verified column above. `<WIFI_SERVICE>` = each Mac's service name from `networksetup -listallnetworkservices`.

## After CP1 (23 Nov 2026, 19:46–19:48)

| Mac | Change applied | Check |
|---|---|---|
| Mac 1 | dnsmasq: `address=/app.nova.test/10.7.5.201`, `address=/api.nova.test/10.7.5.201`, `listen-address=127.0.0.1,10.7.22.124`; restarted (was failing with `error 2` because it tried to bind the old IP 10.7.8.113) | `dig @10.7.22.124 app.nova.test` → NOERROR, aa, 10.7.5.201 |
| Mac 2 | nginx upstream → `10.7.1.218:3001`, `10.7.27.160:3002`; reloaded. DNS list → 10.7.22.124 | `nginx -t` ok; resolves 10.7.5.201 |
| Mac 3 | DNS list → 10.7.22.124 (public servers removed, stale 30 h negative cache flushed); Backend A started | resolves 10.7.5.201; Backend A 200, X-Backend: A |
| Mac 4 | Docker (Colima) container that held port 3002 stopped by Adarsh; Backend B started; DNS list → 10.7.22.124 | Backend B 200; resolves 10.7.5.201 |

Ping: all four Macs reach all four addresses with 0.0% loss.
End-to-end from Mac 4 (Keychain trust, no `-k`): six requests, all `200 OK`, `X-Backend` alternating A, B, A, B, A, B.
Mac 1's own DNS list is intentionally left on DHCP until S3 adds `no-resolv`/`server=` (prevents a forwarding loop).
