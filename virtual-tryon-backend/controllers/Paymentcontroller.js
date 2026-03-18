// =============================================
// PAYMENT CONTROLLER
// Stripe payment integration
// =============================================

const db = require('../config/database');
const stripe = require('../config/stripe');

// =============================================
// CREATE PAYMENT INTENT
// POST /api/payment/create-intent
// Body: { order_id, amount }
// =============================================
const createPaymentIntent = async (req, res) => {
    const { order_id, amount } = req.body;

    // Validation
    if (!order_id || !amount) {
        return res.status(400).json({
            success: false,
            message: 'order_id and amount are required'
        });
    }

    try {
        // Verify order exists
        const orderQuery = 'SELECT * FROM orders WHERE order_id = ?';
        
        db.query(orderQuery, [order_id], async (err, results) => {
            if (err) {
                console.error('Error fetching order:', err);
                return res.status(500).json({
                    success: false,
                    message: 'Error verifying order',
                    error: err.message
                });
            }

            if (results.length === 0) {
                return res.status(404).json({
                    success: false,
                    message: 'Order not found'
                });
            }

            const order = results[0];

            // Create Stripe payment intent
            const paymentIntent = await stripe.paymentIntents.create({
                amount: Math.round(amount * 100), // Convert to paise/cents
                currency: 'inr',
                metadata: {
                    order_id: order_id,
                    customer_email: order.customer_email
                },
                description: `Order ${order_id}`
            });

            // Update order with payment intent ID
            const updateQuery = `
                UPDATE orders 
                SET stripe_payment_intent_id = ? 
                WHERE order_id = ?
            `;

            db.query(updateQuery, [paymentIntent.id, order_id], (err) => {
                if (err) {
                    console.error('Error updating order with payment intent:', err);
                }
            });

            res.json({
                success: true,
                data: {
                    client_secret: paymentIntent.client_secret,
                    payment_intent_id: paymentIntent.id,
                    amount: amount
                }
            });
        });
    } catch (error) {
        console.error('Stripe error:', error);
        res.status(500).json({
            success: false,
            message: 'Error creating payment intent',
            error: error.message
        });
    }
};

// =============================================
// CONFIRM PAYMENT
// POST /api/payment/confirm
// Body: { order_id, payment_intent_id }
// =============================================
const confirmPayment = async (req, res) => {
    const { order_id, payment_intent_id } = req.body;

    // Validation
    if (!order_id || !payment_intent_id) {
        return res.status(400).json({
            success: false,
            message: 'order_id and payment_intent_id are required'
        });
    }

    try {
        // Retrieve payment intent from Stripe
        const paymentIntent = await stripe.paymentIntents.retrieve(payment_intent_id);

        if (paymentIntent.status === 'succeeded') {
            // Update order payment status
            const updateQuery = `
                UPDATE orders 
                SET 
                    payment_status = 'completed',
                    payment_method = 'stripe',
                    stripe_payment_id = ?
                WHERE order_id = ?
            `;

            db.query(updateQuery, [payment_intent_id, order_id], async (err, result) => {
                if (err) {
                    console.error('Error updating order payment status:', err);
                    return res.status(500).json({
                        success: false,
                        message: 'Error updating payment status',
                        error: err.message
                    });
                }

                if (result.affectedRows === 0) {
                    return res.status(404).json({
                        success: false,
                        message: 'Order not found'
                    });
                }

                // Get order details with items for receipt
                const orderQuery = 'SELECT * FROM orders WHERE order_id = ?';
                const itemsQuery = 'SELECT * FROM order_items WHERE order_id = ?';

                db.query(orderQuery, [order_id], (err, orders) => {
                    if (err || orders.length === 0) {
                        console.error('Error fetching order:', err);
                        return res.status(500).json({
                            success: false,
                            message: 'Error fetching order details'
                        });
                    }

                    db.query(itemsQuery, [order_id], async (err, items) => {
                        if (err) {
                            console.error('Error fetching items:', err);
                            items = [];
                        }

                        const order = orders[0];

                        // Generate receipt
                        const receiptService = require('../services/receiptService');
                        
                        try {
                            const receiptUrl = await receiptService.generateReceipt({
                                ...order,
                                items: items
                            });

                            // Update order with receipt URL
                            db.query(
                                'UPDATE orders SET receipt_url = ? WHERE order_id = ?',
                                [receiptUrl, order_id],
                                (err) => {
                                    if (err) {
                                        console.error('Error updating receipt URL:', err);
                                    }
                                }
                            );

                            res.json({
                                success: true,
                                message: 'Payment confirmed successfully',
                                data: {
                                    order_id,
                                    payment_status: 'completed',
                                    amount: paymentIntent.amount / 100,
                                    receipt_url: receiptUrl
                                }
                            });

                        } catch (receiptError) {
                            console.error('Error generating receipt:', receiptError);
                            
                            // Still return success for payment, but note receipt issue
                            res.json({
                                success: true,
                                message: 'Payment confirmed successfully',
                                data: {
                                    order_id,
                                    payment_status: 'completed',
                                    amount: paymentIntent.amount / 100,
                                    receipt_url: null,
                                    note: 'Receipt generation failed, but payment was successful'
                                }
                            });
                        }
                    });
                });
            });
        } else {
            res.status(400).json({
                success: false,
                message: 'Payment not successful',
                payment_status: paymentIntent.status
            });
        }
    } catch (error) {
        console.error('Stripe error:', error);
        res.status(500).json({
            success: false,
            message: 'Error confirming payment',
            error: error.message
        });
    }
};

