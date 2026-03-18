// =============================================
// ADMIN CONTROLLER — full rebuild
// =============================================

const db = require('../config/database');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');

// ─── helpers ──────────────────────────────────────────────────────────────────

function query(sql, params) {
  return new Promise((resolve, reject) => {
    db.query(sql, params, (err, results) => {
      if (err) reject(err);
      else resolve(results);
    });
  });
}

// ─── LOGIN ────────────────────────────────────────────────────────────────────
const login = async (req, res) => {
  const { username, password } = req.body;
  if (!username || !password)
    return res.status(400).json({ success: false, message: 'Username and password are required' });

  try {
    const results = await query('SELECT * FROM admins WHERE username = ?', [username]);
    if (!results.length)
      return res.status(401).json({ success: false, message: 'Invalid credentials' });

    const admin = results[0];
    let valid = false;

    if (admin.password_hash.startsWith('$2b$') || admin.password_hash.startsWith('$2a$')) {
      valid = await bcrypt.compare(password, admin.password_hash);
    } else {
      valid = (admin.password_hash === password);
    }

    if (!valid)
      return res.status(401).json({ success: false, message: 'Invalid credentials' });

    const token = jwt.sign(
      { admin_id: admin.admin_id, username: admin.username, email: admin.email },
      process.env.JWT_SECRET || 'default_secret_key',
      { expiresIn: '24h' }
    );

    await query('UPDATE admins SET last_login = NOW() WHERE admin_id = ?', [admin.admin_id]);

    res.json({
      success: true,
      message: 'Login successful',
      data: {
        token,
        admin: {
          admin_id: admin.admin_id,
          username: admin.username,
          email: admin.email,
          full_name: admin.full_name,
        },
      },
    });
  } catch (e) {
    console.error('Login error:', e);
    res.status(500).json({ success: false, message: 'Login failed', error: e.message });
  }
};

const logout = (_req, res) =>
  res.json({ success: true, message: 'Logout successful' });

// ─── STATS ────────────────────────────────────────────────────────────────────
const getStats = async (_req, res) => {
  try {
    const rows = await query(`
      SELECT
        (SELECT COUNT(*) FROM dresses WHERE is_active = 1)                                         AS total_dresses,
        (SELECT COUNT(*) FROM orders)                                                               AS total_orders,
        (SELECT COALESCE(SUM(total_amount),0) FROM orders WHERE payment_status = 'completed')      AS total_revenue,
        (SELECT COUNT(*) FROM orders WHERE payment_status = 'pending')                             AS pending_orders,
        (SELECT COUNT(*) FROM orders WHERE payment_status = 'completed')                           AS completed_orders,
        (SELECT COUNT(*) FROM tryon_history)                                                        AS total_tryons,
        (SELECT COUNT(*) FROM reviews)                                                              AS total_reviews
    `, []);
    res.json({ success: true, data: rows[0] });
  } catch (e) {
    res.status(500).json({ success: false, message: e.message });
  }
};

// ─── ORDERS ───────────────────────────────────────────────────────────────────
const getAllOrders = async (_req, res) => {
  try {
    const orders = await query(`
      SELECT o.*,
             COUNT(oi.item_id) AS item_count
      FROM orders o
      LEFT JOIN order_items oi ON o.order_id = oi.order_id
      GROUP BY o.order_id
      ORDER BY o.created_at DESC
    `, []);

    // Fetch items for each order
    const enriched = await Promise.all(orders.map(async (order) => {
      const items = await query('SELECT * FROM order_items WHERE order_id = ?', [order.order_id]);
      return { ...order, items };
    }));

    res.json({ success: true, count: enriched.length, data: enriched });
  } catch (e) {
    res.status(500).json({ success: false, message: e.message });
  }
};

const markOrderComplete = async (req, res) => {
  try {
    await query(
      "UPDATE orders SET payment_status = 'completed' WHERE order_id = ?",
      [req.params.orderId]
    );
    res.json({ success: true, message: 'Order marked as completed' });
  } catch (e) {
    res.status(500).json({ success: false, message: e.message });
  }
};

