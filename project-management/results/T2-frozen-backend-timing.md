# T2: frozen backend (read timeout), Phase 1 vs Phase 2 — Extension D

Fault: Backend A on Mac 3 frozen with `kill -STOP` (process alive, listening socket open, never answers).
Edge: nginx 1.31.6 on Mac 2, one worker. Measured with `curl -w '%{time_total}'`, 4 sequential requests to https://app.nova.test/api/status.

| Config on Mac 2 | Request that hit frozen A | Other requests | Status | Run |
|---|---|---|---|---|
| Phase 1 baseline (`proxy_read_timeout` default 60 s) | **60.13 s**, then served by B | 0.04–0.15 s | all 200 | 23 Nov 20:23:16, client Mac 3 |
| Phase 2 (`proxy_read_timeout 5s`) | **5.25 s**, then served by B | 0.05–0.15 s | all 200 | 23 Nov 20:11:49, client Mac 4 |
| Phase 2 (`proxy_read_timeout 5s`) | **5.56 s**, then served by B | 0.03–0.08 s | all 200 | 23 Nov 20:19:34, client Mac 4 |

Result: the wait for a request that lands on a frozen backend dropped from about 60 s to about 5 s (~11x). The request still succeeds because `proxy_next_upstream error timeout` retries it on Backend B.

Discarded runs (documented, not used):
- 20:10:25 Phase 1 → 39.58 s: Backend A was resumed after ~40 s, before the 60 s timeout expired.
- 20:17:51 "Phase 1" → 5.26 s: the Phase 2 config had already been reloaded at 20:16:55, so this run measured Phase 2.

Evidence: MAC_3/evidence/phase2/S2-17-T2-phase1-clean-run.txt; MAC_4/evidence/phase2/S2-16-T2-timer-results-run1-run2.png; MAC_2/evidence/phase2/S2-14-T2-errorlog-phase2-timeout.png; MAC_2/evidence/phase2/S2-16-T2-run2-config-switches.png
