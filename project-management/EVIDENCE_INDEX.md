# Evidence index

Goal: an evaluator finds any proof within 30 seconds. One row per requirement. "Historical" = evidence from 2–5 Oct 2026, not yet re-verified on the current network.

Naming for new evidence: `MAC_<n>/evidence/phase2/S<stage>-<NN>-<slug>.<ext>` and `MAC_<n>/evidence/phase1-completion/S1-<NN>-<slug>.<ext>`.

## Phase 1

| ID | Requirement | Status | Evidence |
|---|---|---|---|
| P1-A1 | LAN, IP details, ping between all Macs | Historical | `MAC_4/evidence/02_lan_ping_reachability_all_macs.jpg`, `MAC_2/01_network_ip_config.png`, `MAC_3/evidence/mac-3_ss/` |
| P1-A2 | Topology diagram | Historical | `report/report.html` Figure 1 |
| P1-B1 | dnsmasq records | Historical | `MAC_1/evidence/MAC1_SS03_DNSMASQ_CONFIG.png`, `MAC1_SS04_DNSMASQ_RUNNING.png` |
| P1-B2 | Two clients resolve through Mac 1 | Historical | `MAC_4/evidence/05_dns_dig_app_nova_test_success.png`, `MAC_2/06_dns_dig_app_nova_test.png` |
| P1-C1 | Backend A | Historical | `MAC_3/evidence/mac-3_ss/`, `MAC_3/evidence/04-listen.txt` … `11-server-log-remote-ip.txt` |
| P1-C2 | Backend B | Historical | `MAC_4/evidence/03_backend_b_port_3002_listen.jpg`, `04_backend_b_local_status_curl.png` |
| P1-D1 | Reverse proxy, round robin | Historical | `MAC_4/evidence/07_load_balancing_round_robin_alternation.jpg`, `MAC_2/03_nginx_virtual_host_config.png`, `MAC_2/05_nginx_process_and_port_443.png` |
| P1-E1 | TLS at nginx, no `-k` | Historical | `MAC_4/evidence/06_https_curl_v_success.png` |
| P1-E2 | CA trusted on every client Mac | Partial | Mac 4 via Anaconda CA file only; Mac 3 not trusted (23 Nov). To do in S1. |
| P1-E3 | TLS handshake captured | Historical | `MAC_4/evidence/13_wireshark_tls_handshake.png`, `13b_wireshark_tls_server_hello_cipher.png`, `wireshark_tls.pcapng` |
| P1-F1 | Cache-Control, 304 | Historical | `MAC_2/09_…`, `11_…`, `12_…`; `MAC_4/evidence/09_…`, `10_…` |
| P1-G1 | DNS capture | Historical | `MAC_4/evidence/11_wireshark_dns_query_response.jpeg`, `MAC_1/wireshark_dns.pcapng` |
| P1-G2 | TCP three-way handshake | Historical | `MAC_4/evidence/12_wireshark_tcp_3way_handshake.jpeg` |
| P1-G3 | Ports identified | Historical | `report/report.html` section 10 |
| P1-X1 | Failure: wrong DNS server | Historical | `MAC_4/evidence/14_…` to `17_…` |
| P1-X2 | Failure: wrong DNS record | Historical | `MAC_1/evidence/MAC1_SS08a_…`, `MAC1_SS08_…`, `MAC1_SS08b_…` |
| P1-X3 | Failure: one backend stopped | Missing | S1 |
| P1-X4 | Failure: both backends stopped (502) | Missing | S1 |
| P1-X5 | Failure: wrong destination port | Missing | S1 |
| P1-H2 | HTTP/2 if supported | Missing | S1 |

## Phase 2

| ID | Requirement | Status | Evidence |
|---|---|---|---|
| P2-A1…A4 | Backup DNS, client lists, primary stopped, DNS vs app failure | Not started | S3 |
| P2-B1…B4 | TTL 30 s, cached answer, flush, migration explanation | Not started | S7 |
| P2-C1…C3 | pf isolation, allowed vs blocked, rollback | Not started | S4 |
| P2-D1…D5 | nginx failover, stop/restart A, single point of failure, T2/T3 timings | Not started | S2, S5 |
| P2-E1…E3 | Standby edge, DNS cutover, cached vs fresh clients | Not started | S6a, S8 |
| P2-F1 | Fault diagnosis runbook and drills | Not started | S9 |
| P2-R1…R3 | Phase 2 report, evidence index, configuration bundle | Not started | S10 |
