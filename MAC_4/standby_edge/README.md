# Mac 4 standby edge (Extension E)

Filled in at S6a (CP7). `nova.standby.conf` will be `nginx/nova.phase2.conf` with one difference: `add_header X-Edge "mac4" always;`.
The private key and CSR stay on Mac 4 only and are never committed (`*.pem`, `*.csr` are git-ignored).
