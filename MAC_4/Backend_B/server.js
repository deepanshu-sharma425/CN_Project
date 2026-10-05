const http = require('http');

const HOST = '0.0.0.0';
const PORT = 3002;

const startTime = Date.now();

function getUptime() {
  return Math.floor((Date.now() - startTime) / 1000);
}

const server = http.createServer((req, res) => {
  // Set common headers for every response
  res.setHeader('X-Backend', 'B');
  res.setHeader('Content-Type', 'application/json');

  const timestamp = new Date().toISOString();

  const method = req.method;
  const isGetOrHead = (method === 'GET' || method === 'HEAD');

  if (isGetOrHead && req.url === '/') {
    const body = JSON.stringify({
      backend: 'B',
      status: 'ok',
      port: PORT,
      message: 'Hello from Backend B',
      timestamp: timestamp
    }, null, 2);
    res.writeHead(200, { 'Content-Length': Buffer.byteLength(body) });
    res.end(method === 'HEAD' ? '' : body);
  } else if (isGetOrHead && req.url === '/api/status') {
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
  console.log(`[${timestamp}] ${req.method} ${req.url} - ${req.socket.remoteAddress}`);
});

server.listen(PORT, HOST, () => {
  console.log(`Backend B running on http://${HOST}:${PORT}`);
  console.log(`Endpoints:`);
  console.log(`  GET /          → Server info`);
  console.log(`  GET /api/status → Health check`);
});

