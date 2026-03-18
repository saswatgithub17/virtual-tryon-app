// =============================================
// DRESS ROUTES
// Endpoints for dress catalog management
// =============================================

const express = require('express');
const router = express.Router();
const dressController = require('../controllers/Dresscontroller');
const { verifyToken, isAdmin } = require('../middleware/auth');
const { uploadDressImage, handleUploadError } = require('../middleware/upload');

// =============================================
// PUBLIC ROUTES (Customer Access)
// =============================================

/**
 * @swagger
 * /api/dresses:
 *   get:
 *     summary: Get all dresses
 *     tags: [Dresses]
 *     responses:
 *       200:
 *         description: List of all dresses
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                 count:
 *                   type: integer
 *                 data:
 *                   type: array
 *                   items:
 *                     type: object
 */
router.get('/', dressController.getAllDresses);

// GET /api/dresses/search - Search dresses
router.get('/search/query', dressController.searchDresses);

/**
 * @swagger
 * /api/dresses/{id}:
 *   get:
 *     summary: Get dress by ID
 *     tags: [Dresses]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Dress details
 *       404:
 *         description: Dress not found
 */
router.get('/:id', dressController.getDressById);

// =============================================
// ADMIN ROUTES (Require Authentication)
// =============================================

/**
 * @swagger
 * /api/dresses:
 *   post:
 *     summary: Add a new dress
 *     tags: [Dresses]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - name
 *               - price
 *               - category
 *             properties:
 *               name:
 *                 type: string
 *               price:
 *                 type: number
 *               category:
 *                 type: string
 *               description:
 *                 type: string
 *     responses:
 *       201:
 *         description: Dress created successfully
 *       401:
 *         description: Unauthorized
 */
router.post('/', verifyToken, isAdmin, dressController.addDress);

// PUT /api/dresses/:id - Update dress (Admin only)
router.put('/:id', verifyToken, isAdmin, dressController.updateDress);

// DELETE /api/dresses/:id - Delete dress (Admin only)
router.delete('/:id', verifyToken, isAdmin, dressController.deleteDress);

// POST /api/dresses/upload - Upload dress image (Admin only)
router.post('/upload', verifyToken, isAdmin, uploadDressImage, handleUploadError, dressController.uploadDressImage);

module.exports = router;
