# Mac 3 backup DNS (Extension A)

[`dnsmasq-nova-backup.conf`](dnsmasq-nova-backup.conf) is the project block used in `/opt/homebrew/etc/dnsmasq.conf` on Mac 3.

Its records must stay identical to Mac 1's (`MAC_1/dnsmasq.phase2-additions.conf`): the same `host-record=…,30` lines and the same `local-ttl=30`. Only `listen-address` differs, because it holds each Mac's own IP.

Failover proof and query log: `MAC_3/evidence/phase2/S3-*` and `MAC_4/evidence/phase2/S3-*`.
