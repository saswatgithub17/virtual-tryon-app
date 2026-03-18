// =============================================
// ADMIN CONTROLLER
// Admin authentication and analytics
// =============================================

const db = require('../config/database');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');

// =============================================
// ADMIN LOGIN
// POST /api/admin/login
// Body: { username, password }
// =============================================
const login = (req, res) => {
    const { username, password } = req.body;

    // Validation
    if (!username || !password) {
        return res.status(400).json({
            success: false,
            message: 'Username and password are required'
        });
    }

    const query = 'SELECT * FROM admins WHERE username = ?';

    db.query(query, [username], async (err, results) => {
        if (err) {
            console.error('Error during login:', err);
            return res.status(500).json({
                success: false,
                message: 'Error during login',
                error: err.message
            });
        }

        if (results.length === 0) {
            return res.status(401).json({
                success: false,
                message: 'Invalid username or password'
            });
        }

        const admin = results[0];
        let isPasswordValid = false;

        // Check if password is plain text (for development)
        if (admin.password_hash === password) {
            // Plain text match - works for development
            isPasswordValid = true;
        } else if (admin.password_hash.startsWith('$2b$') || admin.password_hash.startsWith('$2a$')) {
            // Bcrypt hash - compare properly
            try {
                isPasswordValid = await bcrypt.compare(password, admin.password_hash);
            } catch (error) {
                console.error('Bcrypt comparison error:', error);
                isPasswordValid = false;
            }
        } else {
            // Try plain text comparison as fallback
            isPasswordValid = (admin.password_hash === password);
        }

        if (!isPasswordValid) {
            return res.status(401).json({
                success: false,
                message: 'Invalid username or password'
            });
        }

        // Generate JWT token
        const token = jwt.sign(
            {
                admin_id: admin.admin_id,
                username: admin.username,
                email: admin.email
            },
            process.env.JWT_SECRET || 'default_secret_key',
            { expiresIn: '24h' }
        );

        // Update last login
        db.query(
            'UPDATE admins SET last_login = NOW() WHERE admin_id = ?',
            [admin.admin_id],
            (err) => {
                if (err) console.error('Error updating last login:', err);
            }
        );

        res.json({
            success: true,
            message: 'Login successful',
            data: {
                token,
                admin: {
                    admin_id: admin.admin_id,
                    username: admin.username,
                    email: admin.email,
                    full_name: admin.full_name
                }
            }
        });
    });
};

// =============================================
// ADMIN LOGOUT
// POST /api/admin/logout
// =============================================
const logout = (req, res) => {
    // In JWT, logout is handled client-side by removing the token
    // But we can still provide a confirmation
    res.json({
        success: true,
        message: 'Logout successful'
    });
};

// =============================================
// GET ANALYTICS
// GET /api/admin/analytics
// =============================================
const getAnalytics = (req, res) => {
    const analyticsQuery = `
        SELECT 
            (SELECT COUNT(*) FROM dresses WHERE is_active = TRUE) as total_dresses,
            (SELECT COUNT(*) FROM orders) as total_orders,
            (SELECT COALESCE(SUM(total_amount), 0) FROM orders WHERE payment_status = 'completed') as total_revenue,
            (SELECT COUNT(*) FROM orders WHERE payment_status = 'completed') as completed_orders,
            (SELECT COUNT(*) FROM reviews) as total_reviews,
            (SELECT AVG(rating) FROM reviews) as average_rating,
            (SELECT COUNT(*) FROM orders WHERE DATE(created_at) = CURDATE()) as today_orders,
            (SELECT COALESCE(SUM(total_amount), 0) FROM orders WHERE DATE(created_at) = CURDATE() AND payment_status = 'completed') as today_revenue
    `;

    const topDressesQuery = `
        SELECT 
            d.dress_id,
            d.name,
            d.price,
            d.average_rating,
            COUNT(oi.item_id) as times_ordered
        FROM dresses d
        LEFT JOIN order_items oi ON d.dress_id = oi.dress_id
        GROUP BY d.dress_id
        ORDER BY times_ordered DESC
        LIMIT 5
    `;

    const recentOrdersQuery = `
        SELECT 
            o.order_id,
            o.customer_name,
            o.total_amount,
            o.payment_status,
            o.created_at
        FROM orders o
        ORDER BY o.created_at DESC
        LIMIT 10
    `;

    db.query(analyticsQuery, (err, analyticsResults) => {
        if (err) {
            console.error('Error fetching analytics:', err);
            return res.status(500).json({
                success: false,
                message: 'Error fetching analytics',
                error: err.message
            });
        }

        db.query(topDressesQuery, (err, topDresses) => {
            if (err) {
                console.error('Error fetching top dresses:', err);
                topDresses = [];
            }

            db.query(recentOrdersQuery, (err, recentOrders) => {
                if (err) {
                    console.error('Error fetching recent orders:', err);
                    recentOrders = [];
                }

                res.json({
                    success: true,
                    data: {
                        summary: analyticsResults[0],
                        topDresses: topDresses,
                        recentOrders: recentOrders
                    }
                });
            });
        });
    });
};

// =============================================
// GET ALL TRANSACTIONS
// GET /api/admin/transactions
// =============================================
const getAllTransactions = (req, res) => {
    const query = `
        SELECT 
            o.*,
            COUNT(oi.item_id) as total_items
        FROM orders o
        LEFT JOIN order_items oi ON o.order_id = oi.order_id
        GROUP BY o.order_id
        ORDER BY o.created_at DESC
    `;

    db.query(query, (err, results) => {
        if (err) {
            console.error('Error fetching transactions:', err);
            return res.status(500).json({
                success: false,
                message: 'Error fetching transactions',
                error: err.message
            });
        }

        res.json({
            success: true,
            count: results.length,
            data: results
        });
    });
};

// =============================================
// GET TRANSACTION BY ID
// GET /api/admin/transactions/:id
// =============================================
const getTransactionById = (req, res) => {
    const { id } = req.params;

    const orderQuery = 'SELECT * FROM orders WHERE order_id = ?';
    const itemsQuery = 'SELECT * FROM order_items WHERE order_id = ?';

    db.query(orderQuery, [id], (err, orderResults) => {
        if (err) {
            console.error('Error fetching transaction:', err);
            return res.status(500).json({
                success: false,
                message: 'Error fetching transaction',
                error: err.message
            });
        }

        if (orderResults.length === 0) {
            return res.status(200).json({
                success: false,
                message: 'Transaction not found',
                data: null
            });
        }

        db.query(itemsQuery, [id], (err, items) => {
            if (err) {
                console.error('Error fetching items:', err);
                items = [];
            }

            res.status(200).json({
                success: true,
                data: {
                    order: orderResults[0],
                    items: items
                }
            });
        });
    });
};

module.exports = {
    login,
    logout,
    getAnalytics,
    getAllTransactions,
    getTransactionById
};