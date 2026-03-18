// =============================================
// REVIEW ROUTES
// Endpoints for customer reviews and ratings
// =============================================

const express = require('express');
const router = express.Router();
const reviewController = require('../controllers/Reviewcontroller');

// GET /api/reviews/:dressId - Get reviews for a specific dress
router.get('/:dressId', reviewController.getReviewsByDress);

// POST /api/reviews - Add new review
router.post('/', reviewController.addReview);

module.exports = router;