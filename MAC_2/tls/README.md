# TLS / HTTPS Setup

## Server

- **Machine**: Mac 2
- **IP Address**: `10.7.7.58`
- **Web Server**: `nginx`
- **HTTPS Port**: TCP `443`
- **Role**: Edge Server / Reverse Proxy / Load Balancer / TLS Termination

## Domain

- **Domain Name**: `app.nova.test`
- **DNS Resolution**: `app.nova.test` resolves to `10.7.7.58`

## Certificate

- **Generation Tool**: `mkcert`
- **Issuer**: Local `mkcert development CA`
- **Subject**: `O=mkcert development certificate`
- **Subject Alternative Name (SAN)**: `DNS:app.nova.test`
- **Validity**: Active (valid through January 2029)
- **Deployment Paths**:
  - Certificate: `/opt/homebrew/etc/nginx/certs/app.nova.test.pem`
  - Private Key: `/opt/homebrew/etc/nginx/certs/app.nova.test-key.pem` (protected with strict permissions)

The certificate was generated using the existing local mkcert development CA and contains `app.nova.test` in its Subject Alternative Name (SAN).

## Verification

HTTPS functionality and strict certificate validation were verified using `curl` without disabling certificate verification:

```bash
curl -v https://app.nova.test/
```

> **Note**: Certificate verification succeeds cleanly without using `-k` or `--insecure`.

### Verification Output Highlights

- **TLS Handshake**: Negotiated `TLSv1.3`
- **Host Matching**: `subjectAltName: host "app.nova.test" matched cert's "app.nova.test"`
- **Trust Chain**: `SSL certificate verify ok`
- **HTTP Response**: `HTTP/1.1 200 OK`
- **Load Balancing**: Upstream response received with `X-Backend: A` or `X-Backend: B`

## Trust

- The certificate is signed by the local `mkcert` Root CA (`rootCA.pem`).
- The public root certificate (no private key) is in this repository at `MAC_2/certs/mkcert-rootCA.crt`. It is a copy of `rootCA.pem`, named `.crt` because `.gitignore` excludes `*.pem`.
- For participating client machines (e.g., Mac 1, Mac 3, Mac 4) to verify HTTPS connections without certificate warnings, that root certificate must be trusted in their macOS Keychain. From the repository root on the client machine:

```bash
sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain MAC_2/certs/mkcert-rootCA.crt
```

## Security

- **Private certificate keys must NOT be committed to GitHub.**
- **CA private keys (`rootCA-key.pem`) must NOT be committed to GitHub.**
- **Never expose private key contents in documentation or repository files.**
- Strict file system permissions (`chmod 600`) must be maintained on all private key files on the host machine.
