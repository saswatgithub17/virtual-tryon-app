// =============================================
// ADMIN ROUTES
// Admin authentication and analytics
// =============================================

const express = require('express');
const router = express.Router();
const adminController = require('../controllers/Admincontroller');
const { verifyToken, isAdmin } = require('../middleware/auth');

// POST /api/admin/login - Admin login
router.post('/login', adminController.login);

// POST /api/admin/logout - Admin logout
router.post('/logout', verifyToken, adminController.logout);

// GET /api/admin/analytics - Get sales analytics (Admin only)
router.get('/analytics', verifyToken, isAdmin, adminController.getAnalytics);

// GET /api/admin/transactions - Get all transactions (Admin only)
router.get('/transactions', verifyToken, isAdmin, adminController.getAllTransactions);

// GET /api/admin/transactions/:id - Get transaction details (Admin only)
router.get('/transactions/:id', verifyToken, isAdmin, adminController.getTransactionById);

module.exports = router;