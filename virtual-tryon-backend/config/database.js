// =============================================
// DATABASE CONNECTION CONFIGURATION
// MySQL Connection using mysql2
// =============================================

const mysql = require('mysql2');
require('dotenv').config();

// Create MySQL connection
const connection = mysql.createConnection({
    host: process.env.DB_HOST || 'localhost',
    port: process.env.DB_PORT || 3306,
    user: process.env.DB_USER || 'root',
    password: process.env.DB_PASSWORD || '',
    database: process.env.DB_NAME || 'virtual_tryon_db',
    waitForConnections: true,
    connectionLimit: 10,
    queueLimit: 0
});

// Test database connection
connection.connect((err) => {
    if (err) {
        console.error('❌ Database connection failed:', err.message);
        console.error('   Please check your XAMPP MySQL service is running');
        process.exit(1);
    }
    console.log('✅ Connected to MySQL Database (XAMPP)');
    console.log(`   Database: ${process.env.DB_NAME}`);
});

// Handle connection errors
connection.on('error', (err) => {
    console.error('❌ Database error:', err);
    if (err.code === 'PROTOCOL_CONNECTION_LOST') {
        console.error('   Database connection was closed.');
    }
    if (err.code === 'ER_CON_COUNT_ERROR') {
        console.error('   Database has too many connections.');
    }
    if (err.code === 'ECONNREFUSED') {
        console.error('   Database connection was refused.');
    }
});

// Export connection
module.exports = connection;