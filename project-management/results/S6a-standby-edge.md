# S6a standby edge on Mac 4 (23 Nov 2026)

- Mac 4 generated its own RSA 2048 key and CSR (`~/nova-tls`, key mode 600).
- **Deviation, attempt 1 (22:05):** the key was AirDropped to Mac 3 together with the CSR. That key pair (pubkey sha256 `42cf502a…`) was discarded, the copies on Mac 3 deleted, and a new pair generated. It was never used for any certificate.
- Attempt 2: CSR only (pubkey `2dcda60a…`), checked on Mac 3, signed on Mac 2 with the team mkcert CA (FE:E8:…:31:56) in `~/nova-csr`. Valid until 23 Feb 2029, SAN `DNS:app.nova.test`. Certificate pubkey = key pubkey = `2dcda60a…`.
- Mac 4 nginx: `nginx.conf` backed up to `~/nova-backups/nginx.conf.mac4-before-S6a`; `include servers/*;` added; `servers/nova.conf` = Phase 2 config with `X-Edge "mac4"`. The old `app.teamX.test` block on 8443 was left untouched.
- Listening `*:443`, `*:8080`, `*:8443`. Local test: HTTP/2 200, X-Edge mac4, X-Backend A and B.

## Preflight from Mac 3 (22:19)

| Check | Result |
|---|---|
| E3 status + verify | 200, ssl_verify_result 0 (Keychain, no -k) |
| E4 headers | X-Edge mac4, X-Backend present, JSON body |
| E5 `/` | 200 |
| E6 six requests | B A B A B A |
| E7 ETag | 304 from the backend that issued it (B); A answers 200 (different ETag per backend) |
| E8 `security verify-cert -p basic` | success (Mac 4 and Mac 2). `-p ssl` fails on missing SCTs, an Apple CT policy for public CAs, not a trust failure |
| E9 | same issuer, different fingerprints (Mac 4 `92:16:48:…`, Mac 2 `2F:C5:31:…`) |
| E10 | ALPN h2 |
| E11 | Mac 2 edge unchanged (200, X-Edge mac2); both DNS servers still answer 10.7.5.201 |

Evidence: `MAC_4/evidence/phase2/S6a-*`, `MAC_2/evidence/phase2/S6a-*`, `MAC_3/evidence/phase2/S6a-08*`.
