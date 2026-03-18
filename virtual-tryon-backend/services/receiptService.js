// =============================================
// RECEIPT GENERATION SERVICE — PROFESSIONAL DESIGN
// AuraTry : Pantaloons
// =============================================

const PDFDocument = require('pdfkit');
const fs = require('fs');
const path = require('path');

// ─── Constants ────────────────────────────────────────────────────────────────
const BRAND_NAME    = 'AURATRY : PANTALOONS';
const TAGLINE       = 'Fashion E-Commerce Tryon';
const ADDRESS       = 'Bazarpara Road, Angul, Odisha';
const EMAIL         = 'teambitheads21@gmail.com';
const PHONE         = '9807653124';
const GSTIN         = '21AARCA4812B1ZQ';
const THANK_YOU     = 'Thank you for shopping with AuraTry!';

// A4 dimensions in points (72pt = 1 inch)
const PAGE_W        = 595.28;
const PAGE_H        = 841.89;
const MARGIN        = 50;
const CONTENT_W     = PAGE_W - MARGIN * 2;  // 495.28pt
const CENTER_X      = PAGE_W / 2;           // 297.64pt
const RIGHT_X       = PAGE_W - MARGIN;       // 545.28pt

// Column positions for the items table
const COL = {
  num:      MARGIN,            // #
  name:     MARGIN + 20,       // Item name
  size:     MARGIN + 265,      // Size
  qty:      MARGIN + 310,      // Qty
  price:    MARGIN + 355,      // Unit Price
  amount:   MARGIN + 425,      // Amount (right-aligned at RIGHT_X)
};

/**
 * Draw a full-width horizontal rule.
 * @param {PDFDocument} doc
 * @param {number} y          Y position
 * @param {number} lineWidth  stroke width (default 0.5)
 */
function rule(doc, y, lineWidth = 0.5) {
  doc.save()
     .strokeColor('#000000')
     .lineWidth(lineWidth)
     .moveTo(MARGIN, y)
     .lineTo(RIGHT_X, y)
     .stroke()
     .restore();
}

/**
 * Draw a thick decorative rule (used for header/footer boundaries).
 */
function thickRule(doc, y) {
  rule(doc, y, 1.5);
}

/**
 * Right-align text at a given x position.
 */
function textRight(doc, text, rightEdge, y, options = {}) {
  const w = doc.widthOfString(text);
  doc.text(text, rightEdge - w, y, { lineBreak: false, ...options });
}

/**
 * Formats a JS Date or ISO string into DD/MM/YYYY HH:MM
 */
function formatDate(dateInput) {
  const d = dateInput ? new Date(dateInput) : new Date();
  const pad = n => String(n).padStart(2, '0');
  return `${pad(d.getDate())}/${pad(d.getMonth() + 1)}/${d.getFullYear()}  ${pad(d.getHours())}:${pad(d.getMinutes())}`;
}

/**
 * Formats a number as ₹X,XX,XXX.XX (Indian numbering)
 */
