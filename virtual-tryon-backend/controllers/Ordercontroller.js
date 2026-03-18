// =============================================
// ORDER CONTROLLER
// Handles order management
// =============================================

const db = require('../config/database');
const { v4: uuidv4 } = require('uuid');

// =============================================
// CREATE NEW ORDER
// POST /api/orders
// Body: { customer_name, customer_email, customer_phone, items: [{dress_id, size, quantity}] }
// =============================================
const createOrder = (req, res) => {
    console.log('📦 Order request received:', JSON.stringify(req.body));

    // Support multiple field naming conventions from frontend
    const {
        customer_name,
        customerEmail,
        customer_email,
        customer_phone,
        customerPhone,
        items,
        products,
        productList,
        dress_id,
        id
    } = req.body;

    // Normalize field names
    const name = customer_name || customerEmail || req.body.name || 'Customer';
    const email = customer_email || customerEmail || req.body.email;
    const phone = customer_phone || customerPhone || req.body.phone;
    
    // Handle different formats - items array, single item, or products array
    let orderItems = items || products || productList;
    
    // If no array but there's a single item, convert to array
    if (!orderItems && (dress_id || id)) {
        orderItems = [{ 
            dress_id: dress_id || id,
            quantity: req.body.quantity || 1,
            size_name: req.body.size_name || req.body.size || req.body.selectedSize
        }];
    }
    
    // Ensure it's an array
    if (!Array.isArray(orderItems)) {
        orderItems = [];
    }

    // Validation
    if (!name || !email) {
        return res.status(400).json({
            success: false,
            message: 'Customer name and email are required',
            received: req.body
        });
    }

    if (!orderItems || !Array.isArray(orderItems) || orderItems.length === 0) {
        return res.status(400).json({
            success: false,
            message: 'Items are required',
            received: req.body
        });
    }

    console.log('📋 Processing order items:', JSON.stringify(orderItems));

    // Generate unique order ID
    const orderId = `ORD-${Date.now()}${Math.floor(Math.random() * 1000)}`;

    // Calculate total amount from items
    let totalAmount = 0;
    let processedItems = 0;
    const processedOrderItems = [];

    // Process each item to get dress details and calculate total
    orderItems.forEach((item, index) => {
        // Handle different field name formats from Flutter frontend
        const itemDressId = item.dress_id || item.dressId || item.id || item.dressid;
        
        console.log(`🔍 Processing item ${index + 1}:`, item, 'Dress ID:', itemDressId);
        
        if (!itemDressId) {
            console.log('⚠️ No dress_id found in item:', item);
            processedItems++;
            if (processedItems === orderItems.length) {
                if (processedOrderItems.length === 0) {
                    return res.status(400).json({
                        success: false,
                        message: 'No valid items found in order - missing dress_id'
                    });
                }
            }
            return;
        }
        
        const query = 'SELECT dress_id, name, price FROM dresses WHERE dress_id = ?';
        
        db.query(query, [itemDressId], (err, results) => {
            if (err) {
                console.error('Error fetching dress:', err);
                processedItems++;
                return;
            }

            console.log(`📦 Database query for dress_id ${itemDressId}:`, results.length, 'results');

            if (results.length > 0) {
                const dress = results[0];
                const quantity = item.quantity || item.qty || 1;
                const subtotal = dress.price * quantity;
                
                totalAmount += subtotal;
                
                processedOrderItems.push({
                    dress_id: dress.dress_id,
                    dress_name: dress.name,
                    size_name: item.size_name || item.size || item.selectedSize || 'Default',
                    quantity: quantity,
                    price: dress.price,
                    subtotal: subtotal
                });
            } else {
                console.log(`⚠️ Dress not found for dress_id: ${itemDressId}`);
            }

            processedItems++;

            // After all items processed, create the order
            if (processedItems === orderItems.length) {
                console.log('✅ Processed items:', processedOrderItems.length, 'of', orderItems.length);
                if (processedOrderItems.length === 0) {
                    return res.status(400).json({
                        success: false,
                        message: 'No valid items found in order - dresses may not exist in database',
                        debug: {
                            requestedItems: orderItems,
                            processedCount: processedItems
                        }
                    });
                }

                const insertOrderQuery = `
                    INSERT INTO orders 
                    (order_id, customer_name, customer_email, customer_phone, total_amount, payment_status)
                    VALUES (?, ?, ?, ?, ?, 'pending')
                `;

                const orderParams = [
                    orderId,
                    name,
                    email,
                    phone || null,
                    totalAmount
                ];

                db.query(insertOrderQuery, orderParams, (err) => {
                    if (err) {
                        console.error('Error creating order:', err);
                        return res.status(500).json({
                            success: false,
                            message: 'Error creating order',
                            error: err.message
                        });
                    }

                    // Insert order items
                    const insertItemsQuery = `
                        INSERT INTO order_items 
                        (order_id, dress_id, dress_name, size_name, quantity, price, subtotal)
                        VALUES ?
                    `;

                    const itemsParams = processedOrderItems.map(item => [
                        orderId,
                        item.dress_id,
                        item.dress_name,
                        item.size_name,
                        item.quantity,
                        item.price,
                        item.subtotal
                    ]);

                    db.query(insertItemsQuery, [itemsParams], (err) => {
                        if (err) {
                            console.error('Error adding order items:', err);
                        }

                        res.status(201).json({
                            success: true,
                            message: 'Order created successfully',
                            data: {
                                order_id: orderId,
                                total_amount: totalAmount,
                                items: processedOrderItems,
                                payment_status: 'pending'
                            }
                        });
                    });
                });
            }
        });
    });
};

