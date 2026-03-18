const express = require('express');
const router = express.Router();
const adminController = require('../controllers/Admincontroller');
const { verifyToken, isAdmin } = require('../middleware/auth');
const { uploadDressImage, handleUploadError } = require('../middleware/upload');

// ─── Auth ─────────────────────────────────────────────────────────────────────
router.post('/login',  adminController.login);
router.post('/logout', verifyToken, adminController.logout);

// ─── Stats (live from MySQL) ──────────────────────────────────────────────────
router.get('/stats', verifyToken, isAdmin, adminController.getStats);

// ─── Orders ──────────────────────────────────────────────────────────────────
router.get('/orders',                    verifyToken, isAdmin, adminController.getAllOrders);
router.put('/orders/:orderId/complete',  verifyToken, isAdmin, adminController.markOrderComplete);

// ─── Receipts ─────────────────────────────────────────────────────────────────
router.get('/receipts', verifyToken, isAdmin, adminController.getAllReceipts);

// ─── Try-On History ───────────────────────────────────────────────────────────
router.get('/tryon-history', verifyToken, isAdmin, adminController.getTryOnHistory);

// ─── Dresses ──────────────────────────────────────────────────────────────────
router.get('/dresses',     verifyToken, isAdmin, adminController.getAllDressesWithSizes);
router.post('/dresses',    verifyToken, isAdmin, adminController.addDress);
router.put('/dresses/:id', verifyToken, isAdmin, adminController.updateDress);

// Image upload for a dress (separate multipart endpoint)
router.post(
  '/dresses/:id/upload-image',
  verifyToken, isAdmin,
  uploadDressImage, handleUploadError,
  adminController.uploadDressImage
);

// Legacy analytics + transactions (kept for backward compat)
router.get('/analytics',         verifyToken, isAdmin, adminController.getAnalytics);
router.get('/transactions',      verifyToken, isAdmin, adminController.getAllTransactions);
router.get('/transactions/:id',  verifyToken, isAdmin, adminController.getTransactionById);

module.exports = router;