const http = require('http');
const crypto = require('crypto');

const HOST = '0.0.0.0';
const PORT = 3002;

const startTime = Date.now();

// "/" is static, so it is safe to cache. Its ETag is a hash of the body.
const HOME_BODY = JSON.stringify({
  backend: 'B',
  status: 'ok',
  port: PORT,
  message: 'Hello from Backend B'
}, null, 2);
const HOME_ETAG = '"' + crypto.createHash('sha1').update(HOME_BODY).digest('hex') + '"';

function getUptime() {
  return Math.floor((Date.now() - startTime) / 1000);
}

// True if the client's If-None-Match header lists our ETag
function etagMatches(header, etag) {
  if (!header) return false;
  return header
    .split(',')
    .map((v) => v.trim().replace(/^W\//, ''))
    .some((v) => v === etag || v === '*');
}

const server = http.createServer((req, res) => {
  // Set common headers for every response
  res.setHeader('X-Backend', 'B');
  res.setHeader('Content-Type', 'application/json');

  const timestamp = new Date().toISOString();

  const method = req.method;
  const isGetOrHead = (method === 'GET' || method === 'HEAD');

  if (isGetOrHead && req.url === '/') {
    res.setHeader('Cache-Control', 'public, max-age=60');
    res.setHeader('ETag', HOME_ETAG);
    if (etagMatches(req.headers['if-none-match'], HOME_ETAG)) {
      // Client copy is still valid: no body, no Content-Type
      res.removeHeader('Content-Type');
      res.writeHead(304);
      res.end();
    } else {
      res.writeHead(200, { 'Content-Length': Buffer.byteLength(HOME_BODY) });
      res.end(method === 'HEAD' ? '' : HOME_BODY);
    }
  } else if (isGetOrHead && req.url === '/api/status') {
    // Live data, must never be cached
    res.setHeader('Cache-Control', 'no-store');
    const body = JSON.stringify({
      backend: 'B',
      status: 'ok',
      port: PORT,
      uptime: getUptime(),
      timestamp: timestamp
    }, null, 2);
    res.writeHead(200, { 'Content-Length': Buffer.byteLength(body) });
    res.end(method === 'HEAD' ? '' : body);
  } else {
    res.writeHead(404);
    res.end(JSON.stringify({
      error: 'Not Found'
    }, null, 2));
  }

  // Log every request for debugging
  console.log(`[${timestamp}] ${req.method} ${req.url} -> ${res.statusCode} - ${req.socket.remoteAddress}`);
});

server.listen(PORT, HOST, () => {
  console.log(`Backend B running on http://${HOST}:${PORT}`);
  console.log(`Endpoints:`);
  console.log(`  GET /          → Server info`);
  console.log(`  GET /api/status → Health check`);
});
