# Team Nova — Project Status

**Data as of:** 23 Nov 2026, 17:56 IST · **Source:** coordinator (Kanishk, Mac 3) after CP0
**Branch:** `phase2` (local, not pushed yet) · **Dashboard:** https://claude.ai/artifact/R6GxvyzNWTJWpJq7bTZtb4

The source of truth is `project-status.json` in this folder. Each member edits only their own file in `status/`; the coordinator merges them into `project-status.json` and regenerates this summary.

## Current position

| Item | Value |
|---|---|
| Current stage | S0 — Network re-baseline (not started) |
| Next milestone | CP0P (push policy for `origin/phase2`), then S0 on all four Macs |
| Phase 1 | 14 items with historical evidence (Oct 2026), 5 missing or partial, 0 re-verified on the current network |
| Phase 2 | 0 of 23 items done |
| Approvals recorded | CP0 (approved 23 Nov 2026) |

## Members

| Member | Mac | Status | Current task | Blockers |
|---|---|---|---|---|
| Hrishabh | Mac 1 | Not started | Waiting for `phase2` on GitHub | — |
| Deepanshu | Mac 2 | Not started | Waiting for `phase2` on GitHub; confirm push access | — |
| Kanishk | Mac 3 | Waiting for approval | CP0 done; CP0P next | Mac 3 DNS list includes public servers (cached NXDOMAIN for app.nova.test); Mac 3 does not trust the team CA |
| Adarsh | Mac 4 | Not started | Waiting for `phase2` on GitHub | — |

## Known facts (read-only audit, 23 Nov 2026)

- Every current IP is NOT VERIFIED. Mac 3 was seen at 10.7.1.218 (repo says 10.7.19.171). Macs 1, 2 and 4 did not answer ping from Mac 3.
- Missing Phase 1 evidence: one backend stopped, both backends stopped (502), wrong destination port; CA trust on every client; HTTP/2 (if supported).
- dnsmasq `address=` records currently answer with TTL 0.

## Stage order

S0 inventory → S1 Phase 1 completion → S2 Ext D (nginx failover, T2) → S3 Ext A (backup DNS) → S4 Ext C (pf) → S5 Ext D (T3) → S6a standby edge + preflight → S7 Ext B (TTL) → S8 Ext E (cutover) → S9 Ext F (drills) → S10 report and submission.