// ─── RECEIPTS ─────────────────────────────────────────────────────────────────
const getAllReceipts = async (_req, res) => {
  try {
    const rows = await query(`
      SELECT order_id, customer_name, customer_email, customer_phone,
             total_amount, payment_method, payment_status, receipt_url, created_at
      FROM orders
      WHERE payment_status = 'completed'
      ORDER BY created_at DESC
    `, []);
    res.json({ success: true, count: rows.length, data: rows });
  } catch (e) {
    res.status(500).json({ success: false, message: e.message });
  }
};

// ─── TRY-ON HISTORY ───────────────────────────────────────────────────────────
const getTryOnHistory = async (_req, res) => {
  try {
    const rows = await query(`
      SELECT th.*,
             GROUP_CONCAT(d.name SEPARATOR ', ') AS dress_names
      FROM tryon_history th
      LEFT JOIN dresses d
        ON FIND_IN_SET(d.dress_id, REPLACE(th.dress_ids, ' ', '')) > 0
      GROUP BY th.tryon_id
      ORDER BY th.created_at DESC
    `, []);
    res.json({ success: true, count: rows.length, data: rows });
  } catch (e) {
    res.status(500).json({ success: false, message: e.message });
  }
};

// ─── DRESSES ──────────────────────────────────────────────────────────────────
const getAllDressesWithSizes = async (_req, res) => {
  try {
    const dresses = await query(`
      SELECT d.*,
             GROUP_CONCAT(CONCAT(ds.size_name,':',ds.stock_quantity,':',ds.size_id)
               ORDER BY FIELD(ds.size_name,'XS','S','M','L','XL','XXL')
               SEPARATOR ',') AS sizes_raw
      FROM dresses d
      LEFT JOIN dress_sizes ds ON d.dress_id = ds.dress_id
      GROUP BY d.dress_id
      ORDER BY d.created_at DESC
    `, []);

    const formatted = dresses.map(d => {
      const sizes = d.sizes_raw
        ? d.sizes_raw.split(',').map(s => {
            const [size_name, stock_quantity, size_id] = s.split(':');
            return { size_id: parseInt(size_id), size_name, stock_quantity: parseInt(stock_quantity) };
          })
        : [];
      const { sizes_raw, ...rest } = d;
      return { ...rest, sizes };
    });

    res.json({ success: true, count: formatted.length, data: formatted });
  } catch (e) {
    res.status(500).json({ success: false, message: e.message });
  }
};

const addDress = async (req, res) => {
  const { name, description, price, category, brand, color, material, image_url, sizes } = req.body;

  if (!name || !price)
    return res.status(400).json({ success: false, message: 'name and price are required' });

  try {
    const result = await query(
      `INSERT INTO dresses (name, description, price, category, brand, color, material, image_url, is_active)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, 1)`,
      [name, description || null, price, category || null, brand || null,
       color || null, material || null, image_url || '']
    );

    const dressId = result.insertId;

    // Insert sizes if provided
    let parsedSizes = [];
    if (sizes) {
      parsedSizes = typeof sizes === 'string' ? JSON.parse(sizes) : sizes;
    }
    if (parsedSizes.length) {
      const sizeRows = parsedSizes.map(s => [dressId, s.size_name, parseInt(s.stock_quantity) || 0]);
      await query('INSERT INTO dress_sizes (dress_id, size_name, stock_quantity) VALUES ?', [sizeRows]);
    }

    res.status(201).json({ success: true, message: 'Dress added', data: { dress_id: dressId } });
  } catch (e) {
    res.status(500).json({ success: false, message: e.message });
  }
};