// =============================================
// STRIPE WEBHOOK HANDLER
// POST /api/payment/webhook
// =============================================
const handleWebhook = (req, res) => {
    const sig = req.headers['stripe-signature'];
    const webhookSecret = process.env.STRIPE_WEBHOOK_SECRET;

    let event;

    try {
        event = stripe.webhooks.constructEvent(req.body, sig, webhookSecret);
    } catch (err) {
        console.error('Webhook signature verification failed:', err.message);
        return res.status(400).send(`Webhook Error: ${err.message}`);
    }

    // Handle the event
    switch (event.type) {
        case 'payment_intent.succeeded':
            const paymentIntent = event.data.object;
            console.log('PaymentIntent was successful:', paymentIntent.id);
            
            // Update order status
            const orderId = paymentIntent.metadata.order_id;
            if (orderId) {
                const updateQuery = `
                    UPDATE orders 
                    SET payment_status = 'completed'
                    WHERE order_id = ? AND stripe_payment_intent_id = ?
                `;
                
                db.query(updateQuery, [orderId, paymentIntent.id], (err) => {
                    if (err) {
                        console.error('Error updating order from webhook:', err);
                    }
                });
            }
            break;

        case 'payment_intent.payment_failed':
            const failedPayment = event.data.object;
            console.log('PaymentIntent failed:', failedPayment.id);
            
            const failedOrderId = failedPayment.metadata.order_id;
            if (failedOrderId) {
                const updateFailedQuery = `
                    UPDATE orders 
                    SET payment_status = 'failed'
                    WHERE order_id = ? AND stripe_payment_intent_id = ?
                `;
                
                db.query(updateFailedQuery, [failedOrderId, failedPayment.id], (err) => {
                    if (err) {
                        console.error('Error updating failed order:', err);
                    }
                });
            }
            break;

        default:
            console.log(`Unhandled event type ${event.type}`);
    }

    res.json({ received: true });
};

// =============================================
// GET RECEIPT
// GET /api/payment/receipt/:orderId
// =============================================
const getReceipt = async (req, res) => {
    const { orderId } = req.params;

    try {
        // Get order with items
        const orderQuery = 'SELECT * FROM orders WHERE order_id = ?';
        const itemsQuery = 'SELECT * FROM order_items WHERE order_id = ?';

        db.query(orderQuery, [orderId], (err, orders) => {
            if (err) {
                console.error('Error fetching order:', err);
                return res.status(500).json({
                    success: false,
                    message: 'Error fetching order',
                    error: err.message
                });
            }

            if (orders.length === 0) {
                return res.status(404).json({
                    success: false,
                    message: 'Order not found'
                });
            }

            const order = orders[0];

            // Check if receipt already exists
            if (order.receipt_url) {
                return res.json({
                    success: true,
                    data: {
                        receipt_url: order.receipt_url,
                        order_id: orderId
                    }
                });
            }

            // Generate receipt if not exists
            db.query(itemsQuery, [orderId], async (err, items) => {
                if (err) {
                    console.error('Error fetching items:', err);
                    return res.status(500).json({
                        success: false,
                        message: 'Error fetching order items'
                    });
                }

                const receiptService = require('../services/receiptService');

                try {
                    const receiptUrl = await receiptService.generateReceipt({
                        ...order,
                        items: items
                    });

                    // Update order with receipt URL
                    db.query(
                        'UPDATE orders SET receipt_url = ? WHERE order_id = ?',
                        [receiptUrl, orderId],
                        (err) => {
                            if (err) {
                                console.error('Error updating receipt URL:', err);
                            }
                        }
                    );

                    res.json({
                        success: true,
                        data: {
                            receipt_url: receiptUrl,
                            order_id: orderId
                        }
                    });

                } catch (receiptError) {
                    console.error('Error generating receipt:', receiptError);
                    res.status(500).json({
                        success: false,
                        message: 'Error generating receipt',
                        error: receiptError.message
                    });
                }
            });
        });

    } catch (error) {
        console.error('Error:', error);
        res.status(500).json({
            success: false,
            message: 'Error processing request',
            error: error.message
        });
    }
};

module.exports = {
    createPaymentIntent,
    confirmPayment,
    handleWebhook,
    getReceipt
};