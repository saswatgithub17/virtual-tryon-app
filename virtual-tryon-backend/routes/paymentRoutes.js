// backend/routes/payment.js
// Stripe & UPI Payment Route for AuraTry Backend

const express = require('express');
const router = express.Router();
const QRCode = require('qrcode');

// Load environment variables
require('dotenv').config();

// Initialize Stripe with secret key
const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);

// Database
const db = require('../config/database');

// =================================================================
// CREATE PAYMENT - Supports both Stripe and UPI/QR Code
// Body: { order_id, amount, payment_method: 'stripe' | 'upi' }
// =================================================================
router.post('/create-intent', async (req, res) => {
  try {
    // Support multiple parameter names from frontend
    const { 
      order_id, 
      amount, 
      totalAmount,
      payment_method = 'stripe',
      customer_email,
      currency = 'inr'
    } = req.body;

    const finalAmount = Number(amount ?? totalAmount);
    if (!Number.isFinite(finalAmount) || finalAmount <= 0) {
      return res.status(400).json({
        success: false,
        message: 'Invalid amount. Amount must be greater than 0.'
      });
    }

    console.log('💳 Payment request:', { order_id, amount: finalAmount, payment_method });

    // Generate unique transaction ID
    const transactionId = `TXN-${Date.now()}${Math.floor(Math.random() * 1000)}`;

    if (payment_method === 'upi' || payment_method === 'qr') {
      // =====================================
      // UPI / QR Code Payment
      // =====================================
      
      // Get UPI details from environment or use default
      const upiId = process.env.UPI_ID || 'saswatsumandwibedy17@okhdfcbank';
      const merchantName = process.env.MERCHANT_NAME || 'AuraTry';
      
      // Generate UPI payment string
      const upiPaymentString = `upi://pay?pa=${upiId}&pn=${encodeURIComponent(merchantName)}&am=${finalAmount}&cu=INR&tn=${transactionId}`;
      
      // Generate QR code as data URL
      const qrCodeDataUrl = await QRCode.toDataURL(upiPaymentString, {
        width: 300,
        margin: 2,
        color: {
          dark: '#000000',
          light: '#ffffff'
        }
      });

      // Save transaction to database
      const insertQuery = `
        INSERT INTO payment_transactions 
        (transaction_id, order_id, amount, payment_method, status, upi_transaction_id)
        VALUES (?, ?, ?, ?, 'pending', ?)
      `;
      
      db.query(insertQuery, [transactionId, order_id || null, finalAmount, 'upi', transactionId], (err) => {
        if (err) {
          console.error('Error saving UPI transaction:', err);
        }
      });

      // Return QR code and payment details
      res.json({
        success: true,
        payment_method: 'upi',
        transaction_id: transactionId,
        amount: finalAmount,
        qr_code: qrCodeDataUrl,
        upi_payment_string: upiPaymentString,
        upi_id: upiId,
        message: 'QR code generated successfully. Scan to pay.'
      });

    } else {
      // =====================================
      // Stripe Payment
      // =====================================
      
      // Create Stripe payment intent
      const paymentIntent = await stripe.paymentIntents.create({
        amount: Math.round(finalAmount * 100), // Convert to paise/cents
        currency: currency.toLowerCase(),
        description: order_id ? `Order ${order_id}` : 'AuraTry Dress Purchase',
        automatic_payment_methods: {
          enabled: true,
        },
        metadata: {
          app: 'AuraTry',
          platform: 'mobile',
          order_id: order_id || '',
          transaction_id: transactionId
        },
      });

      // Save transaction to database
      const insertQuery = `
        INSERT INTO payment_transactions 
        (transaction_id, order_id, amount, payment_method, status, stripe_payment_intent_id)
        VALUES (?, ?, ?, ?, 'pending', ?)
      `;
      
      db.query(insertQuery, [transactionId, order_id || null, finalAmount, 'stripe', paymentIntent.id], (err) => {
        if (err) {
          console.error('Error saving Stripe transaction:', err);
        }
      });

      // Return client secret to Flutter app
      res.json({
        success: true,
        payment_method: 'stripe',
        transaction_id: transactionId,
        client_secret: paymentIntent.client_secret,
        payment_intent_id: paymentIntent.id,
        clientSecret: paymentIntent.client_secret,
        paymentIntentId: paymentIntent.id,
        amount: finalAmount,
        currency: currency
      });
    }
    
  } catch (error) {
    console.error('❌ Error creating payment:', error);
    res.status(500).json({
      success: false,
      message: error.message || 'Failed to create payment',
    });
  }
});

