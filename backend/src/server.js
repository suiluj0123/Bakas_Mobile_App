const http = require('http');
const { createApp } = require('./app');

function startServer() {
  const app = createApp();
  const server = http.createServer(app);

  const PORT = Number(process.env.PORT || 3000);
  server.listen(PORT, '0.0.0.0', () => {
    console.log(`Backend running on http://0.0.0.0:${PORT}`);
  });

  return server;
}

module.exports = { startServer };

