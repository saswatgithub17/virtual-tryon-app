// =============================================
// VIRTUAL TRY-ON BACKEND SERVER
// Main Entry Point
// =============================================

const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
const dotenv = require('dotenv');
const path = require('path');
const os = require('os');

// Load environment variables
dotenv.config();

// Import database connection
const db = require('./config/database');

// Import routes
const dressRoutes = require('./routes/dressRoutes');
const orderRoutes = require('./routes/orderRoutes');
const paymentRoutes = require('./routes/paymentRoutes');
const reviewRoutes = require('./routes/reviewRoutes');
const tryonRoutes = require('./routes/tryonRoutes');
const adminRoutes = require('./routes/adminRoutes');

// Import Swagger
const { specs, swaggerUi } = require('./config/swagger');


// Initialize Express app
const app = express();
const PORT = process.env.PORT || 5000;

// =============================================
// MIDDLEWARE
// =============================================

// CORS configuration
app.use(cors({
    origin: '*',
    credentials: true
}));

// Body parser middleware - FIXED: Use proper type function
// IMPORTANT: Stripe webhook needs raw body, so we configure JSON parser carefully
app.use(bodyParser.json({ 
    limit: '50mb', 
    type: 'application/json',
    verify: (req, res, buf) => {
        // Store raw body for Stripe webhook signature verification
        req.rawBody = buf;
    }
}));
app.use(bodyParser.urlencoded({ extended: true, limit: '50mb', type: 'application/x-www-form-urlencoded' }));

// Anti-cache middleware - Prevent 304 responses
app.use((req, res, next) => {
    // Skip cache headers for Stripe webhook (it handles its own response)
    if (req.originalUrl === '/api/payment/webhook') {
        return next();
    }
    // Set cache control headers to prevent browser caching
    res.setHeader('Cache-Control', 'no-store, no-cache, must-revalidate, proxy-revalidate');
    res.setHeader('Pragma', 'no-cache');
    res.setHeader('Expires', '0');
    res.setHeader('Surrogate-Control', 'no-store');
    next();
});

// Static files middleware (for uploaded images) - with cache busting
app.use('/uploads', express.static(path.join(__dirname, 'uploads'), {
    maxAge: 0, // Disable caching for uploaded files
    etag: false,
    lastModified: false
}));

// Request logging middleware (development)
if (process.env.NODE_ENV === 'development') {
    app.use((req, res, next) => {
        console.log(`${req.method} ${req.path}`);
        next();
    });
}

// =============================================
// ROUTES
// =============================================

// Health check route
app.get('/', (req, res) => {
    res.status(200).json({
        success: true,
        message: 'Virtual Try-On API Server is running!',
        version: '1.0.0',
        timestamp: new Date().toISOString()
    });
});

// Swagger Documentation Route
app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(specs));


// API Routes
app.use('/api/dresses', dressRoutes);
app.use('/api/orders', orderRoutes);
app.use('/api/payment', paymentRoutes);
app.use('/api/reviews', reviewRoutes);
app.use('/api/tryon', tryonRoutes);
app.use('/api/admin', adminRoutes);

// Provide an API root so requests to `/api` return useful info
app.get('/api', (req, res) => {
    res.status(200).json({
        success: true,
        message: 'API root - available endpoints',
        endpoints: [
            '/api/dresses',
            '/api/orders',
            '/api/payment',
            '/api/reviews',
            '/api/tryon',
            '/api/admin',
            '/api/discover'
        ]
    });
});

// Lightweight discovery endpoint - returns the backend API URL (useful for mobile setup)
app.get('/api/discover', (req, res) => {
    const localIp = Object.values(os.networkInterfaces())
        .flat()
        .find(i => i && i.family === 'IPv4' && !i.internal)?.address || '127.0.0.1';

    // Return the server root (health check) URL to avoid 404 on /api
    res.json({ apiRoot: `http://${localIp}:${PORT}` });
});

// Simple discover page with QR image (uses public QR service)
app.get('/discover', (req, res) => {
    const localIp = Object.values(os.networkInterfaces())
        .flat()
        .find(i => i && i.family === 'IPv4' && !i.internal)?.address || '127.0.0.1';
        const apiRoot = `http://${localIp}:${PORT}`;
        const apiBase = `${apiRoot}/api`;
        const qrUrl = `https://api.qrserver.com/v1/create-qr-code/?size=300x300&data=${encodeURIComponent(apiRoot)}`;

        res.send(`<!doctype html>
<html>
<head><meta charset="utf-8"><title>Discover AuraTry Backend</title></head>
<body style="font-family: Arial, sans-serif; text-align:center; padding:40px;">
    <h1>Discover Backend</h1>
    <p>Scan this QR from your mobile device or copy the URL below</p>
    <img src="${qrUrl}" alt="API QR" />
    <p>Server root (health): <a href="${apiRoot}">${apiRoot}</a></p>
    <p>API base: <a href="${apiBase}">${apiBase}</a></p>
</body>
</html>`);
});

// =============================================
// ERROR HANDLING
// =============================================

// 404 Handler
app.use((req, res) => {
    res.status(404).json({
        success: false,
        message: 'Route not found'
    });
});

// Global error handler
app.use((err, req, res, next) => {
    console.error('Error:', err.stack);
    res.status(err.status || 500).json({
        success: false,
        message: err.message || 'Internal Server Error',
        error: process.env.NODE_ENV === 'development' ? err.stack : undefined
    });
});

// =============================================
// START SERVER
// =============================================

app.listen(PORT, '0.0.0.0', () => {
    // Auto-detect current local network IP
    const localIp = Object.values(os.networkInterfaces())
        .flat()
        .find(i => i && i.family === 'IPv4' && !i.internal)?.address || 'unknown';

    console.log('╔════════════════════════════════════════════╗');
    console.log('║   🚀 Virtual Try-On Backend Server        ║');
    console.log('╚════════════════════════════════════════════╝');
    console.log(`✅ Server running on: http://localhost:${PORT}`);
    console.log(`✅ Network access: http://0.0.0.0:${PORT}`);
    console.log(`✅ Environment: ${process.env.NODE_ENV || 'development'}`);
    console.log(`✅ Database: ${process.env.DB_NAME}`);
    console.log('════════════════════════════════════════════');
    console.log('📱 For Android Emulator use: http://10.0.2.2:' + PORT);
    console.log(`📱 For Physical Device use:  http://${localIp}:${PORT}`);
    console.log(`📱 Flutter API URL:           http://${localIp}:${PORT}/api`);
    console.log('════════════════════════════════════════════');
    console.log(`🌐 Current IP detected: ${localIp}`);
    console.log('════════════════════════════════════════════');
});

// Graceful shutdown
process.on('SIGINT', () => {
    console.log('\n⚠️  Shutting down server...');
    db.end((err) => {
        if (err) {
            console.error('❌ Error closing database:', err);
        } else {
            console.log('✅ Database connection closed');
        }
        process.exit(0);
    });
});

module.exports = app;
