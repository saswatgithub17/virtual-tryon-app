const db = require('../config/database');
const path = require('path');

// ─── GET ALL DRESSES (with gender, category, search, sort, pagination) ────────
exports.getAllDresses = async (req, res) => {
  try {
    const {
      category,
      gender,
      sort = 'newest',
      search,
      page = 1,
      limit = 50,
    } = req.query;

    let query = `
      SELECT
        d.dress_id, d.name, d.description, d.price, d.category,
        d.brand, d.color, d.material, d.image_url, d.gender,
        d.is_active, d.average_rating, d.total_reviews,
        d.created_at, d.updated_at,
        GROUP_CONCAT(
          CONCAT(ds.size_name, ':', COALESCE(ds.stock_quantity, 0))
          ORDER BY FIELD(ds.size_name, 'XS','S','M','L','XL','XXL')
          SEPARATOR ','
        ) AS sizes
      FROM dresses d
      LEFT JOIN dress_sizes ds ON d.dress_id = ds.dress_id
      WHERE d.is_active = 1
    `;
    const params = [];

    // Gender filter
    if (gender && gender !== 'all') {
      query += ' AND d.gender = ?';
      params.push(gender);
    }

    // Category filter
    if (category && category !== 'All') {
      query += ' AND d.category = ?';
      params.push(category);
    }

    // Search filter
    if (search && search.trim()) {
      query += ' AND (d.name LIKE ? OR d.description LIKE ? OR d.brand LIKE ?)';
      const q = `%${search.trim()}%`;
      params.push(q, q, q);
    }

    query += ' GROUP BY d.dress_id';

    // Sort
    switch (sort) {
      case 'price_asc':
        query += ' ORDER BY d.price ASC';
        break;
      case 'price_desc':
        query += ' ORDER BY d.price DESC';
        break;
      case 'rating':
        query += ' ORDER BY d.average_rating DESC';
        break;
      case 'popular':
        query += ' ORDER BY d.total_reviews DESC';
        break;
      case 'newest':
      default:
        query += ' ORDER BY d.created_at DESC';
        break;
    }

    // Pagination
    const offset = (parseInt(page) - 1) * parseInt(limit);
    query += ' LIMIT ? OFFSET ?';
    params.push(parseInt(limit), offset);

    const dresses = await new Promise((resolve, reject) => {
      db.query(query, params, (err, results) => {
        if (err) return reject(err);
        resolve(results);
      });
    });

    res.json({
      success: true,
      data: dresses,
      pagination: { page: parseInt(page), limit: parseInt(limit) },
    });
  } catch (error) {
    console.error('getAllDresses error:', error);
    res.status(500).json({ success: false, message: 'Failed to fetch dresses' });
  }
};

// ─── GET DRESS BY ID ─────────────────────────────────────────────────────────
exports.getDressById = async (req, res) => {
  try {
    const { id } = req.params;

    const query = `
      SELECT
        d.*,
        GROUP_CONCAT(
          CONCAT(ds.size_name, ':', COALESCE(ds.stock_quantity, 0))
          ORDER BY FIELD(ds.size_name, 'XS','S','M','L','XL','XXL')
          SEPARATOR ','
        ) AS sizes
      FROM dresses d
      LEFT JOIN dress_sizes ds ON d.dress_id = ds.dress_id
      WHERE d.dress_id = ? AND d.is_active = 1
      GROUP BY d.dress_id
    `;

    const results = await new Promise((resolve, reject) => {
      db.query(query, [id], (err, rows) => {
        if (err) return reject(err);
        resolve(rows);
      });
    });

    if (!results.length) {
      return res.status(404).json({ success: false, message: 'Dress not found' });
    }

    res.json({ success: true, data: results[0] });
  } catch (error) {
    console.error('getDressById error:', error);
    res.status(500).json({ success: false, message: 'Failed to fetch dress' });
  }
};

// ─── SEARCH DRESSES ──────────────────────────────────────────────────────────
exports.searchDresses = async (req, res) => {
  try {
    const { q, gender } = req.query;
    if (!q) return res.json({ success: true, data: [] });

    let query = `
      SELECT
        d.*,
        GROUP_CONCAT(
          CONCAT(ds.size_name, ':', COALESCE(ds.stock_quantity, 0))
          ORDER BY FIELD(ds.size_name, 'XS','S','M','L','XL','XXL')
          SEPARATOR ','
        ) AS sizes
      FROM dresses d
      LEFT JOIN dress_sizes ds ON d.dress_id = ds.dress_id
      WHERE d.is_active = 1
        AND (d.name LIKE ? OR d.description LIKE ? OR d.brand LIKE ?)
    `;
    const searchTerm = `%${q}%`;
    const params = [searchTerm, searchTerm, searchTerm];

    if (gender && gender !== 'all') {
      query += ' AND d.gender = ?';
      params.push(gender);
    }

    query += ' GROUP BY d.dress_id ORDER BY d.average_rating DESC LIMIT 20';

    const results = await new Promise((resolve, reject) => {
      db.query(query, params, (err, rows) => {
        if (err) return reject(err);
        resolve(rows);
      });
    });

    res.json({ success: true, data: results });
  } catch (error) {
    console.error('searchDresses error:', error);
    res.status(500).json({ success: false, message: 'Search failed' });
  }
};

