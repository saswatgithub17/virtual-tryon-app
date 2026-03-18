// backend/routes/payment.js
const express = require('express');
const router = express.Router();
const QRCode = require('qrcode');
require('dotenv').config();

const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);
const db = require('../config/database');

// =================================================================
// CREATE PAYMENT INTENT — supports Stripe and UPI/QR
// =================================================================
router.post('/create-intent', async (req, res) => {
  try {
    const {
      order_id,
      amount,
      totalAmount,
      payment_method = 'stripe',
      currency = 'inr'
    } = req.body;

    const finalAmount = Number(amount ?? totalAmount);
    if (!Number.isFinite(finalAmount) || finalAmount <= 0) {
      return res.status(400).json({
        success: false,
        message: 'Invalid amount. Amount must be greater than 0.'
      });
    }

    const transactionId = `TXN-${Date.now()}${Math.floor(Math.random() * 1000)}`;

    if (payment_method === 'upi' || payment_method === 'qr') {
      const upiId = process.env.UPI_ID || 'saswatsumandwibedy17@okhdfcbank';
      const merchantName = process.env.MERCHANT_NAME || 'AuraTry';
      const upiPaymentString = `upi://pay?pa=${upiId}&pn=${encodeURIComponent(merchantName)}&am=${finalAmount}&cu=INR&tn=${transactionId}`;

      const qrCodeDataUrl = await QRCode.toDataURL(upiPaymentString, {
        width: 300,
        margin: 2,
        color: { dark: '#000000', light: '#ffffff' }
      });

      db.query(
        'INSERT INTO payment_transactions (transaction_id, order_id, amount, payment_method, status, upi_transaction_id) VALUES (?, ?, ?, ?, ?, ?)',
        [transactionId, order_id || null, finalAmount, 'upi', 'pending', transactionId],
        (err) => { if (err) console.error('Error saving UPI transaction:', err); }
      );

      return res.json({
        success: true,
        payment_method: 'upi',
        transaction_id: transactionId,
        amount: finalAmount,
        qr_code: qrCodeDataUrl,
        upi_payment_string: upiPaymentString,
        upi_id: upiId,
        message: 'QR code generated. Scan to pay.'
      });
    }

    // Stripe
    const paymentIntent = await stripe.paymentIntents.create({
      amount: Math.round(finalAmount * 100),
      currency: currency.toLowerCase(),
      description: order_id ? `Order ${order_id}` : 'AuraTry Dress Purchase',
      automatic_payment_methods: { enabled: true },
      metadata: { app: 'AuraTry', order_id: order_id || '', transaction_id: transactionId }
    });

    db.query(
      'INSERT INTO payment_transactions (transaction_id, order_id, amount, payment_method, status, stripe_payment_intent_id) VALUES (?, ?, ?, ?, ?, ?)',
      [transactionId, order_id || null, finalAmount, 'stripe', 'pending', paymentIntent.id],
      (err) => { if (err) console.error('Error saving Stripe transaction:', err); }
    );

    res.json({
      success: true,
      payment_method: 'stripe',
      transaction_id: transactionId,
      client_secret: paymentIntent.client_secret,
      payment_intent_id: paymentIntent.id,
      clientSecret: paymentIntent.client_secret,
      paymentIntentId: paymentIntent.id,
      amount: finalAmount,
      currency
    });

  } catch (error) {
    console.error('❌ Error creating payment:', error);
    res.status(500).json({ success: false, message: error.message || 'Failed to create payment' });
  }
});

// =================================================================
// CONFIRM PAYMENT
// =================================================================
router.post('/confirm', async (req, res) => {
  try {
    const { transaction_id, order_id, payment_method, payment_intent_id, paymentIntentId } = req.body;
    const stripePaymentId = payment_intent_id || paymentIntentId || null;

    if (!transaction_id && !order_id) {
      return res.status(400).json({ success: false, message: 'transaction_id or order_id is required' });
    }

    let query = 'UPDATE payment_transactions SET status = ?';
    let params = ['completed'];
    if (transaction_id) { query += ' WHERE transaction_id = ?'; params.push(transaction_id); }
    else { query += ' WHERE order_id = ?'; params.push(order_id); }

    db.query(query, params, async (err) => {
      if (err) {
        console.error('Error confirming payment:', err);
        return res.status(500).json({ success: false, message: 'Error confirming payment' });
      }

      if (order_id) {
        db.query(
          'UPDATE orders SET payment_status = ?, payment_method = ?, stripe_payment_id = ? WHERE order_id = ?',
          [payment_method || 'upi', payment_method || 'upi', transaction_id || stripePaymentId, order_id],
          async (err) => {
            if (err) console.error('Error updating order:', err);

            db.query('SELECT * FROM orders WHERE order_id = ?', [order_id], async (err, orders) => {
              if (err || !orders.length) {
                return res.json({ success: true, message: 'Payment confirmed', receipt_url: null, order_id });
              }
              db.query('SELECT * FROM order_items WHERE order_id = ?', [order_id], async (err, items) => {
                const receiptService = require('../services/receiptService');
                try {
                  const receiptUrl = await receiptService.generateReceipt({ ...orders[0], items: items || [] });
                  db.query('UPDATE orders SET receipt_url = ? WHERE order_id = ?', [receiptUrl, order_id]);
                  res.json({ success: true, message: 'Payment confirmed', receipt_url: receiptUrl, receiptUrl, order_id });
                } catch (receiptErr) {
                  console.error('Receipt error:', receiptErr);
                  res.json({ success: true, message: 'Payment confirmed', receipt_url: null, receiptUrl: null, order_id });
                }
              });
            });
          }
        );
      } else {
        res.json({ success: true, message: 'Payment confirmed' });
      }
    });
  } catch (error) {
    console.error('❌ Error confirming payment:', error);
    res.status(500).json({ success: false, message: error.message || 'Failed to confirm payment' });
  }
});

