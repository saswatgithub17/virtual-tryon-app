// ORDER ROUTES
const express = require('express');
const router = express.Router();
const orderController = require('../controllers/Ordercontroller');
const { verifyToken, isAdmin } = require('../middleware/auth');

// ─── PUBLIC ROUTES ────────────────────────────────────────────────────────

// POST /api/orders — create new order
router.post('/', orderController.createOrder);

// POST /api/orders/create — alias for frontend compatibility
router.post('/create', orderController.createOrder);

// POST /api/orders/calculate — calculate cart total
// Fix 6: static paths MUST come before /:orderId
router.post('/calculate', orderController.calculateTotal);

// ─── ADMIN ROUTES (require auth) ─────────────────────────────────────────

// GET /api/orders/transactions/all — all completed transactions
// Fix 6: this was AFTER /:orderId so Express treated "transactions" as orderId
router.get('/transactions/all', verifyToken, isAdmin, orderController.getAllTransactions);

// GET /api/orders — all orders
router.get('/', verifyToken, isAdmin, orderController.getAllOrders);

// ─── PARAMETERISED ROUTES — always last ──────────────────────────────────

// GET /api/orders/:orderId — get single order by ID
// Must come after all static paths, otherwise "calculate" and
// "transactions" would be swallowed as :orderId values.
router.get('/:orderId', orderController.getOrderById);

module.exports = router;