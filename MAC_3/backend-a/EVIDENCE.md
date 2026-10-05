# Backend A - Evidence (Mac 3, 10.7.2.229:3001)

Owner: Kanishk. Every block below is real terminal output captured on Mac 3 with tee.
Matching screenshots, where taken, are in the evidence/ folder.

## 1. Backend A running and LAN-bound

Proves: the server listens on *:3001 (all interfaces), not only 127.0.0.1.

```
$ lsof -nP -iTCP:3001 -sTCP:LISTEN
COMMAND   PID             USER   FD   TYPE             DEVICE SIZE/OFF NODE NAME
node    87436 kanishk.personal   12u  IPv4 0xe7833e8089b820d4      0t0  TCP *:3001 (LISTEN)
```

## 2. The / endpoint

Proves: / answers 200, identifies Backend A in the body, and carries X-Backend: A.

```
$ curl -si http://10.7.2.229:3001/
HTTP/1.1 200 OK
X-Backend: A
Cache-Control: public, max-age=60
ETag: "abe0f97674562f0dbaee165957d92bab747dd23d"
Content-Type: text/html; charset=utf-8
Content-Length: 168
Date: Fri, 02 Oct 2026 19:24:22 GMT
Connection: keep-alive
Keep-Alive: timeout=5

<!doctype html>
<html><head><meta charset="utf-8"><title>Backend A</title></head>
<body><h1>Backend A</h1><p>Served by Backend A on Mac 3, port 3001.</p></body></html>
```

## 3. The /api/status endpoint

Proves: /api/status answers 200 with JSON naming backend A, and carries X-Backend: A.

```
$ curl -si http://10.7.2.229:3001/api/status
HTTP/1.1 200 OK
X-Backend: A
Content-Type: application/json
Cache-Control: no-store
Content-Length: 136
Date: Fri, 02 Oct 2026 19:24:24 GMT
Connection: keep-alive
Keep-Alive: timeout=5

{"backend":"A","status":"ok","hostname":"Kanishks-MacBook-Pro-2.local","port":3001,"uptimeSeconds":6,"time":"2026-10-02T19:24:24.142Z"}
```

## 4. Cache headers

Proves: / is cacheable: Cache-Control: public, max-age=60 plus an ETag validator.

```
$ curl -sI http://10.7.2.229:3001/
HTTP/1.1 200 OK
X-Backend: A
Cache-Control: public, max-age=60
ETag: "abe0f97674562f0dbaee165957d92bab747dd23d"
Content-Type: text/html; charset=utf-8
Content-Length: 168
Date: Fri, 02 Oct 2026 19:24:26 GMT
Connection: keep-alive
Keep-Alive: timeout=5

```

## 5. Conditional request

Proves: a client holding the current ETag gets 304 Not Modified with no body.

```
$ curl -si -H 'If-None-Match: <ETag from step 4>' http://10.7.2.229:3001/
HTTP/1.1 304 Not Modified
X-Backend: A
Cache-Control: public, max-age=60
ETag: "abe0f97674562f0dbaee165957d92bab747dd23d"
Date: Fri, 02 Oct 2026 19:24:28 GMT
Connection: keep-alive
Keep-Alive: timeout=5

```

## 6. Non-cacheable endpoint

Proves: live data is marked Cache-Control: no-store, in contrast to /.

```
$ curl -sI http://10.7.2.229:3001/api/status
HTTP/1.1 200 OK
X-Backend: A
Content-Type: application/json
Cache-Control: no-store
Content-Length: 137
Date: Fri, 02 Oct 2026 19:24:30 GMT
Connection: keep-alive
Keep-Alive: timeout=5

```

## 7. Server log

Proves: which machines made requests. Format: time, client IP, method, path, status.

```
$ cat server.log
Backend A listening on http://0.0.0.0:3001
2026-10-02T19:24:19.867Z 10.7.2.229 GET /api/status -> 200
2026-10-02T19:24:22.005Z 10.7.2.229 GET / -> 200
2026-10-02T19:24:24.142Z 10.7.2.229 GET /api/status -> 200
2026-10-02T19:24:26.339Z 10.7.2.229 HEAD / -> 200
2026-10-02T19:24:28.510Z 10.7.2.229 HEAD / -> 200
2026-10-02T19:24:28.566Z 10.7.2.229 GET / -> 304
2026-10-02T19:24:30.717Z 10.7.2.229 HEAD /api/status -> 200
2026-10-02T19:25:57.808Z 10.7.7.58 GET / -> 200
2026-10-02T19:25:57.842Z 10.7.7.58 GET /api/status -> 200
```

## 8. LAN accessibility from another Mac

PROVEN: the log above contains requests from other machine(s): 10.7.7.58 
