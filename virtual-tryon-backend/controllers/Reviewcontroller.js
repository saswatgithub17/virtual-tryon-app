// =============================================
// REVIEW CONTROLLER
// Handles customer reviews and ratings
// =============================================

const db = require('../config/database');

// =============================================
// GET REVIEWS BY DRESS ID
// GET /api/reviews/:dressId
// =============================================
const getReviewsByDress = (req, res) => {
    const { dressId } = req.params;

    const query = `
        SELECT * FROM reviews 
        WHERE dress_id = ? 
        ORDER BY created_at DESC
    `;

    db.query(query, [dressId], (err, results) => {
        if (err) {
            console.error('Error fetching reviews:', err);
            return res.status(500).json({
                success: false,
                message: 'Error fetching reviews',
                error: err.message
            });
        }

        res.status(200).json({
            success: true,
            count: results.length,
            data: results
        });
    });
};

// =============================================
// ADD NEW REVIEW
// POST /api/reviews
// Body: { dress_id, customer_name, customer_email, rating, review_text }
// =============================================
const addReview = (req, res) => {
    const {
        dress_id,
        customer_name,
        customer_email,
        rating,
        review_text
    } = req.body;

    // Validation
    if (!dress_id || !rating) {
        return res.status(400).json({
            success: false,
            message: 'dress_id and rating are required'
        });
    }

    if (rating < 1 || rating > 5) {
        return res.status(400).json({
            success: false,
            message: 'Rating must be between 1 and 5'
        });
    }

    const insertQuery = `
        INSERT INTO reviews 
        (dress_id, customer_name, customer_email, rating, review_text, is_verified)
        VALUES (?, ?, ?, ?, ?, FALSE)
    `;

    const params = [
        dress_id,
        customer_name || 'Anonymous',
        customer_email || null,
        rating,
        review_text || null
    ];

    db.query(insertQuery, params, (err, result) => {
        if (err) {
            console.error('Error adding review:', err);
            
            // Check if dress exists
            if (err.code === 'ER_NO_REFERENCED_ROW_2') {
                return res.status(404).json({
                    success: false,
                    message: 'Dress not found'
                });
            }

            return res.status(500).json({
                success: false,
                message: 'Error adding review',
                error: err.message
            });
        }

        // Update dress average rating and review count
        const updateDressQuery = `
            UPDATE dresses 
            SET 
                average_rating = (
                    SELECT AVG(rating) FROM reviews WHERE dress_id = ?
                ),
                total_reviews = (
                    SELECT COUNT(*) FROM reviews WHERE dress_id = ?
                )
            WHERE dress_id = ?
        `;

        db.query(updateDressQuery, [dress_id, dress_id, dress_id], (err) => {
            if (err) {
                console.error('Error updating dress ratings:', err);
            }
        });

        res.status(201).json({
            success: true,
            message: 'Review added successfully',
            data: {
                review_id: result.insertId,
                dress_id,
                rating
            }
        });
    });
};

module.exports = {
    getReviewsByDress,
    addReview
};