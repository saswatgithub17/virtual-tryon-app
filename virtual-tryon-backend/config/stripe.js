// =============================================
// STRIPE PAYMENT CONFIGURATION
// =============================================

const Stripe = require('stripe');
require('dotenv').config();

// Initialize Stripe with secret key
const stripe = Stripe(process.env.STRIPE_SECRET_KEY);

// Export stripe instance
module.exports = stripe;