// =============================================
// RECEIPT GENERATION SERVICE
// PDF receipt creation using PDFKit
// =============================================

const PDFDocument = require('pdfkit');
const fs = require('fs');
const path = require('path');

/**
 * Generate PDF receipt for an order
 * @param {Object} orderData - Order information
 * @returns {Promise<string>} - Path to generated PDF
 */
const generateReceipt = async (orderData) => {
    return new Promise((resolve, reject) => {
        try {
            console.log('📄 Generating receipt for order:', orderData.order_id);

            // Create receipts directory if it doesn't exist
            const receiptsDir = './uploads/receipts';
            if (!fs.existsSync(receiptsDir)) {
                fs.mkdirSync(receiptsDir, { recursive: true });
            }

            // Generate filename
            const filename = `receipt-${orderData.order_id}.pdf`;
            const filepath = path.join(receiptsDir, filename);

            // Create PDF document
            const doc = new PDFDocument({
                size: 'A4',
                margin: 50
            });

            // Pipe to file
            const stream = fs.createWriteStream(filepath);
            doc.pipe(stream);

            // Add content
            generateHeader(doc, orderData);
            generateCustomerInfo(doc, orderData);
            generateOrderTable(doc, orderData);
            generateFooter(doc, orderData);

            // Finalize PDF
            doc.end();

            // Wait for file to be written
            stream.on('finish', () => {
                console.log('✅ Receipt generated:', filename);
                resolve(`/uploads/receipts/${filename}`);
            });

            stream.on('error', (err) => {
                console.error('❌ Error writing receipt:', err);
                reject(err);
            });

        } catch (error) {
            console.error('❌ Error generating receipt:', error);
            reject(error);
        }
    });
};

/**
 * Generate receipt header
 */
const generateHeader = (doc, orderData) => {
    // Company/Store Name
    doc
        .fontSize(24)
        .font('Helvetica-Bold')
        .text('Virtual Try-On Store', 50, 50)
        .fontSize(10)
        .font('Helvetica')
        .text('Fashion E-Commerce', 50, 80)
        .text('123 Fashion Street, Mall City', 50, 95)
        .text('Phone: +91 1234567890', 50, 110)
        .text('Email: support@virtualtryon.com', 50, 125)
        .moveDown();

    // Receipt Title
    doc
        .fontSize(20)
        .font('Helvetica-Bold')
        .text('RECEIPT', 400, 50)
        .fontSize(10)
        .font('Helvetica')
        .text(`Order ID: ${orderData.order_id}`, 400, 80)
        .text(`Date: ${formatDate(orderData.created_at)}`, 400, 95)
        .text(`Payment: ${orderData.payment_method || 'Stripe'}`, 400, 110);

    // Horizontal line
    doc
        .strokeColor('#aaaaaa')
        .lineWidth(2)
        .moveTo(50, 160)
        .lineTo(550, 160)
        .stroke();

    doc.moveDown(2);
};

/**
 * Generate customer information
 */
const generateCustomerInfo = (doc, orderData) => {
    doc
        .fontSize(12)
        .font('Helvetica-Bold')
        .text('BILL TO:', 50, 180);

    doc
        .fontSize(10)
        .font('Helvetica')
        .text(orderData.customer_name, 50, 200)
        .text(orderData.customer_email, 50, 215)
        .text(orderData.customer_phone || 'N/A', 50, 230);

    doc.moveDown(2);
};

/**
 * Generate order items table
 */
