// =============================================
// AUTHENTICATION MIDDLEWARE
// JWT Token Verification
// =============================================

const jwt = require('jsonwebtoken');
require('dotenv').config();

// Verify JWT token middleware
const verifyToken = (req, res, next) => {
    // Get token from header
    const token = req.headers['authorization']?.split(' ')[1]; // Bearer <token>

    if (!token) {
        return res.status(401).json({
            success: false,
            message: 'Access denied. No token provided.'
        });
    }

    try {
        // Verify token
        const decoded = jwt.verify(token, process.env.JWT_SECRET);
        req.admin = decoded; // Add admin info to request
        next();
    } catch (error) {
        return res.status(401).json({
            success: false,
            message: 'Invalid or expired token.'
        });
    }
};

// Check if user is admin
const isAdmin = (req, res, next) => {
    if (!req.admin) {
        return res.status(403).json({
            success: false,
            message: 'Access denied. Admin privileges required.'
        });
    }
    next();
};

module.exports = {
    verifyToken,
    isAdmin
};