// =================================================================
// CHECK PAYMENT STATUS
// =================================================================
router.post('/check-status', async (req, res) => {
  try {
    const { transaction_id, payment_intent_id, order_id } = req.body;
    let query = 'SELECT * FROM payment_transactions WHERE 1=1';
    let params = [];

    if (transaction_id) { query += ' AND transaction_id = ?'; params.push(transaction_id); }
    else if (payment_intent_id) { query += ' AND stripe_payment_intent_id = ?'; params.push(payment_intent_id); }
    else if (order_id) { query += ' AND order_id = ?'; params.push(order_id); }
    else return res.status(400).json({ success: false, message: 'transaction_id, payment_intent_id, or order_id required' });

    db.query(query, params, async (err, results) => {
      if (err) return res.status(500).json({ success: false, message: 'Error checking status' });
      if (!results.length) return res.status(404).json({ success: false, message: 'Payment not found' });

      const txn = results[0];
      if (txn.payment_method === 'stripe' && txn.stripe_payment_intent_id) {
        try {
          const pi = await stripe.paymentIntents.retrieve(txn.stripe_payment_intent_id);
          if (pi.status === 'succeeded' && txn.status !== 'completed') {
            db.query('UPDATE payment_transactions SET status = ? WHERE transaction_id = ?', ['completed', txn.transaction_id]);
          }
          return res.json({ success: true, status: pi.status, payment_method: 'stripe', amount: txn.amount, transaction_id: txn.transaction_id });
        } catch (_) {}
      }
      res.json({ success: true, status: txn.status, payment_method: txn.payment_method, amount: txn.amount, transaction_id: txn.transaction_id, created_at: txn.created_at });
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

// =================================================================
// GET PAYMENT STATUS (by paymentIntentId)
// =================================================================
router.get('/status/:paymentIntentId', async (req, res) => {
  try {
    const pi = await stripe.paymentIntents.retrieve(req.params.paymentIntentId);
    res.json({ success: true, status: pi.status, amount: pi.amount / 100, currency: pi.currency, created: new Date(pi.created * 1000) });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// =================================================================
// REFUND
// =================================================================
router.post('/refund', async (req, res) => {
  try {
    const { paymentIntentId, amount, reason } = req.body;
    if (!paymentIntentId) return res.status(400).json({ error: 'Payment Intent ID required' });
    const refundParams = { payment_intent: paymentIntentId, reason: reason || 'requested_by_customer' };
    if (amount) refundParams.amount = Math.round(amount * 100);
    const refund = await stripe.refunds.create(refundParams);
    res.json({ success: true, refundId: refund.id, status: refund.status, amount: refund.amount / 100, currency: refund.currency });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// =================================================================
// STRIPE WEBHOOK
// Fix 7: use req.rawBody (the raw Buffer) for signature verification,
//        NOT req.body (which is already parsed JSON at this point).
//        req.rawBody is stored by the verify callback in server.js.
// =================================================================
router.post('/webhook', express.raw({ type: 'application/json' }), async (req, res) => {
  const sig = req.headers['stripe-signature'];
  const webhookSecret = process.env.STRIPE_WEBHOOK_SECRET;

  let event;
  try {
    // Fix 7: use req.rawBody stored by server.js bodyParser verify callback
    const rawBody = req.rawBody || req.body;
    event = stripe.webhooks.constructEvent(rawBody, sig, webhookSecret);
  } catch (err) {
    console.error('❌ Webhook signature failed:', err.message);
    return res.status(400).send(`Webhook Error: ${err.message}`);
  }

  switch (event.type) {
    case 'payment_intent.succeeded': {
      const pi = event.data.object;
      console.log('✅ Webhook: payment succeeded', pi.id);
      if (pi.metadata.order_id) {
        db.query(
          'UPDATE orders SET payment_status = ? WHERE order_id = ? AND stripe_payment_intent_id = ?',
          ['completed', pi.metadata.order_id, pi.id]
        );
      }
      break;
    }
    case 'payment_intent.payment_failed': {
      const pi = event.data.object;
      if (pi.metadata.order_id) {
        db.query(
          'UPDATE orders SET payment_status = ? WHERE order_id = ? AND stripe_payment_intent_id = ?',
          ['failed', pi.metadata.order_id, pi.id]
        );
      }
      break;
    }
    default:
      console.log(`Unhandled webhook event: ${event.type}`);
  }

  res.json({ received: true });
});

// =================================================================
// TEST
// =================================================================
router.get('/test', (req, res) => {
  res.json({ success: true, message: 'Payment routes working', stripe_configured: !!process.env.STRIPE_SECRET_KEY, timestamp: new Date().toISOString() });
});

module.exports = router;