const generateOrderTable = (doc, orderData) => {
    const tableTop = 280;
    const itemCodeX = 50;
    const descriptionX = 150;
    const sizeX = 350;
    const quantityX = 400;
    const priceX = 450;
    const amountX = 500;

    // Table Header
    doc
        .fontSize(10)
        .font('Helvetica-Bold')
        .text('#', itemCodeX, tableTop)
        .text('ITEM', descriptionX, tableTop)
        .text('SIZE', sizeX, tableTop)
        .text('QTY', quantityX, tableTop)
        .text('PRICE', priceX, tableTop)
        .text('AMOUNT', amountX, tableTop);

    // Header line
    doc
        .strokeColor('#aaaaaa')
        .lineWidth(1)
        .moveTo(50, tableTop + 15)
        .lineTo(550, tableTop + 15)
        .stroke();

    // Table Items
    let yPosition = tableTop + 30;
    
    orderData.items.forEach((item, index) => {
        // Convert string prices to numbers
        const price = parseFloat(item.price);
        const subtotal = parseFloat(item.subtotal);
        
        doc
            .fontSize(9)
            .font('Helvetica')
            .text(index + 1, itemCodeX, yPosition)
            .text(item.dress_name.substring(0, 25), descriptionX, yPosition)
            .text(item.size_name, sizeX, yPosition)
            .text(item.quantity, quantityX, yPosition)
            .text(`₹${price.toFixed(2)}`, priceX, yPosition)
            .text(`₹${subtotal.toFixed(2)}`, amountX, yPosition);

        yPosition += 25;
    });

    // Bottom line
    doc
        .strokeColor('#aaaaaa')
        .lineWidth(1)
        .moveTo(50, yPosition + 5)
        .lineTo(550, yPosition + 5)
        .stroke();

    // Total
    yPosition += 20;
    const totalAmount = parseFloat(orderData.total_amount);
    doc
        .fontSize(11)
        .font('Helvetica-Bold')
        .text('TOTAL:', 400, yPosition)
        .text(`₹${totalAmount.toFixed(2)}`, 500, yPosition);

    // Payment Status
    yPosition += 30;
    const statusColor = orderData.payment_status === 'completed' ? '#27ae60' : '#e74c3c';
    doc
        .fontSize(10)
        .font('Helvetica-Bold')
        .fillColor(statusColor)
        .text(`Payment Status: ${orderData.payment_status.toUpperCase()}`, 50, yPosition)
        .fillColor('#000000');
};

/**
 * Generate receipt footer
 */
const generateFooter = (doc, orderData) => {
    const footerTop = 700;

    // Thank you message
    doc
        .fontSize(12)
        .font('Helvetica-Bold')
        .text('Thank you for shopping with us!', 50, footerTop, {
            align: 'center',
            width: 500
        });

    // Terms and conditions
    doc
        .fontSize(8)
        .font('Helvetica')
        .text('Terms & Conditions:', 50, footerTop + 30)
        .text('1. All sales are final. No refunds or exchanges.', 50, footerTop + 45)
        .text('2. Items must be in original condition.', 50, footerTop + 58)
        .text('3. For any queries, contact support@virtualtryon.com', 50, footerTop + 71);

    // Footer line
    doc
        .strokeColor('#aaaaaa')
        .lineWidth(1)
        .moveTo(50, 780)
        .lineTo(550, 780)
        .stroke();

    // Copyright
    doc
        .fontSize(8)
        .font('Helvetica')
        .text('© 2024 Virtual Try-On Store. All rights reserved.', 50, 790, {
            align: 'center',
            width: 500
        });
};

/**
 * Format date to readable string
 */
const formatDate = (date) => {
    const d = new Date(date);
    const options = {
        year: 'numeric',
        month: 'long',
        day: 'numeric',
        hour: '2-digit',
        minute: '2-digit'
    };
    return d.toLocaleDateString('en-IN', options);
};

/**
 * Get receipt by order ID (if already generated)
 */
const getReceiptPath = (orderId) => {
    const filename = `receipt-${orderId}.pdf`;
    const filepath = `./uploads/receipts/${filename}`;
    
    if (fs.existsSync(filepath)) {
        return `/uploads/receipts/${filename}`;
    }
    
    return null;
};

module.exports = {
    generateReceipt,
    getReceiptPath,
    formatDate
};