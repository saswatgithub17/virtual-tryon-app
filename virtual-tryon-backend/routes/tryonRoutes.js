// =============================================
// VIRTUAL TRY-ON ROUTES
// AI-powered try-on endpoints
// =============================================

const express = require('express');
const router = express.Router();
const tryonController = require('../controllers/Tryoncontroller');
const { uploadUserPhoto, handleUploadError } = require('../middleware/upload');

/**
 * @swagger
 * /api/tryon:
 *   post:
 *     summary: Process virtual try-on
 *     tags: [TryOn]
 *     requestBody:
 *       content:
 *         multipart/form-data:
 *           schema:
 *             type: object
 *             properties:
 *               userPhoto:
 *                 type: string
 *                 format: binary
 *               dress_ids:
 *                 type: string
 *                 description: JSON string array of dress IDs (e.g., "[1,2]")
 *     responses:
 *       200:
 *         description: Try-on processed successfully
 */
router.post('/', uploadUserPhoto, handleUploadError, tryonController.processTryOn);


module.exports = router;