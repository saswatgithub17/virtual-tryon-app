const db = require('./config/database');

const createPaymentTable = `
CREATE TABLE IF NOT EXISTS payment_transactions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    transaction_id VARCHAR(100) UNIQUE,
    order_id VARCHAR(100),
    amount DECIMAL(10,2),
    payment_method VARCHAR(20),
    status VARCHAR(20) DEFAULT 'pending',
    stripe_payment_intent_id VARCHAR(100),
    upi_transaction_id VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
)`;

db.query(createPaymentTable, (err, results) => {
    if (err) {
        console.error('Error creating table:', err);
    } else {
        console.log('✅ Payment transactions table created successfully!');
    }
    process.exit();
});
