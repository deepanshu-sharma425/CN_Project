# Backend A (Mac 3) — Computer Networks Phase 1

Owner: Kanishk. Plain HTTP backend with HTTP caching. No dependencies (Node built-ins only).

- Host: Mac 3, 10.7.19.171
- Bind: 0.0.0.0 (all interfaces), port 3001
- Reached directly at http://10.7.19.171:3001, and through Mac 2 nginx (10.7.7.58)

Note on IP addresses: Mac 3 gets its address by DHCP. It was 10.7.2.229 when the
captures in `evidence/`, `EVIDENCE.md` and `HANDOFF.md` were taken on 2 October, and
10.7.19.171 for the final setup on 5 October. Those files are left as captured. The
evidence scripts default to the old address; run them with `BACKEND_IP=10.7.19.171`.

## Run

From the repository root:

    cd MAC_3/Backend_A
    pkill -f backend-a/server.js; sleep 1
    nohup node server.js >> server.log 2>&1 &

The `pkill` line stops any copy already running, so this is safe to run at any time.
Starting a second copy without it fails with EADDRINUSE. The log is appended to, so earlier requests are kept.

Check: `lsof -nP -iTCP:3001 -sTCP:LISTEN`
Log:   `cat server.log`
Stop:  `pkill -f backend-a/server.js`

## Endpoints

| Endpoint        | Status | Headers                                                        |
|-----------------|--------|----------------------------------------------------------------|
| GET /           | 200    | X-Backend: A, Cache-Control: public, max-age=60, ETag          |
| GET / + matching If-None-Match | 304 | X-Backend: A, Cache-Control, ETag, no body       |
| GET /api/status | 200    | X-Backend: A, Cache-Control: no-store, application/json        |
| anything else   | 404    | X-Backend: A                                                   |
| non GET/HEAD    | 405    | X-Backend: A, Allow: GET, HEAD                                 |

## Caching

- `/` is static, so it is cacheable for 60 seconds and carries an ETag (SHA-1 of the body).
  A client that sends the ETag back in `If-None-Match` gets `304 Not Modified` with no body.
- `/api/status` is live data, so it is marked `no-store`.

## Evidence

Saved curl output is in `evidence/` (04-listen through 09-no-store). Screenshots go alongside.
