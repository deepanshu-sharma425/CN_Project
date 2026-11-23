# Evidence index

Goal: an evaluator finds any proof within 30 seconds. One row per requirement. "Historical" = evidence from 2–5 Oct 2026, not yet re-verified on the current network.

Naming for new evidence: `MAC_<n>/evidence/phase2/S<stage>-<NN>-<slug>.<ext>` and `MAC_<n>/evidence/phase1-completion/S1-<NN>-<slug>.<ext>`.

## Phase 1

| ID | Requirement | Status | Evidence |
|---|---|---|---|
| P1-A1 | LAN, IP details, ping between all Macs | Re-verified 23 Nov | `MAC_*/evidence/phase2/S0-01-inventory*`, `S0-02-ping*`, `MAC_3/evidence/phase2/S0-03-ping.png`, `project-management/IP_INVENTORY.md`; historical: `MAC_4/evidence/02_lan_ping_reachability_all_macs.jpg`, `MAC_2/01_network_ip_config.png`, `MAC_3/evidence/mac-3_ss/` |
| P1-A2 | Topology diagram | Historical | `report/report.html` Figure 1 |
| P1-B1 | dnsmasq records | Historical | `MAC_1/evidence/MAC1_SS03_DNSMASQ_CONFIG.png`, `MAC1_SS04_DNSMASQ_RUNNING.png` |
| P1-B2 | Two clients resolve through Mac 1 | Historical | `MAC_4/evidence/05_dns_dig_app_nova_test_success.png`, `MAC_2/06_dns_dig_app_nova_test.png` |
| P1-C1 | Backend A | Historical | `MAC_3/evidence/mac-3_ss/`, `MAC_3/evidence/04-listen.txt` … `11-server-log-remote-ip.txt` |
| P1-C2 | Backend B | Historical | `MAC_4/evidence/03_backend_b_port_3002_listen.jpg`, `04_backend_b_local_status_curl.png` |
| P1-D1 | Reverse proxy, round robin | Historical | `MAC_4/evidence/07_load_balancing_round_robin_alternation.jpg`, `MAC_2/03_nginx_virtual_host_config.png`, `MAC_2/05_nginx_process_and_port_443.png` |
| P1-E1 | TLS at nginx, no `-k` | Historical | `MAC_4/evidence/06_https_curl_v_success.png` |
| P1-E2 | CA trusted on every client Mac | Done 23 Nov | `MAC_1/evidence/phase1-completion/S1-01-ca-trust-mac1.png`, `MAC_3/evidence/phase1-completion/S1-01-ca-trust-mac3.png`/`.txt`; Mac 4 end-to-end without `-k`: `MAC_4/evidence/phase2/S0-06-cp1-final-check-passed.png` |
| P1-E3 | TLS handshake captured | Historical | `MAC_4/evidence/13_wireshark_tls_handshake.png`, `13b_wireshark_tls_server_hello_cipher.png`, `wireshark_tls.pcapng` |
| P1-F1 | Cache-Control, 304 | Historical | `MAC_2/09_…`, `11_…`, `12_…`; `MAC_4/evidence/09_…`, `10_…` |
| P1-G1 | DNS capture | Historical | `MAC_4/evidence/11_wireshark_dns_query_response.jpeg`, `MAC_1/wireshark_dns.pcapng` |
| P1-G2 | TCP three-way handshake | Historical | `MAC_4/evidence/12_wireshark_tcp_3way_handshake.jpeg` |
| P1-G3 | Ports identified | Historical | `report/report.html` section 10 |
| P1-X1 | Failure: wrong DNS server | Historical | `MAC_4/evidence/14_…` to `17_…` |
| P1-X2 | Failure: wrong DNS record | Historical | `MAC_1/evidence/MAC1_SS08a_…`, `MAC1_SS08_…`, `MAC1_SS08b_…` |
| P1-X3 | Failure: one backend stopped | Done 23 Nov | `MAC_3/evidence/phase2/S2-02-demo1-backend-a-stopped.png`, `MAC_4/evidence/phase2/S2-03-demo1-a-stopped-all-b.png`, `S2-06-demo1-a-returns.png` |
| P1-X4 | Failure: both backends stopped (502) | Done 23 Nov | `MAC_4/evidence/phase2/S2-08-demo2-both-stopped-502.png`, `MAC_2/evidence/phase2/S2-08-demo2-errorlog-both-refused.png` |
| P1-X5 | Failure: wrong destination port | Done 23 Nov | `MAC_4/evidence/phase1-completion/S1-07-wrong-port-refused.png` |
| P1-H2 | HTTP/2 if supported | Done 23 Nov | `MAC_2/evidence/phase1-completion/S1-03-http2-and-baseline-config.png`; ALPN h2 on both edges: `MAC_3/evidence/phase2/S6a-08b-preflight-rerun.txt` (E10) |

