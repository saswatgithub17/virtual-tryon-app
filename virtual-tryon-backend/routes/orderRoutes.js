// =============================================
// ORDER ROUTES
// Endpoints for order management
// =============================================

const express = require('express');
const router = express.Router();
const orderController = require('../controllers/Ordercontroller');
const { verifyToken, isAdmin } = require('../middleware/auth');

// =============================================
// PUBLIC ROUTES (Customer Access)
// =============================================

/**
 * @swagger
 * /api/orders:
 *   post:
 *     summary: Create a new order
 *     tags: [Orders]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - customer_name
 *               - customer_email
 *               - items
 *             properties:
 *               customer_name:
 *                 type: string
 *               customer_email:
 *                 type: string
 *               customer_phone:
 *                 type: string
 *               items:
 *                 type: array
 *                 items:
 *                   type: object
 *                   properties:
 *                     dress_id:
 *                       type: integer
 *                     size_name:
 *                       type: string
 *                     quantity:
 *                       type: integer
 *     responses:
 *       201:
 *         description: Order created successfully
 */

// Create new order - POST /api/orders
router.post('/', orderController.createOrder);

// Create new order - POST /api/orders/create (for frontend compatibility)
router.post('/create', orderController.createOrder);

/**
 * @swagger
 * /api/orders/{orderId}:
 *   get:
 *     summary: Get order by ID
 *     tags: [Orders]
 *     parameters:
 *       - in: path
 *         name: orderId
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Order details
 */
router.get('/:orderId', orderController.getOrderById);


// POST /api/orders/calculate - Calculate cart total
router.post('/calculate', orderController.calculateTotal);

// =============================================
// ADMIN ROUTES (Require Authentication)
// =============================================

// GET /api/orders - Get all orders (Admin only)
router.get('/', verifyToken, isAdmin, orderController.getAllOrders);

// GET /api/orders/transactions/all - Get all transactions (Admin only)
router.get('/transactions/all', verifyToken, isAdmin, orderController.getAllTransactions);

module.exports = router;