// =================================================================
// CHECK PAYMENT STATUS
// =================================================================
router.post('/check-status', async (req, res) => {
  try {
    const { transaction_id, payment_intent_id, order_id } = req.body;
    
    console.log('🔍 Checking payment status:', { transaction_id, payment_intent_id, order_id });

    // First check our database
    let query = 'SELECT * FROM payment_transactions WHERE 1=1';
    let params = [];

    if (transaction_id) {
      query += ' AND transaction_id = ?';
      params.push(transaction_id);
    } else if (payment_intent_id) {
      query += ' AND stripe_payment_intent_id = ?';
      params.push(payment_intent_id);
    } else if (order_id) {
      query += ' AND order_id = ?';
      params.push(order_id);
    } else {
      return res.status(400).json({
        success: false,
        message: 'transaction_id, payment_intent_id, or order_id is required'
      });
    }

    db.query(query, params, async (err, results) => {
      if (err) {
        console.error('Error checking payment status:', err);
        return res.status(500).json({
          success: false,
          message: 'Error checking payment status'
        });
      }

      if (results.length === 0) {
        // If not in our DB, check with Stripe
        if (payment_intent_id) {
          try {
            const paymentIntent = await stripe.paymentIntents.retrieve(payment_intent_id);
            return res.json({
              success: true,
              status: paymentIntent.status,
              payment_method: 'stripe',
              amount: paymentIntent.amount / 100
            });
          } catch (stripeError) {
            return res.status(404).json({
              success: false,
              message: 'Payment not found'
            });
          }
        }
        
        return res.status(404).json({
          success: false,
          message: 'Payment not found'
        });
      }

      const transaction = results[0];

      // If Stripe payment, verify with Stripe
      if (transaction.payment_method === 'stripe' && transaction.stripe_payment_intent_id) {
        try {
          const paymentIntent = await stripe.paymentIntents.retrieve(transaction.stripe_payment_intent_id);
          
          // Update our records if status changed
          if (paymentIntent.status === 'succeeded' && transaction.status !== 'completed') {
            db.query('UPDATE payment_transactions SET status = ? WHERE transaction_id = ?', 
              ['completed', transaction.transaction_id]);
          }
          
          return res.json({
            success: true,
            status: paymentIntent.status,
            payment_method: 'stripe',
            amount: transaction.amount,
            transaction_id: transaction.transaction_id
          });
        } catch (stripeError) {
          console.error('Stripe error:', stripeError);
        }
      }

      // For UPI payments, return current status
      res.json({
        success: true,
        status: transaction.status,
        payment_method: transaction.payment_method,
        amount: transaction.amount,
        transaction_id: transaction.transaction_id,
        created_at: transaction.created_at
      });
    });

  } catch (error) {
    console.error('❌ Error checking payment status:', error);
    res.status(500).json({
      success: false,
      message: error.message || 'Failed to check payment status',
    });
  }
});

// =================================================================
// CONFIRM PAYMENT (for manual/UPI confirmation)
// =================================================================
router.post('/confirm', async (req, res) => {
  try {
    const {
      transaction_id,
      order_id,
      payment_method,
      payment_intent_id,
      paymentIntentId
    } = req.body;
    const stripePaymentId = payment_intent_id || paymentIntentId || null;
    
    console.log('💰 Payment confirmation:', { transaction_id, order_id, payment_method });

    if (!transaction_id && !order_id) {
      return res.status(400).json({
        success: false,
        message: 'transaction_id or order_id is required'
      });
    }

    // Update transaction status
    let query = 'UPDATE payment_transactions SET status = ?';
    let params = ['completed'];

    if (transaction_id) {
      query += ' WHERE transaction_id = ?';
      params.push(transaction_id);
    } else {
      query += ' WHERE order_id = ?';
      params.push(order_id);
    }

    db.query(query, params, async (err, result) => {
      if (err) {
        console.error('Error confirming payment:', err);
        return res.status(500).json({
          success: false,
          message: 'Error confirming payment'
        });
      }

      // If order_id provided, also update the order
      if (order_id) {
        const updateOrderQuery = `
          UPDATE orders 
          SET payment_status = 'completed', 
              payment_method = ?,
              stripe_payment_id = ?
          WHERE order_id = ?
        `;
        
        db.query(
          updateOrderQuery,
          [payment_method || 'upi', transaction_id || stripePaymentId, order_id],
          async (err) => {
          if (err) {
            console.error('Error updating order:', err);
          }

          // Generate receipt
          try {
            const orderQuery = 'SELECT * FROM orders WHERE order_id = ?';
            const itemsQuery = 'SELECT * FROM order_items WHERE order_id = ?';

            db.query(orderQuery, [order_id], async (err, orders) => {
              if (err || orders.length === 0) {
                console.error('Error fetching order for receipt:', err);
                return res.json({
                  success: true,
                  message: 'Payment confirmed successfully',
                  receipt_url: null
                });
              }

              db.query(itemsQuery, [order_id], async (err, items) => {
                const receiptService = require('../services/receiptService');
                
                try {
                  const receiptUrl = await receiptService.generateReceipt({
                    ...orders[0],
                    items: items || []
                  });

                  // Update order with receipt URL
                  db.query('UPDATE orders SET receipt_url = ? WHERE order_id = ?', 
                    [receiptUrl, order_id]);

                  res.json({
                    success: true,
                    message: 'Payment confirmed successfully',
                    receipt_url: receiptUrl,
                    receiptUrl: receiptUrl,
                    order_id: order_id
                  });
                } catch (receiptError) {
                  console.error('Error generating receipt:', receiptError);
                  res.json({
                    success: true,
                    message: 'Payment confirmed',
                    receipt_url: null,
                    receiptUrl: null,
                    order_id: order_id
                  });
                }
              });
            });
          } catch (receiptError) {
            console.error('Receipt error:', receiptError);
            res.json({
              success: true,
              message: 'Payment confirmed',
              receipt_url: null,
              receiptUrl: null
            });
          }
        });
      } else {
        res.json({
          success: true,
          message: 'Payment confirmed successfully'
        });
      }
    });

  } catch (error) {
    console.error('❌ Error confirming payment:', error);
    res.status(500).json({
      success: false,
      message: error.message || 'Failed to confirm payment',
    });
  }
});