## Phase 2

All Phase 2 evidence was recorded on 23 Nov 2026. Report: `report/Team_Nova_Phase2_Report.pdf` (source `report/phase2_report.html`).

| ID | Requirement (brief §7) | Status | Evidence |
|---|---|---|---|
| P2-A1 | Second DNS resolver on another Mac, same records | Done | `MAC_3/backup_dns/dnsmasq-nova-backup.conf`, `MAC_3/evidence/phase2/S3-01-backup-dns-setup.txt` |
| P2-A2 | Clients list primary and backup | Done | `MAC_2/evidence/phase2/S3-02-client-dns-both-servers.png`, `MAC_3/evidence/phase2/S3-03-client-dns-both-servers.png`, `MAC_4/evidence/phase2/S3-03-client-dns-both-servers.png` |
| P2-A3 | Primary stopped, clients still resolve | Done | `MAC_1/evidence/phase2/S3-04-primary-dns-stopped.png`, `MAC_4/evidence/phase2/S3-06-failover-resolver-and-website.png`, `MAC_3/evidence/phase2/S3-07-backup-dns-query-log.txt`, restore `MAC_1/evidence/phase2/S3-05-primary-restarted.png`, `MAC_4/evidence/phase2/S3-08-restored.png` |
| P2-A4 | DNS failure vs application failure | Done | `MAC_4/evidence/phase2/S3-07-dns-failure-vs-app-failure.png` (DNS) and `S2-08-demo2-both-stopped-502.png` (app); report §4 |
| P2-B1 | Short visible TTL (30 s) | Done | `MAC_3/evidence/phase2/S7-01-ttl30-mac3.png`, `S7-03-ttl30-verified-both-servers.txt`, `MAC_1/evidence/phase2/S7-02-ttl30-mac1.png` |
| P2-B2 | Record changed, cached client keeps old answer until TTL expires | Done | `MAC_1/evidence/phase2/S8-02-cutover-mac1-cached-client.png`, `S8-04-rollback-mac1-cached-client-and-log.png`; `project-management/results/S8-dns-cutover.md` |
| P2-B3 | Manual flush gives the new answer at once | Done | `MAC_3/evidence/phase2/S8-03-rollback-mac3-flushed-client.png`/`.txt` (invalid first run kept: `S8-01-cutover-mac3-ran-too-early.*`) |
| P2-B4 | Relation to migration / cutover | Done | report §5 and §11 B |
| P2-C1 | pf rules: only the edge reaches 3001/3002 | Done | `MAC_3/firewall/*.pf`, `MAC_4/firewall/mac4-backend-b.pf`, `MAC_3/evidence/phase2/S4-02-strict-loaded-token-counters.png`, `MAC_4/evidence/phase2/S4-02-rules-loaded-counters.png` |
| P2-C2 | Edge still reaches backends, client cannot | Done | `MAC_2/evidence/phase2/S4-01-allowed-from-edge.png`, `MAC_1/evidence/phase2/S4-01-blocked-from-mac1.png`, `MAC_3/evidence/phase2/S4-03-tests-and-counters.png`, `mac3-S4-tests.txt`, `mac3-S4-counters-after-block.txt`, `MAC_4/evidence/phase2/S4-03-tests-and-counters.png` |
| P2-C3 | Rollback copy, original restored | Done | `MAC_3/firewall/ROLLBACK.md`, `MAC_4/firewall/ROLLBACK.md`, `MAC_3/evidence/phase2/S4-04-block-counter-and-rollback.png`, `mac3-S4-rollback.txt`, `MAC_1/evidence/phase2/S4-02-after-rollback-ports-open.png`, `MAC_4/evidence/phase2/S4-04-rollback-pf-still-enabled.png` |
| P2-C4 | Edge-tier rules for the standby edge (Mac 4 allowed to A) | Done | `MAC_3/evidence/phase2/S4-05-edgetier-loaded-new-token.png`, `MAC_4/evidence/phase2/S4-05-edgetier-mac4-reaches-a.png`, `MAC_1/evidence/phase2/S4-03-edgetier-still-blocked.png` |
| P2-D1 | nginx detects failure, routes to healthy backend | Done | `nginx/nova.phase2.conf`, `MAC_2/evidence/phase2/S2-01-phase2-config-part1.png`, `S2-01-phase2-config-diff-headers.png` |
| P2-D2 | Stop Backend A → all requests via B | Done | `MAC_3/evidence/phase2/S2-02-demo1-backend-a-stopped.png`, `MAC_4/evidence/phase2/S2-03-demo1-a-stopped-all-b.png`, `MAC_2/evidence/phase2/S2-04-demo1-errorlog.png` |
| P2-D3 | Restart A → load balancing resumes | Done | `MAC_3/evidence/phase2/S2-05-demo1-backend-a-restarted.png`, `MAC_4/evidence/phase2/S2-06-demo1-a-returns.png` |
| P2-D4 | Single point of failure identified | Done | report §7 (edge on Mac 2); Drill 2 `MAC_1/evidence/phase2/S9-D2-02-diag-hrishabh.png` |
| P2-D5 | Timeout tuning, T2 frozen backend (60.13 s → 5.25 s) | Done | `project-management/results/T2-frozen-backend-timing.md`, `MAC_3/evidence/phase2/S2-17-T2-phase1-clean-run.txt`, `MAC_4/evidence/phase2/S2-16-T2-timer-results-run1-run2.png`, `MAC_2/evidence/phase2/S2-14-T2-errorlog-phase2-timeout.png` |
| P2-D6 | Timeout tuning, T3 silent drop (60.14 s → 2.07 s) | Done | `project-management/results/T3-silent-drop-timing.md`, `MAC_3/evidence/phase2/S5-04-T3-phase2-connect-timeout-2s.png`, `S5-06-T3-phase1-connect-timeout-60s.png`, `S5-03-keepalive-finding.txt` |
| P2-E1 | Standby nginx on another Mac, same config | Done | `nginx/nova.standby-mac4.conf`, `MAC_4/evidence/phase2/S6a-07-standby-edge-started.png`, TLS: `S6a-02-key-and-csr.png`, `MAC_2/evidence/phase2/S6a-05-csr-signed.png`, `MAC_4/evidence/phase2/S6a-04-csr-verified-on-mac3.txt`; `project-management/results/S6a-standby-edge.md` |
| P2-E2 | Preflight before cutover | Done | `MAC_3/evidence/phase2/S6a-08b-preflight-rerun.txt` (E9/E11 in `S6a-08a-*`) |
| P2-E3 | DNS record moved to standby and back | Done | `MAC_1/evidence/phase2/S8-02-*`, `S8-04-*`, `MAC_3/evidence/phase2/S8-03-*`; `project-management/results/S8-dns-cutover.md` |
| P2-E4 | Cached clients briefly hit the old edge, new lookups go to standby | Done | as P2-B2/B3 (old edge ≤ 41 s on cached Mac 1; flushed Mac 3 at once) |
| P2-F1 | Systematic diagnosis method (runbook) | Done | `project-management/TROUBLESHOOTING.md`, report §9 |
| P2-F2 | Practice drills, layer identified | Done | D1 DNS: `MAC_1/evidence/phase2/S9-D1-01-*`, `MAC_4/evidence/phase2/S9-D1-02-diag-adarsh.png`, `MAC_1/…/S9-D1-03-rollback.png` · D2 TCP: `MAC_2/…/S9-D2-01-*`, `MAC_1/…/S9-D2-02-diag-hrishabh.png`, `MAC_2/…/S9-D2-03-*` · D3 TLS: `MAC_2/…/S9-D3-01-*`, `MAC_3/…/S9-D3-02-diag-kanishk.*`, `MAC_2/…/S9-D3-03-*` · D4 edge→backend: `MAC_3/…/S9-D4-01-*`, `MAC_2/…/S9-D4-02-diag-deepanshu.png`, `MAC_3/…/S9-D4-03-*` · final state `MAC_3/evidence/phase2/S9-05-final-state-after-drills.txt` |
| P2-F3 | Faculty-injected fault | At evaluation | — |
| P2-R1 | Phase 2 report | Done | `report/Team_Nova_Phase2_Report.pdf` |
| P2-R2 | Configuration bundle | Done | `nginx/`, `MAC_1/dnsmasq.phase2-additions.conf`, `MAC_3/backup_dns/`, `MAC_3/firewall/`, `MAC_4/firewall/` |
| P2-R3 | Updated architecture | Done | report §2 (Figure 1, IP table) |