const updateDress = async (req, res) => {
  const { id } = req.params;
  const { name, description, price, category, brand, color, material, image_url, sizes } = req.body;

  try {
    await query(
      `UPDATE dresses
       SET name = COALESCE(?, name),
           description = COALESCE(?, description),
           price = COALESCE(?, price),
           category = COALESCE(?, category),
           brand = COALESCE(?, brand),
           color = COALESCE(?, color),
           material = COALESCE(?, material),
           image_url = COALESCE(?, image_url)
       WHERE dress_id = ?`,
      [name, description, price, category, brand, color, material, image_url, id]
    );

    // Update sizes if provided
    let parsedSizes = [];
    if (sizes) {
      parsedSizes = typeof sizes === 'string' ? JSON.parse(sizes) : sizes;
    }

    if (parsedSizes.length) {
      for (const s of parsedSizes) {
        const stock = parseInt(s.stock_quantity) || 0;
        if (s.size_id) {
          await query(
            'UPDATE dress_sizes SET stock_quantity = ? WHERE size_id = ?',
            [stock, s.size_id]
          );
        } else {
          await query(
            'INSERT INTO dress_sizes (dress_id, size_name, stock_quantity) VALUES (?, ?, ?)',
            [id, s.size_name, stock]
          );
        }
      }

      // Auto-manage is_active: hide dress if ALL sizes are out of stock
      const allSizes = await query('SELECT stock_quantity FROM dress_sizes WHERE dress_id = ?', [id]);
      const totalStock = allSizes.reduce((sum, row) => sum + (row.stock_quantity || 0), 0);
      await query('UPDATE dresses SET is_active = ? WHERE dress_id = ?', [totalStock > 0 ? 1 : 0, id]);
    }

    res.json({ success: true, message: 'Dress updated' });
  } catch (e) {
    res.status(500).json({ success: false, message: e.message });
  }
};

const uploadDressImage = async (req, res) => {
  if (!req.file)
    return res.status(400).json({ success: false, message: 'No image uploaded' });

  const imageUrl = `/uploads/dresses/${req.file.filename}`;
  const { id } = req.params;

  try {
    if (id && id !== '0') {
      await query('UPDATE dresses SET image_url = ? WHERE dress_id = ?', [imageUrl, id]);
    }
    res.json({ success: true, data: { url: imageUrl, filename: req.file.filename } });
  } catch (e) {
    res.status(500).json({ success: false, message: e.message });
  }
};

// ─── LEGACY ───────────────────────────────────────────────────────────────────
const getAnalytics = async (_req, res) => {
  try {
    const stats = await query(`
      SELECT
        (SELECT COUNT(*) FROM dresses WHERE is_active = 1)                                       AS total_dresses,
        (SELECT COUNT(*) FROM orders)                                                             AS total_orders,
        (SELECT COALESCE(SUM(total_amount),0) FROM orders WHERE payment_status='completed')      AS total_revenue,
        (SELECT COUNT(*) FROM orders WHERE payment_status='completed')                           AS completed_orders,
        (SELECT COUNT(*) FROM reviews)                                                            AS total_reviews,
        (SELECT AVG(rating) FROM reviews)                                                         AS average_rating
    `, []);
    res.json({ success: true, data: { summary: stats[0] } });
  } catch (e) {
    res.status(500).json({ success: false, message: e.message });
  }
};

const getAllTransactions = async (_req, res) => {
  try {
    const rows = await query('SELECT * FROM orders ORDER BY created_at DESC', []);
    res.json({ success: true, count: rows.length, data: rows });
  } catch (e) {
    res.status(500).json({ success: false, message: e.message });
  }
};

const getTransactionById = async (req, res) => {
  try {
    const orders = await query('SELECT * FROM orders WHERE order_id = ?', [req.params.id]);
    if (!orders.length)
      return res.status(404).json({ success: false, message: 'Not found' });
    const items = await query('SELECT * FROM order_items WHERE order_id = ?', [req.params.id]);
    res.json({ success: true, data: { order: orders[0], items } });
  } catch (e) {
    res.status(500).json({ success: false, message: e.message });
  }
};

module.exports = {
  login, logout,
  getStats,
  getAllOrders, markOrderComplete,
  getAllReceipts,
  getTryOnHistory,
  getAllDressesWithSizes, addDress, updateDress, uploadDressImage,
  getAnalytics, getAllTransactions, getTransactionById,
};