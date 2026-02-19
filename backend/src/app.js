const express = require('express');
const cors = require('cors');

const authRoutes = require('./routes/authRoutes');
const paymentRoutes = require('./routes/paymentRoutes');

function createApp() {
  const app = express();

  app.use(cors());
  app.use(express.json({ limit: '1mb' }));

  app.get('/health', (_req, res) => {
    res.status(200).json({ ok: true });
  });

  app.use(authRoutes);
  app.use(paymentRoutes);

  app.use((_req, res) => {
    res.status(404).json({ ok: false, message: 'Not found' });
  });

  app.use((err, _req, res, _next) => {
    res.status(500).json({ ok: false, message: err?.message || 'Server error' });
  });

  return app;
}

module.exports = { createApp };