// =================================================================
// GET PAYMENT STATUS
// =================================================================
router.get('/status/:paymentIntentId', async (req, res) => {
  try {
    const { paymentIntentId } = req.params;
    
    const paymentIntent = await stripe.paymentIntents.retrieve(paymentIntentId);
    
    res.json({
      success: true,
      status: paymentIntent.status,
      amount: paymentIntent.amount / 100,
      currency: paymentIntent.currency,
      created: new Date(paymentIntent.created * 1000),
    });
    
  } catch (error) {
    console.error('❌ Error getting payment status:', error);
    res.status(500).json({
      success: false,
      error: error.message || 'Failed to get payment status',
    });
  }
});


// =================================================================
// REFUND PAYMENT
// =================================================================
router.post('/refund', async (req, res) => {
  try {
    const { paymentIntentId, amount, reason } = req.body;
    
    if (!paymentIntentId) {
      return res.status(400).json({
        error: 'Payment Intent ID is required'
      });
    }
    
    const refundParams = {
      payment_intent: paymentIntentId,
      reason: reason || 'requested_by_customer',
    };
    
    // If partial refund, add amount
    if (amount) {
      refundParams.amount = Math.round(amount * 100);
    }
    
    const refund = await stripe.refunds.create(refundParams);
    
    res.json({
      success: true,
      refundId: refund.id,
      status: refund.status,
      amount: refund.amount / 100,
      currency: refund.currency,
    });
    
  } catch (error) {
    console.error('❌ Error processing refund:', error);
    res.status(500).json({
      success: false,
      error: error.message || 'Failed to process refund',
    });
  }
});


// =================================================================
// WEBHOOK ENDPOINT (for Stripe events)
// =================================================================
router.post('/webhook', express.raw({ type: 'application/json' }), async (req, res) => {
  const sig = req.headers['stripe-signature'];
  const webhookSecret = process.env.STRIPE_WEBHOOK_SECRET;
  
  let event;
  
  try {
    // Verify webhook signature
    event = stripe.webhooks.constructEvent(req.body, sig, webhookSecret);
  } catch (err) {
    console.error('❌ Webhook signature verification failed:', err.message);
    return res.status(400).send(`Webhook Error: ${err.message}`);
  }
  
  // Handle the event
  switch (event.type) {
    case 'payment_intent.succeeded':
      const paymentIntent = event.data.object;
      console.log('✅ Payment succeeded:', paymentIntent.id);
      // TODO: Update order status in database
      break;
      
    case 'payment_intent.payment_failed':
      const failedPayment = event.data.object;
      console.log('❌ Payment failed:', failedPayment.id);
      // TODO: Notify user, update order status
      break;
      
    case 'charge.refunded':
      const refund = event.data.object;
      console.log('💰 Refund processed:', refund.id);
      // TODO: Update order status, notify user
      break;
      
    default:
      console.log(`Unhandled event type: ${event.type}`);
  }
  
  // Return 200 to acknowledge receipt
  res.json({ received: true });
});


// =================================================================
// CREATE CUSTOMER (for saved payment methods)
// =================================================================
router.post('/create-customer', async (req, res) => {
  try {
    const { email, name, phone } = req.body;
    
    const customer = await stripe.customers.create({
      email,
      name,
      phone,
      metadata: {
        app: 'AuraTry',
      },
    });
    
    res.json({
      success: true,
      customerId: customer.id,
      email: customer.email,
    });
    
  } catch (error) {
    console.error('❌ Error creating customer:', error);
    res.status(500).json({
      success: false,
      error: error.message || 'Failed to create customer',
    });
  }
});


// =================================================================
// TEST ENDPOINT
// =================================================================
router.get('/test', (req, res) => {
  res.json({
    success: true,
    message: 'Payment routes are working!',
    stripe_configured: !!process.env.STRIPE_SECRET_KEY,
    timestamp: new Date().toISOString(),
  });
});


module.exports = router;