function rupee(amount) {
  const n = parseFloat(amount) || 0;
  return '₹' + n.toLocaleString('en-IN', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
}

/**
 * Generate a professional PDF receipt.
 * @param {Object} orderData  — order object with items array
 * @returns {Promise<string>} — public URL path to the saved PDF
 */
const generateReceipt = async (orderData) => {
  return new Promise((resolve, reject) => {
    try {
      console.log('📄 Generating professional receipt for order:', orderData.order_id);

      // Ensure receipts directory exists
      const receiptsDir = './uploads/receipts';
      if (!fs.existsSync(receiptsDir)) fs.mkdirSync(receiptsDir, { recursive: true });

      const filename  = `receipt-${orderData.order_id}.pdf`;
      const filepath  = path.join(receiptsDir, filename);

      const doc = new PDFDocument({ size: 'A4', margin: 0, info: {
        Title:   `Receipt — ${orderData.order_id}`,
        Author:  'AuraTry : Pantaloons',
        Subject: 'Purchase Receipt',
      }});

      const stream = fs.createWriteStream(filepath);
      doc.pipe(stream);

      // ═══════════════════════════════════════════════════════════
      // SECTION 1 — HEADER
      // ═══════════════════════════════════════════════════════════
      let y = 48;

      // Brand name
      doc.font('Helvetica-Bold')
         .fontSize(20)
         .fillColor('#000000')
         .text(BRAND_NAME, MARGIN, y, { width: CONTENT_W, align: 'center', lineBreak: false });
      y += 28;

      // Tagline
      doc.font('Helvetica')
         .fontSize(9.5)
         .fillColor('#333333')
         .text(TAGLINE, MARGIN, y, { width: CONTENT_W, align: 'center', lineBreak: false });
      y += 14;

      // Address
      doc.fontSize(8.5)
         .fillColor('#555555')
         .text(ADDRESS, MARGIN, y, { width: CONTENT_W, align: 'center', lineBreak: false });
      y += 13;

      // Contact
      doc.fontSize(8.5)
         .fillColor('#555555')
         .text(`${EMAIL}   |   ${PHONE}`, MARGIN, y, { width: CONTENT_W, align: 'center', lineBreak: false });
      y += 18;

      thickRule(doc, y);
      y += 16;

      // ═══════════════════════════════════════════════════════════
      // SECTION 2 — RECEIPT TITLE + ORDER META
      // ═══════════════════════════════════════════════════════════

      // "RECEIPT" centred title
      doc.font('Helvetica-Bold')
         .fontSize(15)
         .fillColor('#000000')
         .text('RECEIPT', MARGIN, y, { width: CONTENT_W, align: 'center', lineBreak: false });
      y += 26;

      rule(doc, y, 0.4);
      y += 10;

      // Two-column meta row
      const paymentLabel = (orderData.payment_method || 'stripe').toUpperCase();
      const dateStr      = formatDate(orderData.created_at);
      const orderId      = orderData.order_id || 'N/A';

      // Left column
      doc.font('Helvetica-Bold').fontSize(8).fillColor('#555555')
         .text('ORDER ID', MARGIN, y, { lineBreak: false });
      doc.font('Helvetica').fontSize(8.5).fillColor('#000000')
         .text(orderId, MARGIN, y + 11, { lineBreak: false });

      doc.font('Helvetica-Bold').fontSize(8).fillColor('#555555')
         .text('GSTIN', MARGIN, y + 26, { lineBreak: false });
      doc.font('Helvetica').fontSize(8.5).fillColor('#000000')
         .text(GSTIN, MARGIN, y + 37, { lineBreak: false });

      // Right column
      const rightCol = CENTER_X + 10;
      doc.font('Helvetica-Bold').fontSize(8).fillColor('#555555')
         .text('DATE & TIME', rightCol, y, { lineBreak: false });
      doc.font('Helvetica').fontSize(8.5).fillColor('#000000')
         .text(dateStr, rightCol, y + 11, { lineBreak: false });

      doc.font('Helvetica-Bold').fontSize(8).fillColor('#555555')
         .text('PAYMENT METHOD', rightCol, y + 26, { lineBreak: false });
      doc.font('Helvetica').fontSize(8.5).fillColor('#000000')
         .text(paymentLabel, rightCol, y + 37, { lineBreak: false });

      y += 55;

      rule(doc, y, 0.4);
      y += 14;

      // ═══════════════════════════════════════════════════════════
      // SECTION 3 — BILLED TO
      // ═══════════════════════════════════════════════════════════

      doc.font('Helvetica-Bold')
         .fontSize(9)
         .fillColor('#000000')
         .text('BILLED TO', MARGIN, y, { lineBreak: false });
      y += 14;

      // Underline "BILLED TO"
      rule(doc, y, 0.3);
      y += 10;

      const billingFields = [
        ['Name',  orderData.customer_name  || 'N/A'],
        ['Email', orderData.customer_email || 'N/A'],
        ['Phone', orderData.customer_phone || 'N/A'],
      ];

      billingFields.forEach(([label, value]) => {
        doc.font('Helvetica-Bold').fontSize(8.5).fillColor('#555555')
           .text(`${label}:`, MARGIN, y, { continued: false, lineBreak: false });
        doc.font('Helvetica').fontSize(8.5).fillColor('#000000')
           .text(value, MARGIN + 40, y, { lineBreak: false });
        y += 14;
      });

      y += 6;
      rule(doc, y, 0.4);
      y += 14;

      // ═══════════════════════════════════════════════════════════
      // SECTION 4 — ITEMS TABLE
      // ═══════════════════════════════════════════════════════════

      // Table header background
      doc.rect(MARGIN, y, CONTENT_W, 18).fillColor('#000000').fill();

      // Table header text (white on black)
      doc.font('Helvetica-Bold').fontSize(8).fillColor('#FFFFFF');
      doc.text('#',       COL.num,   y + 5, { lineBreak: false });
      doc.text('ITEM',    COL.name,  y + 5, { lineBreak: false });
      doc.text('SIZE',    COL.size,  y + 5, { lineBreak: false });
      doc.text('QTY',     COL.qty,   y + 5, { lineBreak: false });
      doc.text('PRICE',   COL.price, y + 5, { lineBreak: false });
      textRight(doc, 'AMOUNT', RIGHT_X, y + 5);
      y += 22;

      // Item rows
      const items = orderData.items || [];
      let subtotal = 0;

      items.forEach((item, index) => {
        const rowY  = y;
        const isEven = index % 2 === 0;

        // Alternating very-light-gray background
        if (isEven) {
          doc.rect(MARGIN, rowY, CONTENT_W, 18).fillColor('#F7F7F7').fill();
        }

        const price   = parseFloat(item.price)    || 0;
        const qty     = parseInt(item.quantity)    || 1;
        const amount  = parseFloat(item.subtotal)  || (price * qty);
        subtotal += amount;

        // Truncate long dress names
        const dressName = (item.dress_name || 'Product').substring(0, 30);

        doc.font('Helvetica').fontSize(8.5).fillColor('#000000');
        doc.text(String(index + 1),         COL.num,   rowY + 5, { lineBreak: false });
        doc.text(dressName,                 COL.name,  rowY + 5, { lineBreak: false, width: 230 });
        doc.text(item.size_name || 'M',     COL.size,  rowY + 5, { lineBreak: false });
        doc.text(String(qty),               COL.qty,   rowY + 5, { lineBreak: false });
        doc.text(rupee(price),              COL.price, rowY + 5, { lineBreak: false });
        textRight(doc, rupee(amount), RIGHT_X, rowY + 5);

        y += 18;
      });

      // Bottom rule of table
      rule(doc, y, 0.5);
      y += 14;

      // ═══════════════════════════════════════════════════════════
      // SECTION 5 — TOTALS
      // ═══════════════════════════════════════════════════════════

      // Calculate GST (18% inclusive breakdown)
      const totalAmount  = parseFloat(orderData.total_amount) || subtotal;
      const gstRate      = 0.18;
      const baseAmount   = totalAmount / (1 + gstRate);
      const gstAmount    = totalAmount - baseAmount;

      const totalsLeft   = MARGIN + 270;  // label column
      const totalsRight  = RIGHT_X;       // amount column

      // Subtotal row
      doc.font('Helvetica').fontSize(9).fillColor('#333333');
      textRight(doc, 'Subtotal',        totalsLeft, y);
      textRight(doc, rupee(baseAmount), totalsRight, y);
      y += 15;

      // GST row
      doc.font('Helvetica').fontSize(9).fillColor('#333333');
      textRight(doc, 'GST (18% incl.)',  totalsLeft,  y);
      textRight(doc, rupee(gstAmount),   totalsRight, y);
      y += 12;

      rule(doc, y, 0.4);
      y += 10;

      // TOTAL row — bold, larger
      doc.font('Helvetica-Bold').fontSize(11).fillColor('#000000');
      textRight(doc, 'TOTAL',           totalsLeft,  y);
      textRight(doc, rupee(totalAmount), totalsRight, y);
      y += 22;

      thickRule(doc, y);
      y += 14;

      // ═══════════════════════════════════════════════════════════
      // SECTION 6 — PAYMENT STATUS BADGE
      // ═══════════════════════════════════════════════════════════

      const status      = (orderData.payment_status || 'pending').toUpperCase();
      const badgeFill   = status === 'COMPLETED' ? '#000000' : '#555555';
      const badgeW      = 100;
      const badgeH      = 20;
      const badgeX      = MARGIN;
      const badgeY      = y;

      doc.rect(badgeX, badgeY, badgeW, badgeH)
         .fillColor(badgeFill)
         .fill();

      doc.font('Helvetica-Bold').fontSize(8).fillColor('#FFFFFF')
         .text(`PAYMENT: ${status}`, badgeX, badgeY + 6, {
           width: badgeW, align: 'center', lineBreak: false
         });

      y += 38;

      // ═══════════════════════════════════════════════════════════
      // SECTION 7 — THANK YOU + FOOTER
      // ═══════════════════════════════════════════════════════════

      // Thank you message
      doc.font('Helvetica-Bold')
         .fontSize(11)
         .fillColor('#000000')
         .text(THANK_YOU, MARGIN, y, { width: CONTENT_W, align: 'center', lineBreak: false });
      y += 30;

      thickRule(doc, y);
      y += 12;

      // Footer note
      doc.font('Helvetica')
         .fontSize(7.5)
         .fillColor('#777777')
         .text('This is a computer-generated receipt. No signature required.', MARGIN, y, {
           width: CONTENT_W, align: 'center', lineBreak: false
         });

      doc.end();

      stream.on('finish', () => {
        console.log('✅ Professional receipt generated:', filename);
        resolve(`/uploads/receipts/${filename}`);
      });

      stream.on('error', (err) => {
        console.error('❌ Stream error:', err);
        reject(err);
      });

    } catch (error) {
      console.error('❌ Receipt generation failed:', error);
      reject(error);
    }
  });
};

/**
 * Return existing receipt path if already generated.
 */
const getReceiptPath = (orderId) => {
  const filepath = `./uploads/receipts/receipt-${orderId}.pdf`;
  return fs.existsSync(filepath) ? `/uploads/receipts/receipt-${orderId}.pdf` : null;
};

module.exports = { generateReceipt, getReceiptPath };