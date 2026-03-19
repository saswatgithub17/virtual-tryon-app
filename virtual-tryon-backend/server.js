// VIRTUAL TRY-ON BACKEND SERVER
const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
const dotenv = require('dotenv');
const path = require('path');
const os = require('os');

dotenv.config();

const db = require('./config/database');
const dressRoutes = require('./routes/dressRoutes');
const orderRoutes = require('./routes/orderRoutes');
const paymentRoutes = require('./routes/paymentRoutes');
const reviewRoutes = require('./routes/reviewRoutes');
const tryonRoutes = require('./routes/tryonRoutes');
const adminRoutes = require('./routes/adminRoutes');
const { specs, swaggerUi } = require('./config/swagger');

const app = express();
const PORT = process.env.PORT || 5000;

// =================================================================
// MIDDLEWARE
// =================================================================

app.use(cors({ origin: '*', credentials: true }));

// Fix 7: store raw Buffer in req.rawBody BEFORE JSON parse,
//        so the Stripe webhook can use it for signature verification.
app.use(
  bodyParser.json({
    limit: '50mb',
    type: 'application/json',
    verify: (req, _res, buf) => {
      req.rawBody = buf; // raw Buffer — used by /api/payment/webhook
    }
  })
);
app.use(bodyParser.urlencoded({ extended: true, limit: '50mb' }));

// Anti-cache headers (skip for webhook — Stripe needs unmodified response)
app.use((req, res, next) => {
  if (req.originalUrl === '/api/payment/webhook') return next();
  res.setHeader('Cache-Control', 'no-store, no-cache, must-revalidate, proxy-revalidate');
  res.setHeader('Pragma', 'no-cache');
  res.setHeader('Expires', '0');
  next();
});

// Serve uploaded files statically
app.use('/uploads', express.static(path.join(__dirname, 'uploads'), {
  maxAge: 0,
  etag: false,
  lastModified: false
}));

if (process.env.NODE_ENV === 'development') {
  app.use((req, _res, next) => {
    console.log(`${req.method} ${req.path}`);
    next();
  });
}

// =================================================================
// ROUTES
// =================================================================

app.get('/', (_req, res) => {
  res.status(200).json({
    success: true,
    message: 'Virtual Try-On API Server is running!',
    version: '1.0.0',
    timestamp: new Date().toISOString()
  });
});

app.get('/download-app', (req, res) => {
  const pagePath = require('path').join(__dirname, 'uploads', 'apk', 'index.html');
  const fs = require('fs');
  if (fs.existsSync(pagePath)) {
    res.sendFile(pagePath);
  } else {
    res.status(404).send(
      '<h2>Run <code>node apk-share.js</code> first to generate the download page.</h2>'
    );
  }
});
 
app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(specs));
app.use('/api/dresses', dressRoutes);
app.use('/api/orders', orderRoutes);
app.use('/api/payment', paymentRoutes);
app.use('/api/reviews', reviewRoutes);
app.use('/api/tryon', tryonRoutes);
app.use('/api/admin', adminRoutes);

app.get('/api', (_req, res) => {
  res.status(200).json({
    success: true,
    message: 'API root',
    endpoints: ['/api/dresses', '/api/orders', '/api/payment', '/api/reviews', '/api/tryon', '/api/admin']
  });
});

// Discovery endpoint — returns backend URL as JSON and as a QR page
app.get('/api/discover', (_req, res) => {
  const localIp = Object.values(os.networkInterfaces())
    .flat()
    .find(i => i && i.family === 'IPv4' && !i.internal)?.address || '127.0.0.1';
  res.json({ apiRoot: `http://${localIp}:${PORT}` });
});

app.get('/discover', (_req, res) => {
  const localIp = Object.values(os.networkInterfaces())
    .flat()
    .find(i => i && i.family === 'IPv4' && !i.internal)?.address || '127.0.0.1';
  const apiRoot = `http://${localIp}:${PORT}`;
  const qrUrl = `https://api.qrserver.com/v1/create-qr-code/?size=300x300&data=${encodeURIComponent(apiRoot)}`;
  res.send(`<!doctype html><html><head><meta charset="utf-8"><title>Discover AuraTry Backend</title></head>
<body style="font-family:Arial,sans-serif;text-align:center;padding:40px">
<h1>Discover Backend</h1><p>Scan from your mobile or copy the URL</p>
<img src="${qrUrl}" alt="QR"/>
<p>Server: <a href="${apiRoot}">${apiRoot}</a></p>
</body></html>`);
});

// =================================================================
// ERROR HANDLING
// =================================================================

app.use((_req, res) => res.status(404).json({ success: false, message: 'Route not found' }));

app.use((err, _req, res, _next) => {
  console.error('Error:', err.stack);
  res.status(err.status || 500).json({
    success: false,
    message: err.message || 'Internal Server Error',
    error: process.env.NODE_ENV === 'development' ? err.stack : undefined
  });
});

// =================================================================
// START SERVER
// =================================================================

app.listen(PORT, '0.0.0.0', () => {
  const localIp = Object.values(os.networkInterfaces())
    .flat()
    .find(i => i && i.family === 'IPv4' && !i.internal)?.address || 'unknown';

  console.log('╔════════════════════════════════════════════╗');
  console.log('║   🚀 AuraTry Backend Server               ║');
  console.log('╚════════════════════════════════════════════╝');
  console.log(`✅ http://localhost:${PORT}`);
  console.log(`✅ Environment: ${process.env.NODE_ENV || 'development'}`);
  console.log(`✅ Database: ${process.env.DB_NAME}`);
  console.log(`📱 Physical device: http://${localIp}:${PORT}/api`);
  console.log('════════════════════════════════════════════');
});

process.on('SIGINT', () => {
  console.log('\n⚠️ Shutting down...');
  db.end((err) => {
    if (err) console.error('DB close error:', err);
    process.exit(0);
  });
});

module.exports = app;