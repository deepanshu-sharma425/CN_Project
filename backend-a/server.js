// Backend A - Computer Networks Phase 1 (Mac 3)
// Plain HTTP, no dependencies. Run with: node server.js
const http = require('http');
const crypto = require('crypto');
const os = require('os');

const HOST = '0.0.0.0'; // all interfaces, so other Macs on the LAN can reach it
const PORT = 3001;
const BACKEND = 'A';

// "/" is static, so it is safe to cache. Its ETag is a hash of the body.
const HOME_BODY =
  '<!doctype html>\n<html><head><meta charset="utf-8"><title>Backend A</title></head>\n' +
  '<body><h1>Backend A</h1><p>Served by Backend A on Mac 3, port ' + PORT + '.</p></body></html>\n';
const HOME_ETAG = '"' + crypto.createHash('sha1').update(HOME_BODY).digest('hex') + '"';

function send(req, res, status, headers, body) {
  const all = { 'X-Backend': BACKEND, ...headers };
  if (body !== null) all['Content-Length'] = Buffer.byteLength(body);
  res.writeHead(status, all);
  res.end(body === null || req.method === 'HEAD' ? undefined : body);
  console.log(
    `${new Date().toISOString()} ${req.socket.remoteAddress} ${req.method} ${req.url} -> ${status}`
  );
}

function etagMatches(header, etag) {
  if (!header) return false;
  return header
    .split(',')
    .map((v) => v.trim().replace(/^W\//, ''))
    .some((v) => v === etag || v === '*');
}

const server = http.createServer((req, res) => {
  const path = req.url.split('?')[0];

  if (req.method !== 'GET' && req.method !== 'HEAD') {
    return send(req, res, 405, { Allow: 'GET, HEAD', 'Content-Type': 'text/plain' },
      'Backend A: method not allowed\n');
  }

  if (path === '/') {
    const cacheHeaders = { 'Cache-Control': 'public, max-age=60', ETag: HOME_ETAG };
    if (etagMatches(req.headers['if-none-match'], HOME_ETAG)) {
      return send(req, res, 304, cacheHeaders, null); // client copy is still valid
    }
    return send(req, res, 200,
      { ...cacheHeaders, 'Content-Type': 'text/html; charset=utf-8' }, HOME_BODY);
  }

  if (path === '/api/status') {
    const body = JSON.stringify({
      backend: BACKEND,
      status: 'ok',
      hostname: os.hostname(),
      port: PORT,
      uptimeSeconds: Math.round(process.uptime()),
      time: new Date().toISOString(),
    }) + '\n';
    return send(req, res, 200,
      { 'Content-Type': 'application/json', 'Cache-Control': 'no-store' }, body);
  }

  return send(req, res, 404, { 'Content-Type': 'text/plain' }, 'Backend A: not found\n');
});

server.listen(PORT, HOST, () => {
  console.log(`Backend A listening on http://${HOST}:${PORT}`);
});