// ─── ADD DRESS (Admin) ────────────────────────────────────────────────────────
exports.addDress = async (req, res) => {
  try {
    const {
      name, description, price, category, brand,
      color, material, image_url, gender = 'unisex',
      sizes = {},
    } = req.body;

    if (!name || !price || !image_url) {
      return res.status(400).json({ success: false, message: 'name, price, image_url are required' });
    }

    const insertResult = await new Promise((resolve, reject) => {
      db.query(
        `INSERT INTO dresses (name, description, price, category, brand, color, material, image_url, gender)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
        [name, description, price, category, brand, color, material, image_url, gender],
        (err, result) => {
          if (err) return reject(err);
          resolve(result);
        }
      );
    });

    const dressId = insertResult.insertId;

    // Insert sizes
    const sizeNames = ['XS', 'S', 'M', 'L', 'XL', 'XXL'];
    for (const sizeName of sizeNames) {
      const qty = parseInt(sizes[sizeName] || 0);
      if (qty >= 0) {
        await new Promise((resolve, reject) => {
          db.query(
            'INSERT INTO dress_sizes (dress_id, size_name, stock_quantity) VALUES (?, ?, ?)',
            [dressId, sizeName, qty],
            (err) => { if (err) return reject(err); resolve(); }
          );
        });
      }
    }

    res.status(201).json({ success: true, message: 'Dress added', dress_id: dressId });
  } catch (error) {
    console.error('addDress error:', error);
    res.status(500).json({ success: false, message: 'Failed to add dress' });
  }
};

// ─── UPDATE DRESS (Admin) ─────────────────────────────────────────────────────
exports.updateDress = async (req, res) => {
  try {
    const { id } = req.params;
    const {
      name, description, price, category, brand,
      color, material, image_url, gender, is_active,
      sizes = {},
    } = req.body;

    // Auto-deactivate if ALL sizes are out of stock
    let effectiveActive = is_active;
    const sizeValues = Object.values(sizes).map(Number);
    if (sizeValues.length > 0 && sizeValues.every((v) => v === 0)) {
      effectiveActive = 0;
    }

    await new Promise((resolve, reject) => {
      db.query(
        `UPDATE dresses
         SET name=?, description=?, price=?, category=?, brand=?,
             color=?, material=?, image_url=?, gender=?, is_active=?,
             updated_at=NOW()
         WHERE dress_id=?`,
        [name, description, price, category, brand, color, material,
         image_url, gender, effectiveActive, id],
        (err) => { if (err) return reject(err); resolve(); }
      );
    });

    // Update sizes
    const sizeNames = ['XS', 'S', 'M', 'L', 'XL', 'XXL'];
    for (const sizeName of sizeNames) {
      if (sizes[sizeName] !== undefined) {
        const qty = parseInt(sizes[sizeName]);
        await new Promise((resolve, reject) => {
          db.query(
            `INSERT INTO dress_sizes (dress_id, size_name, stock_quantity)
             VALUES (?, ?, ?)
             ON DUPLICATE KEY UPDATE stock_quantity = ?`,
            [id, sizeName, qty, qty],
            (err) => { if (err) return reject(err); resolve(); }
          );
        });
      }
    }

    res.json({ success: true, message: 'Dress updated' });
  } catch (error) {
    console.error('updateDress error:', error);
    res.status(500).json({ success: false, message: 'Failed to update dress' });
  }
};

// ─── DELETE DRESS (Admin) ─────────────────────────────────────────────────────
exports.deleteDress = async (req, res) => {
  try {
    const { id } = req.params;
    await new Promise((resolve, reject) => {
      db.query(
        'UPDATE dresses SET is_active = 0 WHERE dress_id = ?',
        [id],
        (err) => { if (err) return reject(err); resolve(); }
      );
    });
    res.json({ success: true, message: 'Dress deactivated' });
  } catch (error) {
    console.error('deleteDress error:', error);
    res.status(500).json({ success: false, message: 'Failed to delete dress' });
  }
};

// ─── UPLOAD DRESS IMAGE (Admin) ───────────────────────────────────────────────
exports.uploadDressImage = async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ success: false, message: 'No image file uploaded' });
    }
    const imageUrl = `/uploads/dresses/${req.file.filename}`;
    const { id } = req.params;

    if (id) {
      await new Promise((resolve, reject) => {
        db.query(
          'UPDATE dresses SET image_url = ? WHERE dress_id = ?',
          [imageUrl, id],
          (err) => { if (err) return reject(err); resolve(); }
        );
      });
    }

    res.json({ success: true, image_url: imageUrl, message: 'Image uploaded' });
  } catch (error) {
    console.error('uploadDressImage error:', error);
    res.status(500).json({ success: false, message: 'Failed to upload image' });
  }
};