// =============================================
// GET ORDER BY ID
// GET /api/orders/:orderId
// =============================================
const getOrderById = (req, res) => {
    const { orderId } = req.params;

    const orderQuery = 'SELECT * FROM orders WHERE order_id = ?';
    const itemsQuery = 'SELECT * FROM order_items WHERE order_id = ?';

    db.query(orderQuery, [orderId], (err, orderResults) => {
        if (err) {
            console.error('Error fetching order:', err);
            return res.status(500).json({
                success: false,
                message: 'Error fetching order',
                error: err.message
            });
        }

        if (orderResults.length === 0) {
            return res.status(200).json({
                success: false,
                message: 'Order not found',
                data: null
            });
        }

        db.query(itemsQuery, [orderId], (err, items) => {
            if (err) {
                console.error('Error fetching order items:', err);
                items = [];
            }

            res.status(200).json({
                success: true,
                data: {
                    ...orderResults[0],
                    items: items
                }
            });
        });
    });
};

// =============================================
// CALCULATE CART TOTAL
// POST /api/orders/calculate
// Body: { items: [{dress_id, quantity}] }
// =============================================
const calculateTotal = (req, res) => {
    const { items } = req.body;

    if (!items || !Array.isArray(items) || items.length === 0) {
        return res.status(400).json({
            success: false,
            message: 'Items array is required'
        });
    }

    let totalAmount = 0;
    let processedItems = 0;
    const calculatedItems = [];

    items.forEach((item) => {
        const query = 'SELECT dress_id, name, price FROM dresses WHERE dress_id = ?';
        
        db.query(query, [item.dress_id], (err, results) => {
            if (err) {
                console.error('Error fetching dress:', err);
                return;
            }

            if (results.length > 0) {
                const dress = results[0];
                const quantity = item.quantity || 1;
                const subtotal = dress.price * quantity;
                
                totalAmount += subtotal;
                
                calculatedItems.push({
                    dress_id: dress.dress_id,
                    name: dress.name,
                    price: dress.price,
                    quantity: quantity,
                    subtotal: subtotal
                });
            }

            processedItems++;

            if (processedItems === items.length) {
                res.json({
                    success: true,
                    data: {
                        items: calculatedItems,
                        total_amount: totalAmount,
                        item_count: calculatedItems.length
                    }
                });
            }
        });
    });
};

// =============================================
// GET ALL ORDERS (Admin)
// GET /api/orders
// =============================================
const getAllOrders = (req, res) => {
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
            console.error('Error fetching orders:', err);
            return res.status(500).json({
                success: false,
                message: 'Error fetching orders',
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
// GET ALL TRANSACTIONS (Admin)
// GET /api/orders/transactions/all
// =============================================
const getAllTransactions = (req, res) => {
    const query = `
        SELECT * FROM orders 
        WHERE payment_status = 'completed'
        ORDER BY created_at DESC
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

module.exports = {
    createOrder,
    getOrderById,
    calculateTotal,
    getAllOrders,
    getAllTransactions
};