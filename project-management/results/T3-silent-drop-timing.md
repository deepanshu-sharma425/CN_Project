# T3: silent drop (connect timeout), Phase 1 vs Phase 2 — Extension D

Fault: pf on Mac 3 loads `MAC_3/firewall/mac3-backend-a.t3-fault.pf` (only Mac 3 itself may reach TCP 3001; everything else is dropped without a reply), so nginx on Mac 2 sends SYNs that are never answered.
Method: one script on Mac 3 checks which nginx config is live (Phase 2 adds `x-edge`), loads the fault rules, waits 10 s so the idle keep-alive connection from nginx closes (see MAC_3/evidence/phase2/S5-03-keepalive-finding.txt), times 4 sequential requests, then restores the edge-tier rules.

| Config on Mac 2 | Request that hit Backend A | Other requests | Status | nginx error.log | Run |
|---|---|---|---|---|---|
| Phase 1 baseline (`proxy_connect_timeout` default 60 s) | **60.14 s**, then served by B | 0.11–0.26 s | all 200 | 21:00:12 `upstream timed out (60: Operation timed out) while connecting to upstream` | 23 Nov 20:59:02 |
| Phase 2 (`proxy_connect_timeout 2s`) | **2.07 s**, then served by B | 0.05 s | all 200 | 20:55:26 same message | 23 Nov 20:55:14 |

Combined with T2 (results/T2-frozen-backend-timing.md):

| Fault | Phase 1 | Phase 2 |
|---|---|---|
| Backend frozen (read timeout) | 60.13 s | 5.25 s / 5.56 s |
| Packets silently dropped (connect timeout) | 60.14 s | 2.07 s |

Discarded runs: 20:52:04 (keep-alive connection reused, fault never hit); 20:53:06 and 20:56:41 (script guard aborted: wrong PH for the live config, nothing changed).
Evidence: MAC_3/evidence/phase2/S5-04-T3-phase2-connect-timeout-2s.png, S5-06-T3-phase1-connect-timeout-60s.png, S5-06-T3-phase1-run.txt; MAC_2/evidence/phase2/S5-07-T3-final-log-phase2-restored.png
