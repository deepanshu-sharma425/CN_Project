# S8 DNS cutover to the standby edge (Extension E), 23 Nov 2026

Record: `host-record=app.nova.test,<IP>,30` (and api) on both dnsmasq servers (Mac 1 primary 10.7.22.124, Mac 3 backup 10.7.1.218).

## Cutover Mac 2 → Mac 4 (22:22)
- Mac 1 server switched 22:22:26. Cached client Mac 1 (no flush): `mac2` until 22:23:02, `mac4` from 22:23:06.
- Mac 1 dnsmasq log: client lookups at 22:22:25 and next at **22:23:06** (41 s later).
- Mac 3 flushed-client run was **invalid**: it ran at 22:22:01, before Mac 1's server switched, and got the old answer from Mac 1. Repeated on rollback with an automatic wait.

## Rollback Mac 4 → Mac 2 (22:25)
- Mac 1 server switched 22:25:48. Mac 3 script waited for it (`dig @10.7.22.124` poll), switched its own server, flushed: **`10.7.5.201 mac2` at 22:25:50**, immediately.
- Cached client Mac 1: `mac4` until 22:26:18, `mac2` from 22:26:21. Log: lookups 22:25:42 and next **22:26:21** (39 s later).

## Finding
With TTL 30 s, the macOS cache (mDNSResponder) re-queried 39–41 s after the previous lookup, not at 30 s: the observed worst-case switch time for a cached client was about TTL + 10 s. A flushed client switches at once. No requests failed in either direction (every probe returned 200 from one edge).

Evidence: `MAC_1/evidence/phase2/S8-*`, `MAC_3/evidence/phase2/S8-*`.
