# Approvals log

A checkpoint (CP) is a recorded decision. Recording it runs nothing; the owner of each Mac performs the work afterwards. The same decisions are mirrored in the dashboard's Approval center.

| CP | Scope | Decision | By | Date | Notes |
|---|---|---|---|---|---|
| CP0 | Create `phase2` branch and project-management scaffold; commit report sources. Local only, no push. | Approved | Kanishk | 23 Nov 2026 | Given in the Claude Code session on Mac 3 |
| CP0P | Push policy for `origin/phase2` | Pending | | | Recommended: push `phase2` (never `main`) after each approved stage |
| CP1 | Apply the verified S0 inventory | Pending | | | |
| CP2 | Phase 1 completion actions | Pending | | | |
| CP3 | Phase 2 nginx config and T2 | Pending | | | |
| CP4 | Backup DNS and failover experiment | Pending | | | |
| CP4a | `/etc/resolver` fallback (only if CP4 fails) | Pending | | | |
| CP5 | Load and enable strict pf rules | Pending | | | |
| CP5b | Mac 3 to edge-tier rules | Pending | | | |
| CP6 | T3 silent-drop experiment (also called CP5c) | Pending | | | |
| CP7 | Standby edge on Mac 4 and preflight | Pending | | | |
| CP8 | TTL 30 s and record changes | Pending | | | |
| CP9 | DNS cutover to the standby edge | Pending | | | |
| CP10 | Fault injections for drills | Pending | | | |
| CP11 | Final documentation commits | Pending | | | |
| CP12 | Merge to `main` and push | Pending | | | |
