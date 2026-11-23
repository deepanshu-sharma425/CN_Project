# Mac 4 standby edge (Extension E)

Set up on 23 Nov 2026 (stage S6a).

- Config: [`nginx/nova.standby-mac4.conf`](../../nginx/nova.standby-mac4.conf). It is the same as `nginx/nova.phase2.conf` except for `add_header X-Edge "mac4" always;`. It is installed on Mac 4 as `/opt/homebrew/etc/nginx/servers/nova.conf`, and `include servers/*;` was added to Mac 4's `nginx.conf` (backup in `~/nova-backups/` on Mac 4).
- TLS: Mac 4 made its own RSA 2048 key and CSR. Only the CSR went to Mac 2, which signed it with the team mkcert CA. The private key and CSR are never committed (`*.pem` and `*.csr` are git-ignored).
- Checks, cutover and rollback: [`project-management/results/S6a-standby-edge.md`](../../project-management/results/S6a-standby-edge.md) and [`S8-dns-cutover.md`](../../project-management/results/S8-dns-cutover.md).
